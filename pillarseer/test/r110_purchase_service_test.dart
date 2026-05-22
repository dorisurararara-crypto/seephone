// R110 Sprint 1 — IAP 인프라 상태 전이 검증.
//
// StoreKit 실제 결제는 sandbox/실기기에서만 가능하므로, 여기서는 fake IapBackend 로
// PurchaseService / PremiumNotifier 의 상태 전이만 검증한다:
//   - premium 기본값 false
//   - 구매 성공 시 true (+ 캐시 persist)
//   - 복원 성공 시 true
//   - 자동 복원으로 보유자 자동 unlock
//   - 상품 없음 / error / 스토어 불가 시 크래시 없음 · premium false 유지
//   - 취소 시 false 유지
//   - 캐시 선반영 (오프라인 entitlement)
//
// REWORK (codex 7.4 → ) — entitlement source-of-truth 보안:
//   - alreadyOwned error 단독으로는 entitlement 를 열지 않는다.
//   - 빈 restore batch = nothingToRestore 즉시 처리(8초 timeout 의존 X).
//   - 캐시 true + autoRestore 빈 batch → entitled false + 캐시 false (무음).
//   - 캐시 true + store unavailable/error → entitled true 보존(오프라인 UX).
//   - 캐시 true + 수동 restore 빈 batch → entitled false + 캐시 false + toast.
//
// REWORK 4 (codex 9.1 → ) — autoRestore API throw 가 cache false 강등 막기:
//   - autoRestore() 가 Future<bool> 로, restore 호출 성공 제출이면 true,
//     store 불가/throw 면 false.
//   - 캐시 true + autoRestore API throw → entitled true · 캐시 true 보존 ·
//     busy false · lastResult null (결과 불확실 — "복원 내역 없음" 아님).
//   - manual restore API throw → entitlement/캐시 보존 · busy false · error.
//   - alreadyOwned-induced restore API throw → busy false · buyNonConsumable
//     storm 없음 · entitlement/캐시 강등 없음.

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:pillarseer/providers/premium_provider.dart';
import 'package:pillarseer/services/purchase_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── Fake StoreKit backend ───────────────────────────────────────────────

class _FakeIapBackend implements IapBackend {
  _FakeIapBackend({
    this.available = true,
    this.productFound = true,
    this.buyThrows = false,
    this.restoreThrows = false,
  });

  bool available;
  bool productFound;
  bool buyThrows;

  /// true 면 [restorePurchases] 가 StoreKit API 오류처럼 throw 한다 —
  /// auto/manual/induced 복원이 호출 자체로 실패하는 상황을 흉내낸다.
  bool restoreThrows;

  final StreamController<List<PurchaseDetails>> _ctrl =
      StreamController<List<PurchaseDetails>>.broadcast();

  int restoreCallCount = 0;
  int completeCallCount = 0;
  int buyCallCount = 0;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => _ctrl.stream;

  @override
  Future<ProductDetailsResponse> queryProductDetails(Set<String> ids) async {
    if (!productFound) {
      return ProductDetailsResponse(
        productDetails: const [],
        notFoundIDs: ids.toList(),
      );
    }
    return ProductDetailsResponse(
      productDetails: [
        ProductDetails(
          id: kPremiumPackProductId,
          title: 'Premium Pack',
          description: 'Unlock deeper saju readings.',
          price: '₩5,900',
          rawPrice: 5900,
          currencyCode: 'KRW',
        ),
      ],
      notFoundIDs: const [],
    );
  }

  @override
  Future<bool> buyNonConsumable({required PurchaseParam purchaseParam}) async {
    buyCallCount++;
    if (buyThrows) throw Exception('storekit boom');
    return true;
  }

  @override
  Future<void> restorePurchases() async {
    restoreCallCount++;
    if (restoreThrows) throw Exception('storekit restore boom');
  }

  @override
  Future<void> completePurchase(PurchaseDetails purchase) async {
    completeCallCount++;
  }

  /// 테스트가 StoreKit 의 purchaseStream 이벤트를 흉내내는 헬퍼.
  void emit(PurchaseStatus status,
      {String productId = kPremiumPackProductId,
      IAPError? error,
      bool pendingComplete = true}) {
    final d = PurchaseDetails(
      productID: productId,
      status: status,
      verificationData: PurchaseVerificationData(
        localVerificationData: '',
        serverVerificationData: '',
        source: 'test',
      ),
      transactionDate: null,
    );
    d.error = error;
    d.pendingCompletePurchase = pendingComplete;
    _ctrl.add([d]);
  }

  /// StoreKit 이 복원 완료 후 흘려보내는 "복원할 게 없음" 빈 batch.
  void emitEmpty() => _ctrl.add(const <PurchaseDetails>[]);

  Future<void> close() => _ctrl.close();
}

// PremiumNotifier 의 service override 를 위한 fake PurchaseService 가 아니라,
// 실제 PurchaseService 에 fake backend 를 주입해 통째로 검증한다.
PurchaseService _serviceWith(_FakeIapBackend backend) =>
    PurchaseService(backend: backend);

ProviderContainer _container(PurchaseService service) {
  final c = ProviderContainer(
    overrides: [
      premiumProvider.overrideWith(
        () => PremiumNotifier(serviceOverride: service),
      ),
    ],
  );
  addTearDown(c.dispose);
  return c;
}

/// pending 비동기 작업이 흘러갈 시간을 준다.
Future<void> _settle() => Future<void>.delayed(const Duration(milliseconds: 30));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('R110 — PurchaseService (fake StoreKit backend)', () {
    test('init: 스토어 가능 시 storeAvailable true + 상품 조회', () async {
      final backend = _FakeIapBackend();
      final svc = _serviceWith(backend);
      await svc.init();
      expect(svc.storeAvailable, isTrue);
      expect(svc.premiumProduct, isNotNull);
      expect(svc.premiumProduct!.id, kPremiumPackProductId);
      await svc.dispose();
      await backend.close();
    });

    test('init: 스토어 불가여도 throw 없음 · storeAvailable false', () async {
      final backend = _FakeIapBackend(available: false);
      final svc = _serviceWith(backend);
      await svc.init(); // must not throw
      expect(svc.storeAvailable, isFalse);
      expect(svc.premiumProduct, isNull);
      await svc.dispose();
      await backend.close();
    });

    test('buyPremium: 상품 없으면 unavailable 결과 · 크래시 없음', () async {
      final backend = _FakeIapBackend(productFound: false);
      final svc = _serviceWith(backend);
      PurchaseResult? last;
      svc.onPurchaseUpdate = (r) => last = r;
      await svc.init();
      final started = await svc.buyPremium();
      expect(started, isFalse);
      expect(last?.outcome, PurchaseOutcome.unavailable);
      await svc.dispose();
      await backend.close();
    });

    test('buyPremium: backend throw 시 error 결과 · 크래시 없음', () async {
      final backend = _FakeIapBackend(buyThrows: true);
      final svc = _serviceWith(backend);
      PurchaseResult? last;
      svc.onPurchaseUpdate = (r) => last = r;
      await svc.init();
      final started = await svc.buyPremium();
      expect(started, isFalse);
      expect(last?.outcome, PurchaseOutcome.error);
      await svc.dispose();
      await backend.close();
    });

    test('purchaseStream purchased → isPremium true · completePurchase 호출',
        () async {
      final backend = _FakeIapBackend();
      final svc = _serviceWith(backend);
      final results = <PurchaseResult>[];
      svc.onPurchaseUpdate = results.add;
      await svc.init();
      backend.emit(PurchaseStatus.purchased);
      await _settle();
      expect(results.any((r) => r.outcome == PurchaseOutcome.purchased), isTrue);
      expect(results.last.isPremium, isTrue);
      expect(backend.completeCallCount, 1);
      await svc.dispose();
      await backend.close();
    });

    test('purchaseStream restored → restored 결과 · isPremium true', () async {
      final backend = _FakeIapBackend();
      final svc = _serviceWith(backend);
      final results = <PurchaseResult>[];
      svc.onPurchaseUpdate = results.add;
      await svc.init();
      backend.emit(PurchaseStatus.restored);
      await _settle();
      expect(results.any((r) => r.outcome == PurchaseOutcome.restored), isTrue);
      expect(results.last.isPremium, isTrue);
      await svc.dispose();
      await backend.close();
    });

    test('purchaseStream canceled → canceled 결과 · isPremium false', () async {
      final backend = _FakeIapBackend();
      final svc = _serviceWith(backend);
      final results = <PurchaseResult>[];
      svc.onPurchaseUpdate = results.add;
      await svc.init();
      backend.emit(PurchaseStatus.canceled);
      await _settle();
      expect(results.last.outcome, PurchaseOutcome.canceled);
      expect(results.last.isPremium, isFalse);
      await svc.dispose();
      await backend.close();
    });

    test('purchaseStream error(already owned) → alreadyOwned · isPremium false',
        () async {
      // REWORK — alreadyOwned 는 휴리스틱일 뿐. entitlement 를 절대 안 연다.
      final backend = _FakeIapBackend();
      final svc = _serviceWith(backend);
      final results = <PurchaseResult>[];
      svc.onPurchaseUpdate = results.add;
      await svc.init();
      backend.emit(
        PurchaseStatus.error,
        error: IAPError(
          source: 'app_store',
          code: 'already_owned',
          message: 'This product is already owned.',
        ),
      );
      await _settle();
      expect(results.last.outcome, PurchaseOutcome.alreadyOwned);
      expect(results.last.isPremium, isFalse);
      await svc.dispose();
      await backend.close();
    });

    test('purchaseStream 빈 batch → nothingToRestore 즉시 (timeout 의존 X)',
        () async {
      // REWORK — StoreKit 이 복원 완료 후 빈 batch 를 흘려보내면, 8초 timeout
      // 을 기다리지 않고 즉시 nothingToRestore 결과를 낸다.
      final backend = _FakeIapBackend();
      final svc = _serviceWith(backend);
      final results = <PurchaseResult>[];
      svc.onPurchaseUpdate = results.add;
      await svc.init();
      backend.emitEmpty();
      await _settle();
      expect(results.length, 1);
      expect(results.last.outcome, PurchaseOutcome.nothingToRestore);
      expect(results.last.isPremium, isFalse);
      await svc.dispose();
      await backend.close();
    });

    test('purchaseStream error(generic) → error · isPremium false', () async {
      final backend = _FakeIapBackend();
      final svc = _serviceWith(backend);
      final results = <PurchaseResult>[];
      svc.onPurchaseUpdate = results.add;
      await svc.init();
      backend.emit(
        PurchaseStatus.error,
        error: IAPError(
          source: 'app_store',
          code: 'network',
          message: 'Network unavailable.',
        ),
      );
      await _settle();
      expect(results.last.outcome, PurchaseOutcome.error);
      expect(results.last.isPremium, isFalse);
      await svc.dispose();
      await backend.close();
    });

    test('purchaseStream pending → pending 결과 (entitlement 부여 X)', () async {
      final backend = _FakeIapBackend();
      final svc = _serviceWith(backend);
      final results = <PurchaseResult>[];
      svc.onPurchaseUpdate = results.add;
      await svc.init();
      backend.emit(PurchaseStatus.pending);
      await _settle();
      expect(results.last.outcome, PurchaseOutcome.pending);
      expect(results.last.isPremium, isFalse);
      await svc.dispose();
      await backend.close();
    });
  });

  group('R110 — PremiumNotifier (entitlement provider)', () {
    test('premium 기본값 false', () async {
      final backend = _FakeIapBackend();
      final c = _container(_serviceWith(backend));
      final s = c.read(premiumProvider);
      expect(s.entitled, isFalse);
      await _settle();
      // 자동 복원 후에도 (보유 없음) false 유지.
      expect(c.read(premiumProvider).entitled, isFalse);
      await backend.close();
    });

    test('구매 성공 시 entitled true · 캐시 persist', () async {
      final backend = _FakeIapBackend();
      final c = _container(_serviceWith(backend));
      c.read(premiumProvider); // boot
      await _settle();
      await c.read(premiumProvider.notifier).purchasePremium();
      backend.emit(PurchaseStatus.purchased);
      await _settle();
      expect(c.read(premiumProvider).entitled, isTrue);
      expect(c.read(premiumProvider).lastResult, PurchaseOutcome.purchased);
      // 캐시 persist 확인.
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('app.premium.entitled'), isTrue);
      await backend.close();
    });

    test('수동 restore 성공 시 entitled true', () async {
      final backend = _FakeIapBackend();
      final c = _container(_serviceWith(backend));
      c.read(premiumProvider);
      await _settle();
      final restoreFuture =
          c.read(premiumProvider.notifier).restorePurchases();
      backend.emit(PurchaseStatus.restored);
      await restoreFuture;
      expect(c.read(premiumProvider).entitled, isTrue);
      expect(c.read(premiumProvider).lastResult, PurchaseOutcome.restored);
      await backend.close();
    });

    test('자동 복원: 보유자면 사용자 액션 없이 entitled true', () async {
      final backend = _FakeIapBackend();
      final c = _container(_serviceWith(backend));
      c.read(premiumProvider); // boot → autoRestore
      await _settle();
      // 부팅 중 autoRestore() 가 restorePurchases 호출.
      expect(backend.restoreCallCount, greaterThanOrEqualTo(1));
      // StoreKit 이 past purchase 를 stream 으로 재전달.
      backend.emit(PurchaseStatus.restored);
      await _settle();
      expect(c.read(premiumProvider).entitled, isTrue);
      await backend.close();
    });

    test('캐시 선반영: 이전 구매 캐시 있으면 부팅 즉시 entitled true', () async {
      SharedPreferences.setMockInitialValues({'app.premium.entitled': true});
      final backend = _FakeIapBackend();
      final c = _container(_serviceWith(backend));
      c.read(premiumProvider);
      await _settle();
      expect(c.read(premiumProvider).entitled, isTrue);
      await backend.close();
    });

    test('스토어 불가 시 크래시 없음 · entitled false · storeAvailable false',
        () async {
      final backend = _FakeIapBackend(available: false);
      final c = _container(_serviceWith(backend));
      c.read(premiumProvider);
      await _settle();
      final s = c.read(premiumProvider);
      expect(s.entitled, isFalse);
      expect(s.storeAvailable, isFalse);
      await backend.close();
    });

    test('상품 없음 + 구매 시도 → entitled false 유지 · 크래시 없음', () async {
      final backend = _FakeIapBackend(productFound: false);
      final c = _container(_serviceWith(backend));
      c.read(premiumProvider);
      await _settle();
      await c.read(premiumProvider.notifier).purchasePremium();
      await _settle();
      final s = c.read(premiumProvider);
      expect(s.entitled, isFalse);
      expect(s.lastResult, PurchaseOutcome.unavailable);
      await backend.close();
    });

    test('error 결과 시 entitled false 유지 (콘텐츠 영구잠금 없음)', () async {
      final backend = _FakeIapBackend();
      final c = _container(_serviceWith(backend));
      c.read(premiumProvider);
      await _settle();
      await c.read(premiumProvider.notifier).purchasePremium();
      backend.emit(
        PurchaseStatus.error,
        error: IAPError(
          source: 'app_store',
          code: 'network',
          message: 'Network unavailable.',
        ),
      );
      await _settle();
      final s = c.read(premiumProvider);
      expect(s.entitled, isFalse);
      expect(s.lastResult, PurchaseOutcome.error);
      expect(s.busy, isFalse);
      await backend.close();
    });

    test('취소 결과 시 entitled false 유지 · busy 해제', () async {
      final backend = _FakeIapBackend();
      final c = _container(_serviceWith(backend));
      c.read(premiumProvider);
      await _settle();
      await c.read(premiumProvider.notifier).purchasePremium();
      backend.emit(PurchaseStatus.canceled);
      await _settle();
      final s = c.read(premiumProvider);
      expect(s.entitled, isFalse);
      expect(s.lastResult, PurchaseOutcome.canceled);
      expect(s.busy, isFalse);
      await backend.close();
    });

    test('consumeResult: lastResult 비우기', () async {
      final backend = _FakeIapBackend();
      final c = _container(_serviceWith(backend));
      c.read(premiumProvider);
      await _settle();
      await c.read(premiumProvider.notifier).purchasePremium();
      backend.emit(PurchaseStatus.purchased);
      await _settle();
      expect(c.read(premiumProvider).lastResult, PurchaseOutcome.purchased);
      c.read(premiumProvider.notifier).consumeResult();
      expect(c.read(premiumProvider).lastResult, isNull);
      await backend.close();
    });

    test('이미 보유 시 재구매 호출은 no-op', () async {
      SharedPreferences.setMockInitialValues({'app.premium.entitled': true});
      final backend = _FakeIapBackend();
      final c = _container(_serviceWith(backend));
      c.read(premiumProvider);
      await _settle();
      expect(c.read(premiumProvider).entitled, isTrue);
      await c.read(premiumProvider.notifier).purchasePremium();
      // 이미 entitled 라 buyNonConsumable 자체를 호출하지 않음.
      expect(c.read(premiumProvider).entitled, isTrue);
      await backend.close();
    });

    test('isPremiumUnlockedProvider: 실제 결제로 true 가 된다', () async {
      final backend = _FakeIapBackend();
      final c = _container(_serviceWith(backend));
      c.read(premiumProvider);
      await _settle();
      expect(c.read(isPremiumUnlockedProvider), isFalse);
      await c.read(premiumProvider.notifier).purchasePremium();
      backend.emit(PurchaseStatus.purchased);
      await _settle();
      expect(c.read(isPremiumUnlockedProvider), isTrue);
      await backend.close();
    });
  });

  // ── REWORK — entitlement source-of-truth 보안 ─────────────────────────
  group('R110 REWORK — entitlement 위변조/정합성 방어', () {
    test('캐시 true + 자동복원 빈 batch → entitled false · 캐시 false · '
        'lastResult null (무음)', () async {
      // 위변조되었거나 환불된 캐시 true 는 자동복원 빈 batch 로 정정된다.
      // 자동복원이므로 toast/lastResult 없이 무음.
      SharedPreferences.setMockInitialValues({'app.premium.entitled': true});
      final backend = _FakeIapBackend();
      final c = _container(_serviceWith(backend));
      c.read(premiumProvider); // boot → autoRestore
      await _settle();
      // 부팅 직후엔 캐시 선반영으로 잠깐 true 였을 수 있으나, autoRestore
      // 가 호출되었고 빈 batch 를 받아야 false 로 정정된다.
      backend.emitEmpty();
      await _settle();
      final s = c.read(premiumProvider);
      expect(s.entitled, isFalse, reason: '빈 batch → entitlement 강등');
      expect(s.lastResult, isNull, reason: '자동복원 nothingToRestore 는 무음');
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('app.premium.entitled'), isFalse,
          reason: '캐시도 false 로 갱신');
      await backend.close();
    });

    test('캐시 true + 스토어 unavailable → entitled true 보존 (오프라인 UX)',
        () async {
      // StoreKit 자체가 불가하면 결과가 불확실 → 캐시 보존.
      SharedPreferences.setMockInitialValues({'app.premium.entitled': true});
      final backend = _FakeIapBackend(available: false);
      final c = _container(_serviceWith(backend));
      c.read(premiumProvider);
      await _settle();
      final s = c.read(premiumProvider);
      expect(s.entitled, isTrue, reason: '스토어 불가 시 캐시 보존');
      expect(s.storeAvailable, isFalse);
      await backend.close();
    });

    test('캐시 true + 자동복원 중 error → entitled true 보존 (오프라인 UX)',
        () async {
      // 네트워크 error 는 결과 불확실 → 캐시 보존.
      SharedPreferences.setMockInitialValues({'app.premium.entitled': true});
      final backend = _FakeIapBackend();
      final c = _container(_serviceWith(backend));
      c.read(premiumProvider);
      await _settle();
      backend.emit(
        PurchaseStatus.error,
        error: IAPError(
          source: 'app_store',
          code: 'network',
          message: 'Network unavailable.',
        ),
      );
      await _settle();
      expect(c.read(premiumProvider).entitled, isTrue,
          reason: 'error 는 결과 불확실 → 캐시 보존');
      await backend.close();
    });

    test('캐시 true + 수동 restore 빈 batch → entitled false · 캐시 false · '
        'lastResult nothingToRestore', () async {
      SharedPreferences.setMockInitialValues({'app.premium.entitled': true});
      final backend = _FakeIapBackend();
      final c = _container(_serviceWith(backend));
      c.read(premiumProvider); // boot
      await _settle();
      // boot 중 autoRestore 가 한번 돌지만 빈 batch 를 안 주면 캐시 true 유지.
      expect(c.read(premiumProvider).entitled, isTrue);
      // 수동 restore — 빈 batch 도착.
      final restoreFuture =
          c.read(premiumProvider.notifier).restorePurchases();
      backend.emitEmpty();
      await restoreFuture;
      await _settle();
      final s = c.read(premiumProvider);
      expect(s.entitled, isFalse, reason: '수동 restore 빈 batch → 강등');
      expect(s.lastResult, PurchaseOutcome.nothingToRestore,
          reason: '수동은 toast 대상');
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('app.premium.entitled'), isFalse);
      await backend.close();
    });

    test('빈 restore stream 은 8초 timeout 의존 없이 즉시 nothingToRestore',
        () async {
      // emitEmpty 직후 _settle(30ms) 만에 결과가 나와야 한다.
      final backend = _FakeIapBackend();
      final c = _container(_serviceWith(backend));
      c.read(premiumProvider);
      await _settle();
      final sw = Stopwatch()..start();
      final restoreFuture =
          c.read(premiumProvider.notifier).restorePurchases();
      backend.emitEmpty();
      await restoreFuture;
      sw.stop();
      expect(sw.elapsed.inSeconds, lessThan(2),
          reason: '빈 batch 즉시 처리 — 8초 timeout 미의존');
      expect(c.read(premiumProvider).lastResult,
          PurchaseOutcome.nothingToRestore);
      await backend.close();
    });

    test('alreadyOwned error 단독 → isPremiumUnlockedProvider false 유지',
        () async {
      final backend = _FakeIapBackend();
      final c = _container(_serviceWith(backend));
      c.read(premiumProvider);
      await _settle();
      await c.read(premiumProvider.notifier).purchasePremium();
      backend.emit(
        PurchaseStatus.error,
        error: IAPError(
          source: 'app_store',
          code: 'already_owned',
          message: 'This product is already owned.',
        ),
      );
      await _settle();
      expect(c.read(premiumProvider).entitled, isFalse,
          reason: 'alreadyOwned 단독으로는 entitlement 안 열림');
      expect(c.read(isPremiumUnlockedProvider), isFalse);
      expect(c.read(premiumProvider).lastResult, PurchaseOutcome.alreadyOwned);
      await backend.close();
    });

    test('alreadyOwned → restore 유도 → restored 이벤트가 와야 entitled true',
        () async {
      final backend = _FakeIapBackend();
      final c = _container(_serviceWith(backend));
      c.read(premiumProvider);
      await _settle();
      // REWORK 3 — 부팅 auto restore session 을 빈 batch 로 먼저 종료시켜
      // _restore 를 null 로 만든다. 그래야 alreadyOwned 가 진행 중 session
      // 승격이 아니라 새 induced restore 호출을 만든다(원 의도 보존).
      backend.emitEmpty();
      await _settle();
      final restoreCallsBefore = backend.restoreCallCount;
      await c.read(premiumProvider.notifier).purchasePremium();
      backend.emit(
        PurchaseStatus.error,
        error: IAPError(
          source: 'app_store',
          code: 'already_owned',
          message: 'This product is already owned.',
        ),
      );
      await _settle();
      // alreadyOwned 가 restore 를 한번 더 호출했어야 한다.
      expect(backend.restoreCallCount, greaterThan(restoreCallsBefore),
          reason: 'alreadyOwned → restorePurchases 유도');
      expect(c.read(premiumProvider).entitled, isFalse);
      // 이제 StoreKit 이 restored 이벤트를 보내면 entitlement 승격.
      backend.emit(PurchaseStatus.restored);
      await _settle();
      expect(c.read(premiumProvider).entitled, isTrue,
          reason: 'restored 이벤트로만 entitlement 승격');
      expect(c.read(isPremiumUnlockedProvider), isTrue);
      await backend.close();
    });

    test('관계없는 상품 restored → completePurchase 호출하되 entitled false',
        () async {
      final backend = _FakeIapBackend();
      final c = _container(_serviceWith(backend));
      c.read(premiumProvider);
      await _settle();
      final completeBefore = backend.completeCallCount;
      backend.emit(PurchaseStatus.restored,
          productId: 'com.ganziman.pillarseer.some_other_thing');
      await _settle();
      expect(backend.completeCallCount, greaterThan(completeBefore),
          reason: '관계없는 상품도 completePurchase 는 호출(stream 정리)');
      expect(c.read(premiumProvider).entitled, isFalse,
          reason: '프리미엄팩이 아니면 entitlement 안 열림');
      await backend.close();
    });

    test('관계없는 상품 purchased → completePurchase 호출하되 entitled false',
        () async {
      final backend = _FakeIapBackend();
      final c = _container(_serviceWith(backend));
      c.read(premiumProvider);
      await _settle();
      final completeBefore = backend.completeCallCount;
      backend.emit(PurchaseStatus.purchased,
          productId: 'com.ganziman.pillarseer.some_other_thing');
      await _settle();
      expect(backend.completeCallCount, greaterThan(completeBefore));
      expect(c.read(premiumProvider).entitled, isFalse);
      await backend.close();
    });
  });

  // ── REWORK 2 — restore/purchase 동시 이벤트 race 제거 ──────────────────
  group('R110 REWORK2 — restore/purchase race 방어', () {
    test('autoRestore in-flight 중 purchasePremium 성공 후 늦은 empty batch 가 '
        '와도 entitled true · 캐시 true 유지', () async {
      // race: 부팅 자동복원이 아직 진행 중인 동안 사용자가 구매를 완료.
      // 그 직후 같은 boot autoRestore 의 stale empty batch 가 늦게 도착해도
      // 정상 구매자를 강등하면 안 된다.
      final backend = _FakeIapBackend();
      final c = _container(_serviceWith(backend));
      c.read(premiumProvider); // boot → autoRestore 진행 중
      await _settle();
      // autoRestore session 이 아직 살아있는 상태(빈 batch 미도착).
      await c.read(premiumProvider.notifier).purchasePremium();
      backend.emit(PurchaseStatus.purchased);
      await _settle();
      expect(c.read(premiumProvider).entitled, isTrue,
          reason: '구매 성공 → entitlement 승격');
      // 이제 같은 boot autoRestore 의 stale empty batch 가 늦게 도착.
      backend.emitEmpty();
      await _settle();
      final s = c.read(premiumProvider);
      expect(s.entitled, isTrue,
          reason: 'session 도중 purchased 후 stale empty batch 는 강등 금지');
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('app.premium.entitled'), isTrue,
          reason: '캐시도 true 유지');
      await backend.close();
    });

    test('autoRestore waiter timeout cleanup 이 이후 시작된 manual restore '
        'session 을 null 로 지우지 않음', () async {
      // race: autoRestore 의 timeout/cleanup 이 그 사이 시작된 manual
      // restore 의 session 토큰을 닫아 restore context 를 잃게 만들면 안 된다.
      // (전역 _restoreWaiter 시절 버그.)
      final backend = _FakeIapBackend();
      final c = _container(_serviceWith(backend));
      c.read(premiumProvider); // boot → autoRestore session 생성
      await _settle();
      // autoRestore session 이 살아있는 상태에서 사용자가 수동 복원을 누름.
      // restorePurchases 는 manual session 으로 교체한다.
      final restoreFuture =
          c.read(premiumProvider.notifier).restorePurchases();
      // manual restore 에 대해 StoreKit 이 restored 를 흘려보냄.
      backend.emit(PurchaseStatus.restored);
      await restoreFuture;
      // manual restore 가 정상적으로 완료되어 entitlement 가 승격되어야 한다 —
      // autoRestore cleanup 이 manual session 을 닫아버리지 않았다는 증거.
      expect(c.read(premiumProvider).entitled, isTrue,
          reason: 'manual restore session 이 autoRestore cleanup 에 안 지워짐');
      expect(c.read(premiumProvider).lastResult, PurchaseOutcome.restored);
      await backend.close();
    });

    test('state.busy=true 일 때 purchasePremium 중복 호출은 buyNonConsumable '
        '1회만', () async {
      // 재진입 가드: busy 인 동안 들어온 중복 구매 호출은 무시.
      final backend = _FakeIapBackend();
      final c = _container(_serviceWith(backend));
      c.read(premiumProvider);
      await _settle();
      final notifier = c.read(premiumProvider.notifier);
      // 두 호출을 await 사이 없이 발사 — 두 번째는 첫 번째가 동기적으로 세운
      // busy=true 를 보고 즉시 return 해야 한다.
      final f1 = notifier.purchasePremium();
      final f2 = notifier.purchasePremium();
      await Future.wait([f1, f2]);
      expect(backend.buyCallCount, 1,
          reason: 'busy 재진입 가드 → buyNonConsumable 정확히 1회');
      await backend.close();
    });

    test('state.busy=true 일 때 restorePurchases 중복 호출은 restorePurchases '
        '1회만', () async {
      // 재진입 가드: busy 인 동안 들어온 중복 복원 호출은 무시.
      final backend = _FakeIapBackend();
      final c = _container(_serviceWith(backend));
      c.read(premiumProvider);
      await _settle();
      // REWORK 3 — 부팅 auto restore session 을 빈 batch 로 먼저 종료시킨다.
      // 그래야 첫 수동 restore 가 진행 중 session 승격이 아니라 새 호출을
      // 만들어, busy 가드가 "정확히 1회" 를 보장하는지 검증할 수 있다.
      backend.emitEmpty();
      await _settle();
      final restoreBefore = backend.restoreCallCount;
      final notifier = c.read(premiumProvider.notifier);
      final f1 = notifier.restorePurchases();
      final f2 = notifier.restorePurchases();
      // 둘 중 진짜로 진행된 1건만 restored 로 마무리.
      backend.emit(PurchaseStatus.restored);
      await Future.wait([f1, f2]);
      expect(backend.restoreCallCount - restoreBefore, 1,
          reason: 'busy 재진입 가드 → restorePurchases 정확히 1회');
      await backend.close();
    });

    test('alreadyOwned 단독은 여전히 entitled false, alreadyOwned 후 restored '
        '만 true', () async {
      // REWORK 보안 규칙 회귀 — alreadyOwned 는 휴리스틱, restored 만 승격.
      final backend = _FakeIapBackend();
      final c = _container(_serviceWith(backend));
      c.read(premiumProvider);
      await _settle();
      await c.read(premiumProvider.notifier).purchasePremium();
      backend.emit(
        PurchaseStatus.error,
        error: IAPError(
          source: 'app_store',
          code: 'already_owned',
          message: 'This product is already owned.',
        ),
      );
      await _settle();
      expect(c.read(premiumProvider).entitled, isFalse,
          reason: 'alreadyOwned 단독으로는 entitlement 안 열림');
      // alreadyOwned 가 유도한 restore 에 restored 가 도착해야 승격.
      backend.emit(PurchaseStatus.restored);
      await _settle();
      expect(c.read(premiumProvider).entitled, isTrue,
          reason: 'restored 이벤트로만 entitlement 승격');
      await backend.close();
    });

    test('cached true + autoRestore empty 만 온 경우는 여전히 false · 캐시 '
        'false · lastResult null', () async {
      // REWORK 보안 규칙 회귀 — 자동복원 빈 batch 는 무음 강등.
      SharedPreferences.setMockInitialValues({'app.premium.entitled': true});
      final backend = _FakeIapBackend();
      final c = _container(_serviceWith(backend));
      c.read(premiumProvider); // boot → autoRestore
      await _settle();
      backend.emitEmpty();
      await _settle();
      final s = c.read(premiumProvider);
      expect(s.entitled, isFalse, reason: '자동복원 빈 batch → 강등');
      expect(s.lastResult, isNull, reason: '자동복원은 무음');
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('app.premium.entitled'), isFalse);
      await backend.close();
    });

    test('cached true + autoRestore unavailable → 여전히 entitled true 보존',
        () async {
      // REWORK 보안 규칙 회귀 — 스토어 불가는 결과 불확실 → 캐시 보존.
      SharedPreferences.setMockInitialValues({'app.premium.entitled': true});
      final backend = _FakeIapBackend(available: false);
      final c = _container(_serviceWith(backend));
      c.read(premiumProvider);
      await _settle();
      expect(c.read(premiumProvider).entitled, isTrue,
          reason: '스토어 불가 → 캐시 보존');
      await backend.close();
    });

    test('cached true + autoRestore 중 error → 여전히 entitled true 보존',
        () async {
      // REWORK 보안 규칙 회귀 — error 는 결과 불확실 → 캐시 보존.
      SharedPreferences.setMockInitialValues({'app.premium.entitled': true});
      final backend = _FakeIapBackend();
      final c = _container(_serviceWith(backend));
      c.read(premiumProvider);
      await _settle();
      backend.emit(
        PurchaseStatus.error,
        error: IAPError(
          source: 'app_store',
          code: 'network',
          message: 'Network unavailable.',
        ),
      );
      await _settle();
      expect(c.read(premiumProvider).entitled, isTrue,
          reason: 'error 는 결과 불확실 → 캐시 보존');
      await backend.close();
    });

    test('manual restore empty 는 여전히 false · 캐시 false · '
        'lastResult nothingToRestore', () async {
      // REWORK 보안 규칙 회귀 — 수동 복원 빈 batch 는 toast 대상 강등.
      SharedPreferences.setMockInitialValues({'app.premium.entitled': true});
      final backend = _FakeIapBackend();
      final c = _container(_serviceWith(backend));
      c.read(premiumProvider); // boot
      await _settle();
      expect(c.read(premiumProvider).entitled, isTrue);
      final restoreFuture =
          c.read(premiumProvider.notifier).restorePurchases();
      backend.emitEmpty();
      await restoreFuture;
      await _settle();
      final s = c.read(premiumProvider);
      expect(s.entitled, isFalse, reason: '수동 복원 빈 batch → 강등');
      expect(s.lastResult, PurchaseOutcome.nothingToRestore,
          reason: '수동은 toast 대상');
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('app.premium.entitled'), isFalse);
      await backend.close();
    });
  });

  // ── REWORK 3 — restore 호출 overlap 차단(stream misrouting 제거) ─────────
  // codex 9.2 → : StoreKit purchaseStream 이벤트에 restore 호출별 tag 가
  // 없으므로, 동시에 restorePurchases() 를 2개 띄우면 늦은 auto empty batch
  // 가 manual/induced session 의 결과처럼 misroute 될 수 있다. 해결책 =
  // auto session 진행 중이면 새 호출 없이 그 session 을 manual-visible 로
  // 승격. 아래 테스트는 restore 호출이 항상 1개로 유지됨을 검증한다.
  group('R110 REWORK3 — restore 호출 overlap 차단', () {
    test('autoRestore in-flight 중 manual restore 를 눌러도 backend restore '
        'call 이 추가로 안 늘어남(1회 유지)', () async {
      final backend = _FakeIapBackend();
      final c = _container(_serviceWith(backend));
      c.read(premiumProvider); // boot → autoRestore session 진행 중
      await _settle();
      // 부팅 autoRestore 가 restore 호출 1회 — session 은 아직 in-flight.
      final restoreAfterBoot = backend.restoreCallCount;
      expect(restoreAfterBoot, greaterThanOrEqualTo(1));
      // 수동 복원 — 진행 중 auto session 을 승격, 새 호출 없음.
      final restoreFuture =
          c.read(premiumProvider.notifier).restorePurchases();
      await _settle();
      expect(backend.restoreCallCount, restoreAfterBoot,
          reason: 'auto in-flight 중 수동 복원은 새 restore 호출 X — 승격');
      // 승격된 session 으로 결과가 도착하면 정상 마무리.
      backend.emit(PurchaseStatus.restored);
      await restoreFuture;
      expect(backend.restoreCallCount, restoreAfterBoot,
          reason: 'restore 호출은 끝까지 1회 유지');
      await backend.close();
    });

    test('autoRestore in-flight 중 manual 승격 상태에서 empty batch → '
        'manual nothingToRestore(busy false)', () async {
      final backend = _FakeIapBackend();
      final c = _container(_serviceWith(backend));
      c.read(premiumProvider); // boot → autoRestore in-flight
      await _settle();
      final restoreAfterBoot = backend.restoreCallCount;
      final restoreFuture =
          c.read(premiumProvider.notifier).restorePurchases();
      await _settle();
      // 승격 직후 busy 는 true.
      expect(c.read(premiumProvider).busy, isTrue);
      // 진행 중 session(원래 auto)이 빈 batch 를 받는다 — 승격됐으므로
      // 무음이 아니라 수동 nothingToRestore 로 노출돼야 한다.
      backend.emitEmpty();
      await restoreFuture;
      final s = c.read(premiumProvider);
      expect(s.busy, isFalse, reason: '승격 session 종료 → busy 해제');
      expect(s.lastResult, PurchaseOutcome.nothingToRestore,
          reason: '승격됐으므로 무음 아님 — toast 노출');
      expect(backend.restoreCallCount, restoreAfterBoot,
          reason: 'restore 호출 추가 없음');
      await backend.close();
    });

    test('autoRestore in-flight 중 manual 승격 상태에서 restored → '
        'entitled true · lastResult restored', () async {
      final backend = _FakeIapBackend();
      final c = _container(_serviceWith(backend));
      c.read(premiumProvider); // boot → autoRestore in-flight
      await _settle();
      final restoreFuture =
          c.read(premiumProvider.notifier).restorePurchases();
      await _settle();
      backend.emit(PurchaseStatus.restored);
      await restoreFuture;
      final s = c.read(premiumProvider);
      expect(s.entitled, isTrue, reason: '승격 session 으로 restored 도착');
      expect(s.lastResult, PurchaseOutcome.restored);
      expect(s.busy, isFalse);
      await backend.close();
    });

    test('autoRestore in-flight 중 alreadyOwned 가 와도 restorePurchases '
        '추가 호출 storm 없음', () async {
      final backend = _FakeIapBackend();
      final c = _container(_serviceWith(backend));
      c.read(premiumProvider); // boot → autoRestore in-flight
      await _settle();
      final restoreAfterBoot = backend.restoreCallCount;
      await c.read(premiumProvider.notifier).purchasePremium();
      // alreadyOwned 가 연달아 와도, 진행 중 auto session 을 승격할 뿐
      // 새 restore 호출을 만들지 않는다.
      backend.emit(
        PurchaseStatus.error,
        error: IAPError(
          source: 'app_store',
          code: 'already_owned',
          message: 'This product is already owned.',
        ),
      );
      await _settle();
      backend.emit(
        PurchaseStatus.error,
        error: IAPError(
          source: 'app_store',
          code: 'already_owned',
          message: 'This product is already owned.',
        ),
      );
      await _settle();
      expect(backend.restoreCallCount, restoreAfterBoot,
          reason: 'auto in-flight 중 alreadyOwned → 새 restore 호출 X');
      await backend.close();
    });

    test('autoRestore in-flight 중 alreadyOwned 후 늦은 empty → '
        'buyNonConsumable 재호출/restore storm 없음 · busy false · '
        'entitled false 유지 · 이후 재구매 가능', () async {
      final backend = _FakeIapBackend();
      final c = _container(_serviceWith(backend));
      c.read(premiumProvider); // boot → autoRestore in-flight
      await _settle();
      final restoreAfterBoot = backend.restoreCallCount;
      final notifier = c.read(premiumProvider.notifier);
      await notifier.purchasePremium();
      final buyAfterFirst = backend.buyCallCount;
      backend.emit(
        PurchaseStatus.error,
        error: IAPError(
          source: 'app_store',
          code: 'already_owned',
          message: 'This product is already owned.',
        ),
      );
      await _settle();
      // 승격된 induced session 이 늦은 empty batch 를 받는다.
      backend.emitEmpty();
      await _settle();
      final s = c.read(premiumProvider);
      expect(s.busy, isFalse, reason: 'induced session 종료 → busy false');
      expect(s.entitled, isFalse, reason: 'empty → entitlement 안 열림');
      expect(backend.restoreCallCount, restoreAfterBoot,
          reason: 'restore storm 없음');
      expect(backend.buyCallCount, buyAfterFirst,
          reason: '늦은 empty 가 buyNonConsumable 재호출을 유발하지 않음');
      // session 종료 후 재구매 가능해야 한다.
      await notifier.purchasePremium();
      expect(backend.buyCallCount, buyAfterFirst + 1,
          reason: 'session 종료 후 재구매 허용');
      await backend.close();
    });

    test('alreadyOwned-induced restore pending 중 purchasePremium 재호출 → '
        'buyNonConsumable 추가 호출 0', () async {
      final backend = _FakeIapBackend();
      final c = _container(_serviceWith(backend));
      c.read(premiumProvider);
      await _settle();
      // 부팅 auto session 을 먼저 종료 — 그래야 alreadyOwned 가 새 induced
      // session 을 만들고 inducedByAlreadyOwned 가드를 검증할 수 있다.
      backend.emitEmpty();
      await _settle();
      final notifier = c.read(premiumProvider.notifier);
      await notifier.purchasePremium();
      final buyAfterFirst = backend.buyCallCount;
      backend.emit(
        PurchaseStatus.error,
        error: IAPError(
          source: 'app_store',
          code: 'already_owned',
          message: 'This product is already owned.',
        ),
      );
      await _settle();
      // induced restore 가 pending 인 동안 purchasePremium 재호출 — 차단.
      await notifier.purchasePremium();
      await notifier.purchasePremium();
      expect(backend.buyCallCount, buyAfterFirst,
          reason: 'induced restore pending 중 buyNonConsumable 추가 호출 0');
      await backend.close();
    });

    test('purchased 성공 후 늦은 empty → entitled/cache true 유지', () async {
      final backend = _FakeIapBackend();
      final c = _container(_serviceWith(backend));
      c.read(premiumProvider); // boot → autoRestore in-flight
      await _settle();
      await c.read(premiumProvider.notifier).purchasePremium();
      backend.emit(PurchaseStatus.purchased);
      await _settle();
      expect(c.read(premiumProvider).entitled, isTrue);
      // 같은 boot auto session 의 stale empty batch 가 늦게 도착.
      backend.emitEmpty();
      await _settle();
      expect(c.read(premiumProvider).entitled, isTrue,
          reason: 'purchased 후 늦은 empty 는 강등 금지');
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('app.premium.entitled'), isTrue);
      await backend.close();
    });

    test('manual restore timeout 후 busy false', () async {
      // stream 응답이 끝내 안 와도(빈 batch 조차) timeout 으로 마무리되며
      // busy 가 false 가 되어 UI 가 stuck 되지 않는다.
      final backend = _FakeIapBackend();
      final c = _container(_serviceWith(backend));
      c.read(premiumProvider);
      await _settle();
      // 부팅 auto session 종료 — 새 manual session 이 timeout 을 타도록.
      backend.emitEmpty();
      await _settle();
      await c.read(premiumProvider.notifier).restorePurchases();
      // restorePurchases 는 응답이 없으면 _kRestoreTimeout 후 반환된다.
      final s = c.read(premiumProvider);
      expect(s.busy, isFalse, reason: 'manual restore timeout → busy false');
      expect(s.lastResult, PurchaseOutcome.nothingToRestore);
      await backend.close();
    });

    test('restored 후 후속 empty → 같은 session entitlementGranted true 면 '
        '강등 금지', () async {
      final backend = _FakeIapBackend();
      final c = _container(_serviceWith(backend));
      c.read(premiumProvider); // boot → autoRestore in-flight
      await _settle();
      // 진행 중 auto session 으로 restored 도착 → entitlement 승격.
      backend.emit(PurchaseStatus.restored);
      await _settle();
      expect(c.read(premiumProvider).entitled, isTrue);
      // 같은 session 의 후속 empty batch 가 늦게 도착 — 강등하면 안 된다.
      backend.emitEmpty();
      await _settle();
      expect(c.read(premiumProvider).entitled, isTrue,
          reason: 'session entitlementGranted true → 후속 empty 강등 금지');
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('app.premium.entitled'), isTrue);
      await backend.close();
    });
  });

  // ── REWORK 4 — autoRestore API throw 가 cache false 강등 막기 ────────────
  // codex 9.1 → : autoRestore() 가 restorePurchases() throw 를 무음 처리하면
  // session 은 stream 응답 없이 timeout 되어 nothingToRestore 로 강등됐다 —
  // cached true 기존 구매자가 StoreKit 일시 오류만으로 프리미엄을 잃었다.
  // 수정: autoRestore() 가 Future<bool> 로 restore 제출 성공 여부를 알리고,
  // false 면 provider 가 entitlement/캐시/lastResult 를 보존한 채 session 만
  // 정리한다("복원 내역 없음"이 아니라 "결과 불확실").
  group('R110 REWORK4 — autoRestore API throw → cache 보존', () {
    test('캐시 true + autoRestore API throw → entitled true · 캐시 true · '
        'busy false · lastResult null', () async {
      // restore 호출 자체가 throw — 결과 불확실. cached true 기존 구매자는
      // 프리미엄을 유지해야 한다(강등 금지).
      SharedPreferences.setMockInitialValues({'app.premium.entitled': true});
      final backend = _FakeIapBackend(restoreThrows: true);
      final c = _container(_serviceWith(backend));
      c.read(premiumProvider); // boot → autoRestore (restore throw)
      await _settle();
      // autoRestore() 가 restorePurchases() 를 호출은 했으나 throw 했다.
      expect(backend.restoreCallCount, greaterThanOrEqualTo(1));
      final s = c.read(premiumProvider);
      expect(s.entitled, isTrue,
          reason: 'autoRestore API throw 는 결과 불확실 → 캐시 보존');
      expect(s.busy, isFalse, reason: 'busy stuck 없음');
      expect(s.lastResult, isNull,
          reason: '자동 복원 API 실패는 무음 — error toast 없음');
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('app.premium.entitled'), isTrue,
          reason: '캐시도 true 유지 — false 강등 금지');
      await backend.close();
    });

    test('autoRestore API throw 후에도 이후 수동 restore 가 정상 동작', () async {
      // autoRestore 실패가 _restore 토큰을 막아두면 안 된다 — null 로 비워져
      // 사용자가 수동 버튼으로 재시도할 수 있어야 한다.
      SharedPreferences.setMockInitialValues({'app.premium.entitled': true});
      final backend = _FakeIapBackend(restoreThrows: true);
      final c = _container(_serviceWith(backend));
      c.read(premiumProvider); // boot → autoRestore throw
      await _settle();
      // 이제 throw 를 멈추고 수동 복원 — 정상적으로 새 호출이 떠야 한다.
      backend.restoreThrows = false;
      final restoreBefore = backend.restoreCallCount;
      final restoreFuture =
          c.read(premiumProvider.notifier).restorePurchases();
      backend.emit(PurchaseStatus.restored);
      await restoreFuture;
      expect(backend.restoreCallCount - restoreBefore, 1,
          reason: 'autoRestore throw 후에도 수동 restore 호출 1회 가능');
      expect(c.read(premiumProvider).entitled, isTrue);
      expect(c.read(premiumProvider).lastResult, PurchaseOutcome.restored);
      await backend.close();
    });

    test('manual restore API throw → entitlement/캐시 보존 · busy false · '
        'lastResult error', () async {
      // 수동 복원 호출 자체가 throw — error 로 마무리하되, 결과 불확실이므로
      // cached true 기존 구매자를 강등하지 않는다.
      SharedPreferences.setMockInitialValues({'app.premium.entitled': true});
      final backend = _FakeIapBackend();
      final c = _container(_serviceWith(backend));
      c.read(premiumProvider); // boot
      await _settle();
      // 부팅 auto session 을 빈 batch 로 종료 — 새 manual session 이 직접
      // restore 호출을 만들고 그게 throw 하도록.
      backend.emitEmpty();
      await _settle();
      // 부팅 auto 빈 batch 로 강등됐을 수 있으니 캐시/entitlement 를 복구해
      // manual throw 가 *보존* 하는지를 깨끗하게 검증한다.
      backend.emit(PurchaseStatus.restored);
      await _settle();
      expect(c.read(premiumProvider).entitled, isTrue);
      // 이제 restore 호출이 throw 하도록 — 수동 복원 시도.
      backend.restoreThrows = true;
      await c.read(premiumProvider.notifier).restorePurchases();
      await _settle();
      final s = c.read(premiumProvider);
      expect(s.entitled, isTrue,
          reason: 'manual restore API throw 는 결과 불확실 → entitlement 보존');
      expect(s.busy, isFalse, reason: 'busy stuck 없음');
      expect(s.lastResult, PurchaseOutcome.error,
          reason: '수동 복원 API throw 는 error 노출');
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('app.premium.entitled'), isTrue,
          reason: '캐시 보존 — 강등 금지');
      await backend.close();
    });

    test('alreadyOwned-induced restore API throw → busy false · '
        'buyNonConsumable storm 없음 · entitlement/캐시 강등 없음', () async {
      // alreadyOwned 가 유도한 induced restore 호출이 throw 해도, busy 가
      // stuck 되거나 buyNonConsumable storm 이 나거나 entitlement/캐시가
      // 강등되면 안 된다.
      SharedPreferences.setMockInitialValues({'app.premium.entitled': true});
      final backend = _FakeIapBackend();
      final c = _container(_serviceWith(backend));
      c.read(premiumProvider);
      await _settle();
      // 부팅 auto session 을 빈 batch 로 종료 — alreadyOwned 가 새 induced
      // session + 직접 restore 호출을 만들도록(_restore == null).
      backend.emitEmpty();
      await _settle();
      // 빈 batch 강등 후 entitlement/캐시 복구 — induced throw 가 *보존*
      // 하는지를 깨끗하게 검증.
      backend.emit(PurchaseStatus.restored);
      await _settle();
      expect(c.read(premiumProvider).entitled, isTrue);
      final notifier = c.read(premiumProvider.notifier);
      await notifier.purchasePremium();
      final buyAfterFirst = backend.buyCallCount;
      // 이제 induced restore 호출이 throw 하도록.
      backend.restoreThrows = true;
      backend.emit(
        PurchaseStatus.error,
        error: IAPError(
          source: 'app_store',
          code: 'already_owned',
          message: 'This product is already owned.',
        ),
      );
      await _settle();
      final s = c.read(premiumProvider);
      expect(s.busy, isFalse, reason: 'induced restore throw → busy stuck 없음');
      expect(s.entitled, isTrue,
          reason: 'induced restore API throw 는 entitlement 강등 없음');
      expect(backend.buyCallCount, buyAfterFirst,
          reason: 'induced restore throw 는 buyNonConsumable storm 유발 X');
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('app.premium.entitled'), isTrue,
          reason: '캐시 보존 — 강등 금지');
      // induced session 종료(_restore == null) 후 추가 alreadyOwned 가 와도
      // restore 호출이 다시 1회만 떠야 한다 — restore storm 없음.
      backend.restoreThrows = false;
      final restoreBeforeSecond = backend.restoreCallCount;
      backend.emit(
        PurchaseStatus.error,
        error: IAPError(
          source: 'app_store',
          code: 'already_owned',
          message: 'This product is already owned.',
        ),
      );
      await _settle();
      expect(backend.restoreCallCount - restoreBeforeSecond, 1,
          reason: 'induced session 종료 후 후속 alreadyOwned → restore 1회');
      await backend.close();
    });
  });
}
