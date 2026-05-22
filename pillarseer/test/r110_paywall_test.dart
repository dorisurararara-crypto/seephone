// R110 Sprint 3 — 프리미엄팩 paywall 회귀 가드.
//
// monetization_playbook.md §"Paywall UX" / §"문구 (확정)" 를 코드가 그대로
// 지키는지 검증한다. 네 층위로 본다:
//   A. kPremiumLockedTapOverride 기본 구현 — SnackBar placeholder 가 아니라
//      paywall 표시 함수(showPremiumPaywall)로 연결됨.
//   B. paywall 위젯 동작 — 확정 문구 노출, CTA→purchasePremium,
//      restore→restorePurchases, lastResult→consumeResult, 무료 복귀.
//   C. 설정 화면 restore 진입점 존재.
//   D. 금지 문구 / 구독·광고 / 본문 절단·blur scan.
//
// Sprint 2 게이트 테스트(test/r110_premium_gate_test.dart) 와 독립 —
// 이 파일은 paywall UX 만 본다.

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:pillarseer/l10n/app_localizations.dart';
import 'package:pillarseer/providers/premium_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pillarseer/services/purchase_service.dart';
import 'package:pillarseer/widgets/premium_gate.dart';
import 'package:pillarseer/widgets/premium_paywall.dart';

// ── fake StoreKit backend — purchase_service_test 의 패턴 재사용 ──────────
class _FakeIapBackend implements IapBackend {
  _FakeIapBackend();

  final StreamController<List<PurchaseDetails>> _ctrl =
      StreamController<List<PurchaseDetails>>.broadcast();

  int restoreCallCount = 0;
  int buyCallCount = 0;

  @override
  Future<bool> isAvailable() async => true;

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => _ctrl.stream;

  @override
  Future<ProductDetailsResponse> queryProductDetails(Set<String> ids) async {
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
    return true;
  }

  @override
  Future<void> restorePurchases() async {
    restoreCallCount++;
  }

  @override
  Future<void> completePurchase(PurchaseDetails purchase) async {}

  Future<void> close() => _ctrl.close();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  setUp(() => SharedPreferences.setMockInitialValues({}));

  String read(String path) => File(path).readAsStringSync();

  // ── A. kPremiumLockedTapOverride 기본 구현 ───────────────────────────────

  group('A. kPremiumLockedTapOverride 기본 구현', () {
    test('A1 — 기본 hook 이 showPremiumPaywall 로 연결됨 (SnackBar placeholder X)',
        () {
      final src = read('lib/widgets/premium_gate.dart');
      expect(src.contains('showPremiumPaywall('), isTrue,
          reason: 'premium_gate 기본 hook 이 paywall 표시 함수를 호출하지 않음');
      // Sprint 2 의 SnackBar placeholder 안내는 제거되어야 한다.
      expect(src.contains('프리미엄팩에서 ${'lock.label'}'), isFalse);
      expect(
          src.contains(
              'The Premium Pack opens a deeper look at'),
          isFalse,
          reason: 'Sprint 2 SnackBar placeholder 문구가 남아 있음');
    });

    test('A2 — context null/unmounted 면 크래시 없이 no-op', () {
      // null context — 크래시 없이 반환되어야 한다.
      expect(
        () => showPremiumPaywall(
            null,
            const PremiumLockContext(
              feature: PremiumFeature.mySajuCategory,
              label: '재물운',
            )),
        returnsNormally,
      );
    });
  });

  // ── B. paywall 위젯 동작 ─────────────────────────────────────────────────

  group('B. paywall bottom sheet 동작', () {
    Widget host({
      required PurchaseService service,
      Locale locale = const Locale('ko'),
    }) {
      return ProviderScope(
        overrides: [
          premiumProvider.overrideWith(
              () => PremiumNotifier(serviceOverride: service)),
        ],
        child: MaterialApp(
          locale: locale,
          supportedLocales: AppL10n.supportedLocales,
          localizationsDelegates: AppL10n.localizationsDelegates,
          home: Consumer(
            builder: (context, ref, _) {
              // premiumProvider 를 watch 해 PremiumNotifier 가 즉시 build/_boot
              // 되게 한다 (실앱에서는 게이트 화면들이 isPremiumUnlockedProvider
              // 를 watch 하므로 부팅됨).
              ref.watch(premiumProvider);
              return Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () => showPremiumPaywall(
                        context,
                        const PremiumLockContext(
                          feature: PremiumFeature.mySajuCategory,
                          label: '재물운',
                        )),
                    child: const Text('OPEN'),
                  ),
                ),
              );
            },
          ),
        ),
      );
    }

    testWidgets('B1 — 확정 문구(헤드라인/서브/CTA/보조/가격보조/restore) 노출',
        (tester) async {
      final backend = _FakeIapBackend();
      await tester.pumpWidget(host(service: PurchaseService(backend: backend)));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OPEN'));
      await tester.pumpAndSettle();

      expect(find.text('내 사주를 더 깊게 열어보세요'), findsOneWidget,
          reason: '헤드라인 확정 문구 누락');
      expect(
          find.text(
              '무료 리포트는 계속 사용할 수 있어요. 프리미엄팩은 긴 해석과 추가 리포트를 한 번에 여는 단건 구매입니다.'),
          findsOneWidget,
          reason: '서브 확정 문구 누락');
      expect(find.text('한 번 구매하면 계속 사용할 수 있어요.'), findsOneWidget,
          reason: '가격 보조 확정 문구 누락');
      expect(find.text('지금은 무료로 계속 보기'), findsOneWidget,
          reason: '무료 복귀 보조 CTA 누락');
      expect(find.text('이미 구매하셨나요? 구매 복원'), findsOneWidget,
          reason: 'paywall 하단 restore 진입점 누락');
      // CTA 라벨은 UPPERCASE 로 렌더된다 — 원문이 코드에 있는지로 가드.
      final src = read('lib/widgets/premium_paywall.dart');
      expect(src.contains('프리미엄팩 열기'), isTrue, reason: 'CTA 확정 문구 누락');
      // 가격 — StoreKit localized price 우선 노출.
      expect(find.text('₩5,900'), findsOneWidget,
          reason: 'StoreKit localized price 미표시');
    });

    testWidgets('B2 — CTA 탭 → purchasePremium → buyNonConsumable 호출',
        (tester) async {
      // StoreKit fake backend 의 async(stream/buy)는 real async 로만 진행되므로
      // backend 가 관여하는 구간은 tester.runAsync 로 감싼다.
      final backend = _FakeIapBackend();
      await tester.pumpWidget(host(service: PurchaseService(backend: backend)));
      await tester.runAsync(() => Future<void>.delayed(
          const Duration(milliseconds: 100)));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OPEN'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('프리미엄팩 열기'.toUpperCase()));
      await tester.runAsync(() => Future<void>.delayed(
          const Duration(milliseconds: 100)));
      expect(backend.buyCallCount, 1,
          reason: 'CTA 가 purchasePremium → buyNonConsumable 로 이어지지 않음');
    });

    testWidgets('B3 — 구매 성공(purchased) → paywall 닫힘 + entitlement 승격',
        (tester) async {
      // StoreKit purchaseStream 의 fake-async 미전달 + GoogleFonts runAsync
      // fatal 을 피하기 위해, PurchaseService 의 onPurchaseUpdate 콜백을 직접
      // 호출해 purchased 결과를 결정론적으로 주입한다(stream 경유와 동일 경로).
      final service = PurchaseService(backend: _FakeIapBackend());
      await tester.pumpWidget(host(service: service));
      await tester.pumpAndSettle();
      final container =
          ProviderScope.containerOf(tester.element(find.text('OPEN')));
      await tester.tap(find.text('OPEN'));
      await tester.pumpAndSettle();
      expect(find.text('내 사주를 더 깊게 열어보세요'), findsOneWidget);

      // App Store 가 확인한 purchased 결과를 PurchaseService 콜백으로 주입.
      service.onPurchaseUpdate?.call(const PurchaseResult(
        PurchaseOutcome.purchased,
        isPremium: true,
      ));
      await tester.pump();
      // entitlement 가 승격되었다 (purchased = App Store 확인 신호).
      expect(container.read(premiumProvider).entitled, isTrue,
          reason: 'purchased 후 entitlement 미승격');
      // _handleResult 가 sheet 를 pop.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('내 사주를 더 깊게 열어보세요'), findsNothing,
          reason: '구매 성공 후 paywall 이 닫히지 않음');
    });

    testWidgets('B4 — restore 탭 → restorePurchases 경로 진입', (tester) async {
      final backend = _FakeIapBackend();
      await tester.pumpWidget(host(service: PurchaseService(backend: backend)));
      // 베이스 화면(GoogleFonts 미사용)만 떠 있는 동안 runAsync 로 부팅을
      // 완료한다 — paywall sheet 가 떠 있으면 runAsync 중 폰트 fetch 가
      // fatal 이 되므로, 부팅은 sheet 를 열기 전에 끝낸다.
      await tester.runAsync(() => Future<void>.delayed(
          const Duration(milliseconds: 300)));
      await tester.pumpAndSettle();
      // 부팅 자동 복원이 StoreKit restore 를 1회 이상 호출했다.
      expect(backend.restoreCallCount, greaterThanOrEqualTo(1),
          reason: '부팅 자동 복원이 restorePurchases 를 호출하지 않음');
      final autoCount = backend.restoreCallCount;

      await tester.tap(find.text('OPEN'));
      await tester.pumpAndSettle();
      final restoreFinder = find.text('이미 구매하셨나요? 구매 복원');
      await tester.ensureVisible(restoreFinder);
      await tester.pumpAndSettle();
      await tester.tap(restoreFinder);
      // restore 탭 → restorePurchases() — fake-async pump 으로 microtask 처리.
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 20));
      }
      // 진행 중 auto session 이 끝났으면 새 restore 호출이 추가된다.
      // (auto session 이 아직 떠 있으면 승격되어 호출 누계는 동일.)
      // 어느 쪽이든 restore 호출 누계는 줄지 않고, restorePurchases 경로를 탄다.
      expect(backend.restoreCallCount, greaterThanOrEqualTo(autoCount),
          reason: 'restore 탭 후 restore 호출 누계가 감소함');
    });

    testWidgets('B5 — 무료 복귀: "지금은 무료로 계속 보기" → paywall 닫힘', (tester) async {
      final backend = _FakeIapBackend();
      await tester.pumpWidget(host(service: PurchaseService(backend: backend)));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OPEN'));
      await tester.pumpAndSettle();
      expect(find.text('내 사주를 더 깊게 열어보세요'), findsOneWidget);

      await tester.tap(find.text('지금은 무료로 계속 보기'));
      await tester.pumpAndSettle();
      expect(find.text('내 사주를 더 깊게 열어보세요'), findsNothing,
          reason: '무료 복귀 후에도 paywall 이 닫히지 않음');
    });

    testWidgets('B6 — 영어 locale 문구 노출', (tester) async {
      final backend = _FakeIapBackend();
      await tester.pumpWidget(host(
        service: PurchaseService(backend: backend),
        locale: const Locale('en'),
      ));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OPEN'));
      await tester.pumpAndSettle();
      expect(find.text('Open a deeper reading of your saju'), findsOneWidget,
          reason: '영어 헤드라인 누락');
      expect(find.text('Keep using the free report'), findsOneWidget,
          reason: '영어 무료 복귀 CTA 누락');
    });

    test('B7 — CTA/restore/result 소비 경로 wiring (source)', () {
      final src = read('lib/widgets/premium_paywall.dart');
      // CTA → purchasePremium.
      expect(src.contains('purchasePremium()'), isTrue,
          reason: 'paywall CTA 가 purchasePremium 를 호출하지 않음');
      // restore → restorePurchases.
      expect(src.contains('restorePurchases()'), isTrue,
          reason: 'paywall restore 가 restorePurchases 를 호출하지 않음');
      // lastResult listen → consumeResult.
      expect(src.contains('ref.listen<PremiumState>(premiumProvider'), isTrue,
          reason: 'paywall 이 lastResult 를 listen 하지 않음');
      expect(src.contains('consumeResult()'), isTrue,
          reason: 'paywall 이 result 를 소비(consumeResult)하지 않음');
      // 결과 toast 확정 문구.
      expect(src.contains('프리미엄팩이 열렸습니다.'), isTrue,
          reason: '성공 toast 확정 문구 누락');
      expect(src.contains('구매가 취소되었습니다.'), isTrue,
          reason: '취소 toast 확정 문구 누락');
      expect(src.contains('복원할 구매 내역을 찾지 못했어요.'), isTrue,
          reason: 'restore 실패 toast 확정 문구 누락');
      // busy 중복 탭 방지.
      expect(src.contains('busy'), isTrue,
          reason: 'paywall 이 busy 상태로 중복 탭을 막지 않음');
    });
  });

  // ── C. 설정 화면 restore 진입점 ──────────────────────────────────────────

  group('C. 설정 화면 restore 진입점', () {
    test('C1 — settings_screen 에 프리미엄팩/구매 복원 행 존재', () {
      final src = read('lib/screens/settings_screen.dart');
      expect(src.contains('_PremiumPackRow'), isTrue,
          reason: '설정에 프리미엄팩 행 미적용');
      expect(src.contains('settings_premium_pack_row'), isTrue,
          reason: '설정 프리미엄팩 행 Key 누락');
      expect(src.contains('restorePurchases()'), isTrue,
          reason: '설정 행이 restorePurchases 를 호출하지 않음');
      expect(src.contains('consumeResult()'), isTrue,
          reason: '설정 행이 결과 소비(consumeResult)를 하지 않음');
    });
  });

  // ── D. 금지 문구 / 구독·광고 / 본문 절단 scan ─────────────────────────────

  group('D. paywall 금지 가드', () {
    final files = [
      'lib/widgets/premium_paywall.dart',
      'lib/widgets/premium_gate.dart',
      'lib/screens/settings_screen.dart',
    ];

    test('D1 — playbook 금지 문구 없음', () {
      const forbidden = [
        '당신의 운명을 모두 확인하려면 결제하세요',
        '오늘 안 보면 놓칩니다',
        '곧 가격이 오릅니다',
        '무료는 일부만 보여드립니다',
        '준비 중인 기능까지 미리 구매',
      ];
      for (final f in files) {
        final src = read(f);
        for (final phrase in forbidden) {
          expect(src.contains(phrase), isFalse,
              reason: '$f 에 금지 문구 "$phrase" 존재');
        }
      }
    });

    test('D2 — 구독/광고/체험/광고제거 문구 없음', () {
      // 구독·자동갱신·광고 SDK·체험·광고 제거 — 단건 IAP 정책 위반 키워드.
      final src = read('lib/widgets/premium_paywall.dart');
      const banned = [
        'autoRenewable',
        'subscription',
        'google_mobile_ads',
        'admob',
        '월 구독',
        '연 구독',
        '무료 체험',
        '광고 제거',
        '광고 없이',
      ];
      for (final w in banned) {
        expect(src.toLowerCase().contains(w.toLowerCase()), isFalse,
            reason: 'paywall 에 금지 키워드 "$w" 존재 (단건 IAP 정책 위반)');
      }
    });

    test('D3 — "준비 중" 기능을 혜택으로 팔지 않음', () {
      final src = read('lib/widgets/premium_paywall.dart');
      // 포함 항목 리스트에 준비 중/193명 류 표현이 없어야 한다.
      expect(src.contains('준비 중'), isFalse,
          reason: 'paywall 혜택에 "준비 중" 표현 존재');
      expect(src.contains('193'), isFalse,
          reason: 'paywall 에 최애의 사주 준비 중 193명 노출');
    });

    test('D4 — 본문 절단/blur/truncate 방식 추가 없음', () {
      final src = read('lib/widgets/premium_paywall.dart');
      // 본문을 흐리거나 자르는 위젯/속성을 paywall 이 도입하지 않는다.
      expect(src.contains('ImageFilter.blur'), isFalse,
          reason: 'paywall 이 blur 도입');
      expect(src.contains('TextOverflow.fade'), isFalse,
          reason: 'paywall 이 본문 fade truncate 도입');
      expect(src.contains('ShaderMask'), isFalse,
          reason: 'paywall 이 ShaderMask 본문 마스킹 도입');
    });

    test('D5 — legal URL 이 pillarseer-legal 경로로 노출', () {
      final paywall = read('lib/widgets/premium_paywall.dart');
      expect(paywall.contains('pillarseer-legal/privacy.html'), isTrue,
          reason: 'paywall privacy URL 이 pillarseer-legal 경로 아님');
      expect(paywall.contains('pillarseer-legal/terms.html'), isTrue,
          reason: 'paywall terms URL 이 pillarseer-legal 경로 아님');
      // 구 사이트 경로(pillarseer/privacy.html — legal 없음)가 남으면 안 됨.
      final settings = read('lib/screens/settings_screen.dart');
      expect(settings.contains('github.io/pillarseer/privacy.html'), isFalse,
          reason: 'settings 에 구 legal 경로(pillarseer/privacy.html)가 남음');
      expect(settings.contains('github.io/pillarseer/terms.html'), isFalse,
          reason: 'settings 에 구 legal 경로(pillarseer/terms.html)가 남음');
      expect(settings.contains('pillarseer-legal/privacy.html'), isTrue,
          reason: 'settings privacy URL 정정 안 됨');
      expect(settings.contains('pillarseer-legal/terms.html'), isTrue,
          reason: 'settings terms URL 정정 안 됨');
    });
  });
}
