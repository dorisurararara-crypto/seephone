// Pillar Seer — R110 Sprint 1: 프리미엄 entitlement provider.
//
// monetization_playbook.md 기준:
//   - 상품 = com.ganziman.pillarseer.premium_pack (non-consumable 단건).
//   - 로컬 저장 entitlement 는 캐시일 뿐, source of truth = App Store.
//   - 앱 시작 시 조용한 자동 복원으로 같은 Apple ID 보유자는 자동 unlock.
//
// 상태 분리:
//   - premiumProvider = 실제 결제로 획득한 entitlement (App Store source of truth).
//   - devUnlockProvider(isPro) = 개발자 magic-code unlock. release 에서 비활성.
//   - isPremiumUnlockedProvider = 위 둘 중 하나라도 true 면 프리미엄 콘텐츠 접근 허용.
//     (Sprint 2 의 기능 게이트는 이 derived provider 를 watch.)
//
// 패턴은 streak_provider / notification_provider 와 동일 — Notifier + NotifierProvider.
//
// REWORK 2 (codex 8.4 → ) — restore/purchase 동시 이벤트 race 제거:
//   - 전역 `_restoreWaiter` / `_autoRestoreInFlight` 를 per-operation
//     `_RestoreSession` 토큰으로 대체. auto restore cleanup 이 이후 시작된
//     manual restore session 을 닫지 못한다(토큰 identity 검사).
//   - waiter 는 restore 맥락 결과(restored/nothingToRestore/error/unavailable)
//     로만 complete. purchased/canceled/pending/alreadyOwned 는 restore
//     context 를 닫지 않는다.
//   - 한 restore session 중 purchased/restored 로 entitlement 가 true 가
//     되면, 같은 session 의 stale nothingToRestore 는 강등하지 않는다.
//
// REWORK 3 (codex 9.2 → ) — restore 호출 overlap 차단(stream misrouting 제거):
//   StoreKit purchaseStream 이벤트에는 어느 restore 호출에서 왔는지 tag 가
//   없다. 따라서 동시에 2개의 restorePurchases() 호출이 떠 있으면, 늦게
//   도착하는 첫 호출(auto)의 empty batch 가 두 번째 호출(manual/induced)의
//   결과처럼 라우팅될 수 있다. 해결책 = "동시에 restore 호출을 2개 만들지
//   않는다":
//   - auto restore 진행 중 사용자가 수동 복원을 누르면 새 restorePurchases()
//     를 호출하지 않고, 진행 중인 auto session 을 manual-visible 로 *승격*
//     한다(userVisible=true). 늦게 오는 auto empty/restored 가 그대로 그
//     수동 요청의 결과가 된다 — restore 호출은 여전히 1개라 의미가 일관된다.
//   - auto restore 진행 중 alreadyOwned 가 오면 새 restore 호출 대신 그
//     auto session 을 induced/manual-visible 로 승격한다. restore 호출이
//     아직 없었던 경우(_restore==null)에만 새 induced session + 1회 호출.
//   - induced(alreadyOwned) restore 가 pending 인 동안 purchasePremium 은
//     return — buyNonConsumable storm 방지. session 이 끝나야 다시 허용.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/purchase_service.dart';
import 'dev_unlock_provider.dart';

/// 프리미엄 entitlement 캐시 키 (shared_preferences).
const String _kPremiumCacheKey = 'app.premium.entitled';

/// 자동/수동 복원이 stream 응답을 기다리는 최대 시간.
/// StoreKit 은 복원할 게 없으면 stream 에 아무것도 안 보내므로,
/// 이 시간이 지나면 "복원할 내역 없음"으로 마무리한다.
const Duration _kRestoreTimeout = Duration(seconds: 8);

/// 프리미엄 상태 모델.
@immutable
class PremiumState {
  const PremiumState({
    required this.entitled,
    required this.storeAvailable,
    this.busy = false,
    this.lastResult,
    this.localizedPrice,
  });

  /// 프리미엄팩 보유 여부(실제 결제/복원 기준). 초기값 false.
  final bool entitled;

  /// StoreKit 사용 가능 여부. false 여도 앱은 무료로 정상 동작.
  final bool storeAvailable;

  /// 구매/복원 진행 중 — UI 로딩 표시용.
  final bool busy;

  /// 마지막 결제/복원 결과 — toast/안내용 (1회성).
  final PurchaseOutcome? lastResult;

  /// StoreKit localized 가격 문자열 (예: "₩5,900"). 미조회 시 null.
  final String? localizedPrice;

  PremiumState copyWith({
    bool? entitled,
    bool? storeAvailable,
    bool? busy,
    PurchaseOutcome? lastResult,
    bool clearLastResult = false,
    String? localizedPrice,
  }) {
    return PremiumState(
      entitled: entitled ?? this.entitled,
      storeAvailable: storeAvailable ?? this.storeAvailable,
      busy: busy ?? this.busy,
      lastResult: clearLastResult ? null : (lastResult ?? this.lastResult),
      localizedPrice: localizedPrice ?? this.localizedPrice,
    );
  }

  /// 디폴트 — 미보유, 스토어는 일단 가능으로 가정(init 에서 정정).
  factory PremiumState.initial() =>
      const PremiumState(entitled: false, storeAvailable: true);
}

/// 1회 복원 작업(자동/수동)의 로컬 상태.
///
/// 전역 필드 대신 작업마다 새 인스턴스를 만들어 [PremiumNotifier._restore]
/// 에 토큰처럼 보관한다. 이렇게 하면:
///   - auto restore 의 timeout cleanup 이 그 사이 시작된 manual restore
///     session 을 닫지 못한다(identity 비교).
///   - 한 session 안에서 purchased/restored 로 entitlement 가 살아나면
///     [entitlementGranted] 가 true 가 되어, 늦게 도착한 같은 session 의
///     stale nothingToRestore 가 정상 구매자를 강등하지 못한다.
///
/// REWORK 3 — 같은 session 이 진행 중일 때 새 restore 호출을 만들지 않고
/// "승격"할 수 있게 [userVisible] / [inducedByAlreadyOwned] 를 가변으로 둔다.
/// 동시에 떠 있는 StoreKit restore 호출이 항상 1개라, tag 없는 stream
/// 이벤트도 단 하나의 session 으로만 라우팅되어 misrouting 이 불가능하다.
class _RestoreSession {
  _RestoreSession({
    required this.isAuto,
    this.userVisible = false,
    this.inducedByAlreadyOwned = false,
  });

  /// 자동(앱 시작) 복원으로 *시작*되었으면 true, 수동(버튼)이면 false.
  ///
  /// 시작 성격일 뿐 — 결과 노출 여부는 [userVisible] 가 결정한다(승격 가능).
  final bool isAuto;

  /// 결과(nothingToRestore)를 사용자에게 toast/lastResult 로 노출할지.
  ///
  /// 순수 auto 복원은 false(무음). 수동 복원이거나, auto session 이
  /// 사용자의 수동 복원/alreadyOwned 로 승격되면 true 가 된다.
  /// true 인 동안은 restore 종결까지 state.busy 도 true 로 유지한다.
  bool userVisible;

  /// 이 session 이 alreadyOwned 신호 때문에 (재)구매 영수증 확인을 위해
  /// 진행 중인지. true 인 동안 purchasePremium 재진입은 차단된다 —
  /// buyNonConsumable storm 방지.
  bool inducedByAlreadyOwned;

  /// stream 응답을 받았는지 추적 — timeout 후 nothingToRestore 판정.
  final Completer<void> waiter = Completer<void>();

  /// 이 복원 session 도중 purchased/restored 로 entitlement 가 살아났는지.
  /// true 면 같은 session 의 stale empty batch 는 강등하지 않는다.
  bool entitlementGranted = false;

  /// 이 session 에 대해 StoreKit restorePurchases() 호출이 이미 떠 있는지.
  ///
  /// auto/manual/induced 어느 경우든 restore 호출은 session 당 정확히 1회.
  /// 이미 true 면 같은 session 을 승격할 뿐 새 호출을 절대 추가하지 않는다.
  bool restoreCallStarted = false;
}

class PremiumNotifier extends Notifier<PremiumState> {
  PremiumNotifier({PurchaseService? serviceOverride})
      : _serviceOverride = serviceOverride;

  /// test 주입용. null 이면 build 에서 실제 PurchaseService 생성.
  final PurchaseService? _serviceOverride;

  late final PurchaseService _service;

  /// 현재 진행 중인 복원 작업. 없으면 null.
  ///
  /// 전역 `_restoreWaiter` / `_autoRestoreInFlight` race 를 제거하기 위해
  /// 작업 단위 토큰으로 관리한다. cleanup·완료 처리는 이 필드가 *바로 그*
  /// session 인지(identity) 확인한 뒤에만 수행한다.
  _RestoreSession? _restore;

  /// notifier 가 dispose 되었는지. true 면 stream 콜백·timeout 콜백이
  /// 더 이상 state 를 건드리지 않는다(disposed notifier write 방지).
  bool _disposed = false;

  @override
  PremiumState build() {
    _service = _serviceOverride ?? PurchaseService();
    _service.onPurchaseUpdate = _onPurchaseResult;
    ref.onDispose(() {
      _disposed = true;
      // 진행 중 복원 session 의 waiter 를 닫아, 매달린 .timeout() 타이머가
      // 즉시 정리되게 한다(테스트 leaked-timer / dispose 후 콜백 방지).
      final session = _restore;
      if (session != null && !session.waiter.isCompleted) {
        session.waiter.complete();
      }
      _restore = null;
      // ignore: discarded_futures
      _service.dispose();
    });
    // 비동기 부팅 — 캐시 즉시 반영 후 StoreKit 자동 복원.
    // ignore: discarded_futures
    _boot();
    return PremiumState.initial();
  }

  /// 앱 시작 부팅 시퀀스:
  ///   1) 로컬 캐시 entitlement 즉시 반영(오프라인에서도 UX 유지).
  ///   2) PurchaseService.init() — purchase stream listen + 상품 조회.
  ///   3) 조용한 자동 복원 — App Store 가 진짜 source of truth.
  ///
  /// 어떤 단계가 실패해도 앱은 죽지 않는다. StoreKit 을 못 쓰면 캐시값을 유지.
  Future<void> _boot() async {
    // 1) 캐시 먼저.
    final cached = await _readCache();
    if (cached) {
      state = state.copyWith(entitled: true);
    }

    // 2) StoreKit init.
    try {
      await _service.init();
    } catch (e) {
      debugPrint('[PremiumNotifier] service.init failed: $e');
    }
    state = state.copyWith(
      storeAvailable: _service.storeAvailable,
      localizedPrice: _service.premiumProduct?.price,
    );

    // 3) 조용한 자동 복원. 결과는 _onPurchaseResult 로 들어온다.
    await _autoRestore();
  }

  /// 앱 시작 시 조용한 자동 복원. 복원할 게 없어도 toast 없음(무음).
  ///
  /// StoreKit 이 명시적으로 nothingToRestore 를 돌려주면(빈 batch) — 같은
  /// Apple ID 에 프리미엄팩 구매 내역이 없다는 뜻 — 캐시 true 가 위변조거나
  /// 환불/가족공유 해제 등으로 무효해진 것이므로 entitled/캐시를 false 로 내린다.
  /// 반대로 unavailable/error/네트워크 실패에서는 응답이 불확실하므로 캐시를
  /// 보존해 오프라인 기존 구매자 UX 를 지킨다(_onPurchaseResult 참고).
  ///
  /// 자동 복원 중 이미 다른 복원 작업이 진행 중이면(예: 이례적 중복 부팅)
  /// 새 session 을 만들지 않는다.
  Future<void> _autoRestore() async {
    if (!_service.storeAvailable) return;
    if (_restore != null) return; // 이미 복원 진행 중 — 중복 방지.
    final session = _RestoreSession(isAuto: true);
    session.restoreCallStarted = true;
    _restore = session;
    final started = await _service.autoRestore();
    if (!started) {
      // restore 호출 자체가 실패(store 불가/StoreKit API throw)했다 — 이는
      // "복원 내역 없음"이 아니라 "결과 불확실"이다. timeout waiter 를 등록하면
      // session 이 8초 뒤 nothingToRestore 로 강등돼 cached true 기존 구매자가
      // 프리미엄을 잃는다. 따라서 timeout 을 등록하지 않고, *이 session* 이
      // 아직 현재 session 일 때만 조용히 정리한다:
      //   - waiter 를 닫아 매달린 타이머가 없게 하고,
      //   - _restore 를 null 로 비워 이후 manual/induced 복원이 가능하게 하되,
      //   - entitlement/캐시/lastResult 는 절대 건드리지 않는다(보존).
      if (identical(_restore, session)) {
        if (!session.waiter.isCompleted) {
          session.waiter.complete();
        }
        _restore = null;
      }
      return;
    }
    // restore 호출이 정상 제출됨 — stream(빈 batch 포함) 응답을 기다린다.
    // timeout 시 처리는 _finishRestoreSession 으로 통일한다.
    // auto session 이 그 사이 manual-visible 로 승격됐다면 userVisible 가
    // true 이므로 timeout 도 manual nothingToRestore 로 마무리된다.
    // cleanup·완료 처리는 *이 session* 이 아직 현재 session 일 때만.
    unawaited(session.waiter.future
        .timeout(_kRestoreTimeout, onTimeout: () {
      _finishRestoreSession(session, timedOut: true);
    }).whenComplete(() {
      if (identical(_restore, session)) {
        _restore = null;
      }
    }));
  }

  /// 프리미엄팩 구매 — paywall(Sprint 3) 이 호출.
  ///
  /// 재진입 방지:
  ///   - 이미 보유(entitled) 거나 다른 결제/복원이 진행 중(busy)이면 return.
  ///   - alreadyOwned 가 유도한 induced restore 가 pending 인 동안에도 return
  ///     — 영수증 확인 결과(restored/nothing/error)가 나오기 전 buyNonConsumable
  ///     을 다시 호출하면 storm 이 난다. session 이 끝나면(restored/nothing/
  ///     error/unavailable/timeout) _restore 가 null 이 되어 다시 허용된다.
  Future<void> purchasePremium() async {
    if (state.entitled || state.busy) return;
    if (_restore != null && _restore!.inducedByAlreadyOwned) return;
    state = state.copyWith(busy: true, clearLastResult: true);
    final started = await _service.buyPremium();
    if (!started) {
      // 시작 실패 — 결과는 콜백으로도 오지만, busy 는 여기서 해제.
      state = state.copyWith(busy: false);
    }
    // 성공 시작 시 busy=true 유지 → stream 결과(_onPurchaseResult)에서 해제.
  }

  /// 수동 "구매 복원" — paywall 하단 / 설정 화면(Sprint 3) 이 호출.
  /// 자동 복원과 달리, 복원할 게 없으면 nothingToRestore 를 알린다(toast 대상).
  ///
  /// nothingToRestore 가 오면 — StoreKit 이 빈 batch 로 즉시 알려주거나, 응답이
  /// 아예 없어 timeout 으로 판정되거나 — 이 Apple ID 에 프리미엄팩 구매 내역이
  /// 없다는 뜻이다. state.entitled 가 true 였더라도(캐시 위변조/환불) false 로
  /// 내리고 캐시도 false 로 갱신한다. App Store 가 source of truth.
  ///
  /// REWORK 3 — restore 호출 overlap 차단:
  ///   - 이미 복원 session 이 진행 중이면(_restore != null) 새 restorePurchases()
  ///     를 호출하지 않는다. 대신 그 session 을 manual-visible 로 *승격* 한다
  ///     (userVisible=true). 늦게 도착하는 그 session 의 empty/restored 가
  ///     그대로 이 수동 요청의 결과가 된다 — StoreKit restore 호출이 1개라
  ///     tag 없는 stream 이벤트도 misroute 될 수 없다.
  ///   - 진행 중 session 이 없을 때만 새 manual session + 1회 restore 호출.
  ///
  /// 재진입 방지: state.busy 면 즉시 return — 중복 진입 방지.
  Future<void> restorePurchases() async {
    if (state.busy) return;

    final existing = _restore;
    if (existing != null && !existing.waiter.isCompleted) {
      // 이미 복원 호출이 떠 있다(대개 부팅 auto restore). 새 호출을 추가하지
      // 않고 그 session 을 사용자에게 보이는 manual 복원으로 승격한다.
      existing.userVisible = true;
      state = state.copyWith(busy: true, clearLastResult: true);
      await _awaitRestoreSession(existing);
      return;
    }

    // 진행 중 session 없음 — 새 manual session + restore 호출 1회.
    state = state.copyWith(busy: true, clearLastResult: true);
    final session = _RestoreSession(isAuto: false, userVisible: true);
    session.restoreCallStarted = true;
    _restore = session;
    await _service.restorePurchases();
    await _awaitRestoreSession(session);
  }

  /// 복원 session 의 stream 응답(또는 timeout)을 기다린다.
  ///
  /// stream 응답이 먼저 오면 _onPurchaseResult 가 처리하고 waiter 를 닫는다.
  /// 응답이 끝내 안 오면 _kRestoreTimeout 후 [_finishRestoreSession] 이
  /// nothingToRestore 로 마무리한다(busy stuck 방지).
  Future<void> _awaitRestoreSession(_RestoreSession session) async {
    try {
      await session.waiter.future.timeout(_kRestoreTimeout);
    } on TimeoutException {
      _finishRestoreSession(session, timedOut: true);
    } finally {
      // 이 session 이 아직 현재 session 일 때만 정리(다른 작업이 교체했으면 보존).
      if (identical(_restore, session)) {
        _restore = null;
      }
    }
  }

  /// restore session 의 timeout 종결 처리 — auto/manual/induced 공통.
  ///
  /// stream 응답이 끝내 안 오면(빈 batch 조차) "복원 내역 없음"으로 본다.
  ///   - session 도중 purchased/restored 로 entitlement 가 살아났으면 강등 X.
  ///   - userVisible 면 nothingToRestore lastResult 노출(+ busy 해제),
  ///     아니면 무음. 어느 쪽이든 busy 는 반드시 false 로 — stuck 방지.
  void _finishRestoreSession(_RestoreSession session, {bool timedOut = false}) {
    // notifier 가 이미 dispose 됐으면 state 를 건드리지 않는다.
    if (_disposed) return;
    // 이미 끝난 session(다른 작업이 교체)이면 무시 — 늦은 timeout 콜백.
    if (!identical(_restore, session)) return;
    if (!session.waiter.isCompleted) {
      session.waiter.complete();
    }
    if (session.entitlementGranted) {
      // 이 session 도중 구매/복원 성공 — 강등 금지, busy 만 해제.
      state = state.copyWith(busy: false);
      return;
    }
    // 응답 없음 = 복원 내역 없음. 캐시 true 였다면 위변조/환불로 무효.
    // ignore: discarded_futures
    _writeCache(false);
    if (session.userVisible) {
      state = state.copyWith(
        entitled: false,
        busy: false,
        lastResult: PurchaseOutcome.nothingToRestore,
      );
    } else {
      // 순수 auto 복원 — 무음 강등.
      state = state.copyWith(entitled: false, busy: false);
    }
  }

  /// 마지막 결과 소비 후 비우기 — UI 가 toast 1회 표시 후 호출.
  void consumeResult() {
    if (state.lastResult != null) {
      state = state.copyWith(clearLastResult: true);
    }
  }

  /// 진행 중인 복원 session 의 waiter 를 complete 한다.
  /// restore 맥락의 결과(restored/nothingToRestore/error/unavailable)에서만
  /// 호출 — purchased/canceled/pending/alreadyOwned 는 restore context 를
  /// 닫지 않으므로 이 함수를 부르지 않는다.
  void _completeRestoreWaiter() {
    final session = _restore;
    if (session != null && !session.waiter.isCompleted) {
      session.waiter.complete();
    }
  }

  /// PurchaseService 콜백 — 신규 구매·복원·자동복원·에러 모두 여기로.
  ///
  /// entitlement 승격 규칙(monetization_playbook.md "결제의 영구성"):
  ///   - purchased / restored 만 entitled=true + 캐시 true. App Store 가
  ///     영수증을 확인해준 신호이기 때문.
  ///   - alreadyOwned 는 휴리스틱일 뿐 — entitlement 를 열지 않고, 대신
  ///     restorePurchases() 를 한 번 호출해 restored 이벤트를 유도한다.
  ///   - nothingToRestore 는 App Store 가 "구매 내역 없음"을 명시한 것 —
  ///     캐시 true 가 위변조/환불로 무효해진 것이므로 entitled/캐시를 내린다.
  ///     단, 같은 복원 session 도중 purchased/restored 가 먼저 들어와
  ///     entitlement 가 살아난 경우는 강등하지 않는다(stale empty batch).
  ///   - canceled / error / unavailable 은 결과가 불확실하므로 기존
  ///     entitlement/캐시를 보존한다(오프라인 기존 구매자 UX 유지).
  ///
  /// race 방어: restore waiter 는 restore 맥락의 결과로만 complete 한다.
  /// purchased/canceled/pending/alreadyOwned 가 waiter 를 닫아 restore
  /// context 를 잃게 만들지 않는다.
  void _onPurchaseResult(PurchaseResult result) {
    // notifier 가 이미 dispose 됐으면 state 를 건드리지 않는다.
    if (_disposed) return;
    final session = _restore;

    switch (result.outcome) {
      case PurchaseOutcome.pending:
        // 진행 중 — busy 유지, 상태 변화 없음. restore waiter 도 닫지 않음.
        return;

      case PurchaseOutcome.purchased:
      case PurchaseOutcome.restored:
        // App Store 가 확인한 신호 — entitlement 승격 + 캐시 persist.
        // 진행 중 복원 session 이 있으면 "entitlement 살아남"으로 표시해
        // 같은 session 의 늦은 empty batch 가 강등하지 못하게 한다.
        // (waiter 자체는 닫지 않는다 — 같은 session 의 후속 batch 를
        //  여전히 받을 수 있어야 하고, restored 면 아래서 닫는다.)
        if (session != null) {
          session.entitlementGranted = true;
        }
        // ignore: discarded_futures
        _writeCache(true);
        state = state.copyWith(
          entitled: true,
          busy: false,
          lastResult: result.outcome,
        );
        // restored 는 restore 맥락의 종결 신호 — waiter 를 닫아도 안전하다
        // (restore 작업이 성공으로 끝남). purchased 는 restore 맥락이
        // 아니므로 닫지 않는다.
        if (result.outcome == PurchaseOutcome.restored) {
          _completeRestoreWaiter();
        }
        return;

      case PurchaseOutcome.alreadyOwned:
        {
          // entitlement 를 열지 않는다. 영수증 확인을 위해 restore 를 유도 —
          // restored 이벤트가 오면 위 case 에서 entitlement 가 승격된다.
          // (restore 가 빈 batch 를 돌려주면 nothingToRestore 로 정리됨.)
          //
          // REWORK 3 — restore 호출 overlap 차단:
          //   - 이미 복원 session 이 진행 중이면(부팅 auto restore 포함) 새
          //     restorePurchases() 를 *추가 호출하지 않는다*. 대신 그 session
          //     을 induced/manual-visible 로 승격한다. 늦게 오는 그 session
          //     의 restored/empty 가 그대로 영수증 확인 결과가 된다 — restore
          //     호출이 1개라 tag 없는 stream 이벤트가 misroute 될 수 없다.
          //   - 진행 중 session 이 없을 때만 새 induced session + 1회 호출.
          //   - 어느 경우든 inducedByAlreadyOwned=true 로, restore 종결까지
          //     purchasePremium 재진입(buyNonConsumable storm)을 차단한다.
          final existing = _restore;
          if (existing != null && !existing.waiter.isCompleted) {
            // 진행 중 session 승격 — 새 호출 없음.
            existing.userVisible = true;
            existing.inducedByAlreadyOwned = true;
            // busy 는 restore 종결 신호(_onPurchaseResult/timeout)에서 해제.
            state = state.copyWith(busy: true, lastResult: result.outcome);
          } else {
            final induced = _RestoreSession(
              isAuto: false,
              userVisible: true,
              inducedByAlreadyOwned: true,
            );
            induced.restoreCallStarted = true;
            _restore = induced;
            state = state.copyWith(busy: true, lastResult: result.outcome);
            // ignore: discarded_futures
            _service.restorePurchases();
            unawaited(induced.waiter.future
                .timeout(_kRestoreTimeout, onTimeout: () {
              _finishRestoreSession(induced, timedOut: true);
            }).whenComplete(() {
              if (identical(_restore, induced)) {
                _restore = null;
              }
            }));
          }
          return;
        }

      case PurchaseOutcome.nothingToRestore:
        {
          // REWORK 3 — 진행 중 복원 session 이 없을 때(_restore == null) 도착한
          // empty batch 는 우리가 기다리던 복원 결과가 아니라 unsolicited
          // 잔여 stream noise(예: 직전 session 의 trailing empty)다.
          // nothingToRestore 는 "명확한 복원 결과일 때만" 강등해야 하므로
          // (spec G), session 이 없으면 강등하지 않고 무시한다. 이로써
          // restored 로 끝난 session 이후 늦게 오는 empty 가 정상 구매자를
          // 강등하지 못한다(spec F·#9).
          if (session == null) {
            return;
          }
          // App Store 가 "이 Apple ID 에 구매 내역 없음"을 명시.
          // restore 맥락의 종결 신호 — waiter 를 닫는다.
          _completeRestoreWaiter();
          // 같은 복원 session 도중 purchased/restored 로 entitlement 가
          // 이미 살아났다면, 이 empty batch 는 stale 이므로 무시한다
          // (정상 구매자 강등 방지).
          if (session.entitlementGranted) {
            state = state.copyWith(busy: false);
            return;
          }
          // 캐시 true 였다면 위변조/환불로 무효해진 것 → 내린다.
          if (state.entitled) {
            // ignore: discarded_futures
            _writeCache(false);
          }
          // REWORK 3 — 결과 노출 여부는 isAuto 가 아니라 userVisible 로
          // 판정한다. auto 로 시작했어도 수동 복원/alreadyOwned 로 승격되어
          // userVisible 가 true 면 "복원할 내역 없음" 을 알린다.
          if (session.userVisible) {
            // 수동/승격 복원 — "복원할 내역 없음" 알림.
            state = state.copyWith(
              busy: false,
              entitled: false,
              lastResult: PurchaseOutcome.nothingToRestore,
            );
          } else {
            // 순수 자동 복원 — toast/lastResult 없이 무음. 캐시 true 였으면 false.
            state = state.copyWith(busy: false, entitled: false);
          }
          return;
        }

      case PurchaseOutcome.unavailable:
      case PurchaseOutcome.error:
        // restore 맥락의 결과일 수 있음 — waiter 를 닫아 timeout 대기 종료.
        // (구매 맥락의 error 라도 waiter 가 있으면 닫는 게 안전하다:
        //  restore session 이 timeout 까지 대기하지 않게 함. entitlement 는
        //  아래서 보존하므로 강등 위험 없음.)
        _completeRestoreWaiter();
        // graceful — 결과 불확실. 기존 entitlement/캐시 보존(콘텐츠 영구잠금 방지).
        state = state.copyWith(busy: false, lastResult: result.outcome);
        return;

      case PurchaseOutcome.canceled:
        // 사용자 취소 — 구매 맥락. restore waiter 는 닫지 않는다
        // (restore context 를 잃지 않게).
        state = state.copyWith(busy: false, lastResult: result.outcome);
        return;
    }
  }

  // ── shared_preferences 캐시 (source of truth 아님) ──────────────────

  Future<bool> _readCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_kPremiumCacheKey) ?? false;
    } catch (e) {
      debugPrint('[PremiumNotifier] readCache failed: $e');
      return false;
    }
  }

  Future<void> _writeCache(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kPremiumCacheKey, value);
    } catch (e) {
      debugPrint('[PremiumNotifier] writeCache failed: $e');
    }
  }
}

/// 실제 결제 entitlement provider.
final premiumProvider =
    NotifierProvider<PremiumNotifier, PremiumState>(PremiumNotifier.new);

/// 프리미엄 콘텐츠 접근 허용 여부 — Sprint 2 기능 게이트가 watch 할 provider.
///
/// 실제 결제(premiumProvider.entitled) OR 개발자 unlock(devUnlockProvider).
/// dev unlock 은 release 빌드에서 항상 false(dev_unlock_provider.kDevGateEnabled)
/// 이므로, 정식 출시 빌드에서는 오직 실제 결제만 프리미엄을 연다.
final isPremiumUnlockedProvider = Provider<bool>((ref) {
  final paid = ref.watch(premiumProvider.select((s) => s.entitled));
  final devUnlocked = ref.watch(devUnlockProvider);
  return paid || devUnlocked;
});
