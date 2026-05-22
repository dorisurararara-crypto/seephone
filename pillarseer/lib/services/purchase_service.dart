// Pillar Seer — R110 Sprint 1: 인앱결제(IAP) 인프라 서비스.
//
// 상품: com.ganziman.pillarseer.premium_pack — non-consumable 단건 (₩5,900 / $4.99).
// 자동갱신 결제·광고·외부결제 없음. StoreKit(in_app_purchase) 단건 IAP 만 사용.
//
// 책임 분리:
//   - PurchaseService = StoreKit 와의 모든 상호작용(상품 조회·구매·복원·스트림 처리).
//   - PremiumNotifier(premium_provider.dart) = entitlement 상태를 앱에 expose.
// PurchaseService 는 상태를 직접 들고 있지 않고, 콜백으로 결과만 흘려보낸다.
//
// 핵심 원칙(monetization_playbook.md "결제의 영구성"):
//   - non-consumable 은 Apple ID 에 영구 귀속. 로컬 저장은 캐시일 뿐.
//   - 진짜 source of truth = App Store. 앱 시작 시 조용히 자동 복원.
//   - StoreKit 실패/네트워크 끊김에도 앱이 죽거나 콘텐츠가 영구히 잠기지 않음
//     (graceful fallback — premium 못 확인하면 false 로 두되 캐시는 보존).

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

/// 프리미엄팩 상품 ID — ASC IAP 와 정확히 일치해야 함.
const String kPremiumPackProductId = 'com.ganziman.pillarseer.premium_pack';

/// IAP 결과 분류 — provider/UI 가 toast·로그에 사용.
enum PurchaseOutcome {
  /// 결제 진행 중 — 아직 entitlement 부여 X. UI 는 로딩만.
  pending,

  /// 신규 구매 성공.
  purchased,

  /// 복원으로 entitlement 확인됨(자동 복원 포함).
  restored,

  /// 사용자가 결제를 취소함.
  canceled,

  /// 이미 보유 중인 상품을 다시 구매 시도(StoreKit 이 거른 경우).
  /// 이 결과 자체는 entitlement 를 부여하지 않는다 — provider 가 restore 를
  /// 유도하고, restored 이벤트가 와야 entitlement 가 승격된다.
  alreadyOwned,

  /// 결제/네트워크/StoreKit 오류.
  error,

  /// StoreKit 사용 불가(시뮬레이터·미지원 환경 등) — 앱은 무료로 정상 동작.
  unavailable,

  /// 복원했으나 해당 Apple ID 의 구매 내역이 없음.
  nothingToRestore,
}

/// StoreKit 백엔드 추상화 — PurchaseService 가 의존하는 최소 표면.
///
/// 기본 구현([StoreKitIapBackend])은 `InAppPurchase.instance` 위에 얹는다.
/// `InAppPurchase` 는 private 생성자라 직접 mock 할 수 없으므로, 이 인터페이스를
/// 두고 test 에서 fake backend 를 주입한다(상태 전이 검증용).
abstract class IapBackend {
  /// StoreKit 사용 가능 여부.
  Future<bool> isAvailable();

  /// 결제/복원 결과가 흘러오는 스트림.
  Stream<List<PurchaseDetails>> get purchaseStream;

  /// 상품 정보 조회.
  Future<ProductDetailsResponse> queryProductDetails(Set<String> ids);

  /// non-consumable 구매 시작.
  Future<bool> buyNonConsumable({required PurchaseParam purchaseParam});

  /// 과거 구매 복원(자동/수동 공용 — past purchases 를 stream 으로 재전달).
  Future<void> restorePurchases();

  /// 구매 완료 처리(stream 재전달 방지).
  Future<void> completePurchase(PurchaseDetails purchase);
}

/// 실서비스용 백엔드 — `InAppPurchase.instance` 위임.
class StoreKitIapBackend implements IapBackend {
  StoreKitIapBackend([InAppPurchase? iap])
      : _iap = iap ?? InAppPurchase.instance;

  final InAppPurchase _iap;

  @override
  Future<bool> isAvailable() => _iap.isAvailable();

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => _iap.purchaseStream;

  @override
  Future<ProductDetailsResponse> queryProductDetails(Set<String> ids) =>
      _iap.queryProductDetails(ids);

  @override
  Future<bool> buyNonConsumable({required PurchaseParam purchaseParam}) =>
      _iap.buyNonConsumable(purchaseParam: purchaseParam);

  @override
  Future<void> restorePurchases() => _iap.restorePurchases();

  @override
  Future<void> completePurchase(PurchaseDetails purchase) =>
      _iap.completePurchase(purchase);
}

/// PurchaseService 가 콜백으로 넘기는 1건의 결과.
@immutable
class PurchaseResult {
  const PurchaseResult(this.outcome, {this.message, this.isPremium = false});

  final PurchaseOutcome outcome;

  /// 로그/디버그용 부가 메시지(사용자 노출 문구는 UI 가 l10n 으로 결정).
  final String? message;

  /// 이 결과로 프리미엄 entitlement 가 활성화되어야 하는지.
  ///
  /// **App Store 가 확인한 신호일 때만 true.** 즉 purchased / restored 만 true.
  /// alreadyOwned 는 StoreKit 의 error 메시지 휴리스틱일 뿐 영수증 확인이 아니므로
  /// 절대 true 를 주지 않는다 — entitlement 는 뒤따르는 restored/purchased
  /// 이벤트로만 승격된다(provider 가 restore 를 유도).
  final bool isPremium;

  @override
  String toString() =>
      'PurchaseResult($outcome, isPremium=$isPremium, message=$message)';
}

/// StoreKit IAP 인프라. 앱 전역에서 1 인스턴스만 쓰는 것을 전제로 설계하되,
/// test 에서는 [backend] 로 fake [IapBackend] 를 주입할 수 있다.
class PurchaseService {
  PurchaseService({IapBackend? backend})
      : _iap = backend ?? StoreKitIapBackend();

  final IapBackend _iap;

  StreamSubscription<List<PurchaseDetails>>? _sub;

  /// 조회된 프리미엄팩 상품(가격·통화 등 localized). 미조회 시 null.
  ProductDetails? _premiumProduct;
  ProductDetails? get premiumProduct => _premiumProduct;

  /// StoreKit 자체가 사용 불가한 환경인지(시뮬레이터 등).
  bool _storeAvailable = true;
  bool get storeAvailable => _storeAvailable;

  bool _initialized = false;
  bool _disposed = false;

  /// 결제/복원 결과를 받을 콜백. provider 가 set.
  void Function(PurchaseResult result)? onPurchaseUpdate;

  /// 인프라 초기화 — purchase stream listen + 상품 사전 조회.
  ///
  /// 어떤 단계가 실패해도 throw 하지 않는다(graceful). StoreKit 사용 불가나
  /// 상품 조회 실패 시 [storeAvailable]/[premiumProduct] 로만 드러난다.
  Future<void> init() async {
    if (_initialized || _disposed) return;
    _initialized = true;

    try {
      _storeAvailable = await _iap.isAvailable();
    } catch (e) {
      _storeAvailable = false;
      debugPrint('[PurchaseService] isAvailable failed: $e');
    }

    // purchase stream 은 store 사용 가능 여부와 무관하게 listen 해 둔다.
    // listen 자체가 실패해도 앱은 무료로 정상 동작.
    try {
      _sub = _iap.purchaseStream.listen(
        _onPurchaseStream,
        onError: (Object e) =>
            debugPrint('[PurchaseService] purchaseStream error: $e'),
      );
    } catch (e) {
      debugPrint('[PurchaseService] purchaseStream listen failed: $e');
    }

    if (_storeAvailable) {
      await _queryPremiumProduct();
    }
  }

  /// 프리미엄팩 상품 조회. 실패해도 throw 하지 않음.
  Future<ProductDetails?> _queryPremiumProduct() async {
    try {
      final response =
          await _iap.queryProductDetails({kPremiumPackProductId});
      if (response.error != null) {
        debugPrint(
            '[PurchaseService] queryProductDetails error: ${response.error}');
      }
      if (response.productDetails.isNotEmpty) {
        _premiumProduct = response.productDetails.firstWhere(
          (p) => p.id == kPremiumPackProductId,
          orElse: () => response.productDetails.first,
        );
      } else {
        debugPrint('[PurchaseService] premium pack not found in store '
            '(notFoundIDs: ${response.notFoundIDs})');
      }
    } catch (e) {
      debugPrint('[PurchaseService] queryProductDetails failed: $e');
    }
    return _premiumProduct;
  }

  /// UI(paywall) 가 호출. 상품이 아직 없으면 1회 재조회 시도.
  /// 반환값 null = 상품 없음/스토어 불가 → UI 는 안내만.
  Future<ProductDetails?> ensurePremiumProduct() async {
    if (_premiumProduct != null) return _premiumProduct;
    if (!_storeAvailable) return null;
    return _queryPremiumProduct();
  }

  /// 프리미엄팩 구매 시작. 결과는 [onPurchaseUpdate] 콜백으로 비동기 전달.
  ///
  /// 즉시 반환값:
  ///   - true  = 구매 플로우가 StoreKit 에 정상 제출됨.
  ///   - false = 시작조차 못 함(스토어 불가/상품 없음/예외) → UI 가 안내.
  Future<bool> buyPremium() async {
    if (!_storeAvailable) {
      onPurchaseUpdate?.call(const PurchaseResult(PurchaseOutcome.unavailable));
      return false;
    }
    final product = await ensurePremiumProduct();
    if (product == null) {
      onPurchaseUpdate
          ?.call(const PurchaseResult(PurchaseOutcome.unavailable));
      return false;
    }
    try {
      final param = PurchaseParam(productDetails: product);
      // non-consumable → buyNonConsumable.
      final ok = await _iap.buyNonConsumable(purchaseParam: param);
      if (!ok) {
        onPurchaseUpdate?.call(const PurchaseResult(
          PurchaseOutcome.error,
          message: 'buyNonConsumable returned false',
        ));
      }
      return ok;
    } catch (e) {
      debugPrint('[PurchaseService] buyNonConsumable failed: $e');
      onPurchaseUpdate?.call(PurchaseResult(
        PurchaseOutcome.error,
        message: e.toString(),
      ));
      return false;
    }
  }

  /// 수동 "구매 복원" — Sprint 3 의 paywall/설정 버튼이 호출.
  /// 결과는 purchaseStream 을 통해 [onPurchaseUpdate] 로 들어온다.
  /// (StoreKit 은 복원할 게 없으면 stream 에 아무것도 안 보내므로,
  ///  provider 가 timeout 후 nothingToRestore 로 마무리한다.)
  Future<void> restorePurchases() async {
    if (!_storeAvailable) {
      onPurchaseUpdate?.call(const PurchaseResult(PurchaseOutcome.unavailable));
      return;
    }
    try {
      await _iap.restorePurchases();
    } catch (e) {
      debugPrint('[PurchaseService] restorePurchases failed: $e');
      onPurchaseUpdate?.call(PurchaseResult(
        PurchaseOutcome.error,
        message: e.toString(),
      ));
    }
  }

  /// 앱 시작 시 조용한 자동 복원(silent auto-restore).
  ///
  /// StoreKit 의 past purchases 를 조회해, 같은 Apple ID 가 프리미엄팩을
  /// 이미 보유 중이면 사용자 액션 없이 entitlement 가 살아난다.
  /// in_app_purchase 에서는 [restorePurchases] 가 past purchases 를
  /// purchaseStream 으로 다시 흘려보내는 메커니즘이므로, 그대로 재사용한다.
  /// 자동 복원 맥락에서는 "복원할 게 없음"이 정상이므로 toast 를 띄우지 않는다
  /// — provider 가 [_RestoreSession.userVisible] 로 nothingToRestore 를 무음 처리.
  ///
  /// 반환값 = restore 호출이 StoreKit 에 *정상 제출되었는지*.
  ///   - true  = `restorePurchases()` 가 throw 없이 제출됨. 이후 stream(빈
  ///             batch 포함)으로 결과가 흘러온다 → provider 가 session 을
  ///             timeout waiter 로 마무리.
  ///   - false = store 사용 불가, 또는 `restorePurchases()` 가 throw —
  ///             결과가 *불확실*하다. provider 는 이 경우 entitlement/캐시를
  ///             강등하지 않고 session 만 정리한다(기존 구매자 보존).
  /// 자동 복원은 무음이어야 하므로, throw 시에도 [onPurchaseUpdate] error 를
  /// 호출하지 않는다(debugPrint 만).
  Future<bool> autoRestore() async {
    if (!_storeAvailable) return false;
    try {
      await _iap.restorePurchases();
      return true;
    } catch (e) {
      // 자동 복원 실패는 조용히 넘어간다(무음 — toast/콜백 없음). 사용자는
      // 수동 버튼으로 재시도 가능. provider 는 false 를 받아 entitlement/캐시를
      // 보존한 채 session 만 닫는다("복원 내역 없음"이 아니라 "결과 불확실").
      debugPrint('[PurchaseService] autoRestore failed (silent): $e');
      return false;
    }
  }

  /// purchaseStream 콜백 — 신규 구매·복원·자동복원 모두 여기로 들어온다.
  Future<void> _onPurchaseStream(List<PurchaseDetails> purchases) async {
    // 빈 리스트 = StoreKit 이 복원할 past purchase 가 하나도 없음을 명시.
    // (in_app_purchase 는 restore 완료 시 빈 batch 를 한 번 흘려보낸다.)
    // timeout 에 의존하지 않고 즉시 nothingToRestore 로 마무리한다 —
    // 자동 복원 맥락에서는 provider 가 이 결과를 무음 처리한다.
    if (purchases.isEmpty) {
      onPurchaseUpdate
          ?.call(const PurchaseResult(PurchaseOutcome.nothingToRestore));
      return;
    }
    for (final p in purchases) {
      try {
        await _handleOne(p);
      } catch (e) {
        debugPrint('[PurchaseService] handle purchase failed: $e');
      }
    }
  }

  Future<void> _handleOne(PurchaseDetails p) async {
    switch (p.status) {
      case PurchaseStatus.pending:
        // 결제 진행 중 — 아직 entitlement 부여 X. UI 는 로딩만.
        onPurchaseUpdate?.call(const PurchaseResult(PurchaseOutcome.pending));
        break;

      case PurchaseStatus.purchased:
      case PurchaseStatus.restored:
        final isPremiumPack = p.productID == kPremiumPackProductId;
        if (isPremiumPack) {
          final restored = p.status == PurchaseStatus.restored;
          onPurchaseUpdate?.call(PurchaseResult(
            restored ? PurchaseOutcome.restored : PurchaseOutcome.purchased,
            isPremium: true,
            message: 'productID=${p.productID}',
          ));
        }
        // 완료 처리 — non-consumable 도 completePurchase 필수
        // (안 하면 stream 에 계속 재전달됨).
        await _completeIfNeeded(p);
        break;

      case PurchaseStatus.canceled:
        onPurchaseUpdate
            ?.call(const PurchaseResult(PurchaseOutcome.canceled));
        await _completeIfNeeded(p);
        break;

      case PurchaseStatus.error:
        final err = p.error;
        // StoreKit 의 "이미 보유" 류 오류는 alreadyOwned 로 분류한다.
        // 단, 이 메시지는 영수증 확인이 아니라 휴리스틱이므로 entitlement 를
        // 절대 부여하지 않는다(isPremium=false). provider 가 이 신호를 받아
        // restorePurchases() 를 호출하면, restored 이벤트가 와야 비로소
        // entitlement 가 승격된다.
        if (_looksAlreadyOwned(err)) {
          onPurchaseUpdate?.call(PurchaseResult(
            PurchaseOutcome.alreadyOwned,
            message: err?.message,
          ));
        } else {
          onPurchaseUpdate?.call(PurchaseResult(
            PurchaseOutcome.error,
            message: err?.message,
          ));
        }
        await _completeIfNeeded(p);
        break;
    }
  }

  bool _looksAlreadyOwned(IAPError? err) {
    if (err == null) return false;
    final msg = '${err.code} ${err.message}'.toLowerCase();
    return msg.contains('already') ||
        msg.contains('owned') ||
        msg.contains('purchased');
  }

  Future<void> _completeIfNeeded(PurchaseDetails p) async {
    if (!p.pendingCompletePurchase) return;
    try {
      await _iap.completePurchase(p);
    } catch (e) {
      debugPrint('[PurchaseService] completePurchase failed: $e');
    }
  }

  /// stream listen 해제 — 앱/provider 종료 시.
  Future<void> dispose() async {
    _disposed = true;
    await _sub?.cancel();
    _sub = null;
    onPurchaseUpdate = null;
  }
}
