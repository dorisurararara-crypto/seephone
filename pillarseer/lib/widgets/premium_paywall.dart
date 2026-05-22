// Pillar Seer — R110 Sprint 3: 프리미엄팩 paywall bottom sheet.
//
// monetization_playbook.md §"Paywall UX" 기준:
//   - 진입: 잠긴 카테고리/항목 탭 → 이 bottom sheet.
//   - 구매 안 해도 무료로 복귀 가능 ("지금은 무료로 계속 보기").
//   - 본문 중간 truncate/blur 금지 — 이 sheet 는 별도 면으로, 무료 본문을
//     가리지 않는다. 잠긴 섹션은 PremiumLockedSection placeholder 가 담당.
//   - 미완성 예정 기능을 혜택으로 팔지 않는다 — 포함 항목 리스트는 playbook
//     확정안만 사용.
//
// 표시 방식: route 추가 대신 기존 UX(input_screen / home_screen)의
// showModalBottomSheet 패턴을 따른다. 진입점은 `showPremiumPaywall()`.
//
// hook 연결: premium_gate.dart 의 `kPremiumLockedTapOverride` 기본 구현이
// 이 함수를 호출하도록 교체된다(테스트 override 는 그대로 가능).
//
// 구매/복원 흐름:
//   - CTA       → premiumProvider.notifier.purchasePremium()
//   - restore   → premiumProvider.notifier.restorePurchases()
//   - busy      → CTA/restore 중복 탭 방지 + 로딩 표시
//   - lastResult→ listen 하여 toast 1회 후 consumeResult(). 성공/복원 성공
//     이면 sheet 를 닫고, 취소/실패/복원 없음이면 무료로 계속 보기 가능.
//   - store unavailable/error 도 크래시 없이 무료로 계속 보기 가능.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/premium_provider.dart';
import '../services/purchase_service.dart';
import '../theme/app_theme.dart';
import 'premium_gate.dart';

/// 가격 fallback — StoreKit localized price 미조회 시에만 사용.
/// 단건 구매 가격임을 해치지 않는 짧은 표기 (구독/월/연 표기 금지).
const String _kPriceFallbackKo = '₩5,900';
const String _kPriceFallbackEn = r'$4.99';

/// 법무 사이트 (pillarseer-legal).
const String _kPrivacyUrl =
    'https://dorisurararara-crypto.github.io/pillarseer-legal/privacy.html';
const String _kTermsUrl =
    'https://dorisurararara-crypto.github.io/pillarseer-legal/terms.html';

/// 잠긴 항목 탭 → 프리미엄팩 paywall bottom sheet 를 띄운다.
///
/// premium_gate.dart 의 `kPremiumLockedTapOverride` 기본 구현이 이 함수를
/// 호출한다. [context] 가 null 이거나 unmounted 면 크래시 없이 no-op.
void showPremiumPaywall(BuildContext? context, PremiumLockContext lock) {
  if (context == null || !context.mounted) {
    debugPrint('[PremiumPaywall] no usable context → no-op '
        '(${lock.feature.name})');
    return;
  }
  // toast 는 sheet 가 닫힌 뒤에도 떠야 하므로, sheet 보다 위(루트)에 사는
  // ScaffoldMessenger 를 미리 잡아 sheet 에 넘긴다.
  final messenger = ScaffoldMessenger.maybeOf(context);
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.bg,
    barrierColor: AppColors.ink.withValues(alpha: 0.42),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetCtx) =>
        _PremiumPaywallSheet(lock: lock, messenger: messenger),
  );
}

/// paywall bottom sheet 본체. ProviderScope 안에서 동작 — premiumProvider 를
/// watch/listen 한다.
class _PremiumPaywallSheet extends ConsumerStatefulWidget {
  const _PremiumPaywallSheet({required this.lock, this.messenger});

  final PremiumLockContext lock;

  /// sheet 보다 위에 사는 ScaffoldMessenger — sheet 가 닫혀도 toast 가
  /// 살아남도록 toast 는 이 messenger 로 띄운다.
  final ScaffoldMessengerState? messenger;

  @override
  ConsumerState<_PremiumPaywallSheet> createState() =>
      _PremiumPaywallSheetState();
}

class _PremiumPaywallSheetState extends ConsumerState<_PremiumPaywallSheet> {
  bool _useKo(BuildContext context) =>
      (Localizations.maybeLocaleOf(context)?.languageCode ?? 'en') == 'ko';

  /// lastResult → toast 1회 표시 후 consumeResult. 성공/복원 성공이면 sheet 를
  /// 닫는다. 취소/실패/복원 없음은 무료로 계속 보기 가능 — sheet 유지.
  void _handleResult(PurchaseOutcome outcome) {
    final useKo = _useKo(context);
    String? msg;
    var closeSheet = false;
    switch (outcome) {
      case PurchaseOutcome.purchased:
      case PurchaseOutcome.restored:
        msg = useKo ? '프리미엄팩이 열렸습니다.' : 'Premium Pack unlocked.';
        closeSheet = true;
        break;
      case PurchaseOutcome.canceled:
        msg = useKo ? '구매가 취소되었습니다.' : 'Purchase canceled.';
        break;
      case PurchaseOutcome.nothingToRestore:
        msg = useKo
            ? '복원할 구매 내역을 찾지 못했어요.'
            : "We couldn't find a purchase to restore.";
        break;
      case PurchaseOutcome.error:
        msg = useKo
            ? '잠시 후 다시 시도해 주세요. 무료 리포트는 계속 사용할 수 있어요.'
            : 'Please try again later. The free report stays available.';
        break;
      case PurchaseOutcome.unavailable:
        msg = useKo
            ? '지금은 스토어에 연결할 수 없어요. 무료 리포트는 계속 사용할 수 있어요.'
            : "The store isn't reachable right now. The free report stays available.";
        break;
      case PurchaseOutcome.alreadyOwned:
      case PurchaseOutcome.pending:
        // 진행 중/영수증 확인 단계 — toast 없음. 후속 결과에서 처리.
        msg = null;
        break;
    }
    // result 는 1회만 소비.
    ref.read(premiumProvider.notifier).consumeResult();
    // sheet 를 먼저 닫고(성공 시), toast 는 루트 messenger 로 띄운다 —
    // sheet route 가 사라져도 toast 가 유지된다.
    if (closeSheet && mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
    if (msg != null) {
      final messenger = widget.messenger ??
          (mounted ? ScaffoldMessenger.maybeOf(context) : null);
      messenger
        ?..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.ink,
          content: Text(
            msg,
            style: GoogleFonts.notoSansKr(fontSize: 13, color: AppColors.bg),
          ),
        ));
    }
  }

  Future<void> _openLink(String url) async {
    final messenger = ScaffoldMessenger.of(context);
    final useKo = _useKo(context);
    try {
      final ok = await launchUrl(Uri.parse(url),
          mode: LaunchMode.externalApplication);
      if (!ok) throw Exception('launch returned false');
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: url));
      if (!mounted) return;
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.ink,
          content: Text(
            useKo ? '주소를 복사했어요.' : 'URL copied.',
            style: GoogleFonts.notoSansKr(fontSize: 13, color: AppColors.bg),
          ),
        ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final useKo = _useKo(context);
    final premium = ref.watch(premiumProvider);
    final busy = premium.busy;

    // 결과(toast) 1회 처리 — listen 으로 lastResult 변화를 받는다.
    ref.listen<PremiumState>(premiumProvider, (prev, next) {
      final outcome = next.lastResult;
      if (outcome != null && prev?.lastResult != outcome) {
        _handleResult(outcome);
      }
    });

    final priceLabel = _priceLabel(premium, useKo);

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 14, 24, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // grab handle.
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 22),
                  decoration: BoxDecoration(
                    color: AppColors.line,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                (useKo ? 'PREMIUM PACK' : 'PREMIUM PACK'),
                style: GoogleFonts.inter(
                  fontSize: 9,
                  letterSpacing: 5,
                  fontWeight: FontWeight.w500,
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(height: 12),
              // 헤드라인 (playbook 확정안).
              Text(
                useKo
                    ? '내 사주를 더 깊게 열어보세요'
                    : 'Open a deeper reading of your saju',
                style: GoogleFonts.notoSerifKr(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 10),
              // 서브 (playbook 확정안).
              Text(
                useKo
                    ? '무료 리포트는 계속 사용할 수 있어요. 프리미엄팩은 긴 해석과 추가 리포트를 한 번에 여는 단건 구매입니다.'
                    : 'The free report stays available. The Premium Pack is a one-time purchase that opens longer readings and extra reports together.',
                style: GoogleFonts.notoSansKr(
                  fontSize: 13,
                  height: 1.7,
                  color: AppColors.inkLight,
                ),
              ),
              const SizedBox(height: 22),
              // 포함 항목 리스트 (playbook 확정안 — 미완성 예정 항목 제외).
              ..._benefits(useKo).map((b) => _BenefitRow(text: b)),
              const SizedBox(height: 20),
              Container(height: 1, color: AppColors.line),
              const SizedBox(height: 18),
              // 가격 — StoreKit localized price 우선.
              Center(
                child: Text(
                  priceLabel,
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              // 가격 보조 (playbook 확정안).
              Center(
                child: Text(
                  useKo
                      ? '한 번 구매하면 계속 사용할 수 있어요.'
                      : 'Buy once and keep it for good.',
                  style: GoogleFonts.notoSansKr(
                    fontSize: 12,
                    color: AppColors.taupe,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              // CTA — 프리미엄팩 열기.
              _PrimaryButton(
                label: busy
                    ? (useKo ? '처리 중…' : 'Working…')
                    : (useKo ? '프리미엄팩 열기' : 'Open Premium Pack'),
                busy: busy,
                onTap: busy
                    ? null
                    : () => ref
                        .read(premiumProvider.notifier)
                        .purchasePremium(),
              ),
              const SizedBox(height: 10),
              // 보조 — 지금은 무료로 계속 보기.
              TextButton(
                onPressed: busy
                    ? null
                    : () {
                        if (Navigator.of(context).canPop()) {
                          Navigator.of(context).pop();
                        }
                      },
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.taupe,
                  minimumSize: const Size(0, 44),
                  shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero),
                ),
                child: Text(
                  useKo ? '지금은 무료로 계속 보기' : 'Keep using the free report',
                  style: GoogleFonts.notoSansKr(
                    fontSize: 13,
                    color: AppColors.taupe,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              // restore 진입점 1/2 — paywall 하단.
              Center(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: busy
                      ? null
                      : () => ref
                          .read(premiumProvider.notifier)
                          .restorePurchases(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      useKo
                          ? '이미 구매하셨나요? 구매 복원'
                          : 'Already purchased? Restore purchase',
                      style: GoogleFonts.notoSansKr(
                        fontSize: 12.5,
                        color: busy ? AppColors.taupe : AppColors.inkLight,
                        decoration: TextDecoration.underline,
                        decorationColor: AppColors.taupe,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              // 약관 / 개인정보 — 작은 텍스트 링크.
              Center(
                child: Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _LegalLink(
                      label: useKo ? '이용약관' : 'Terms of Use',
                      onTap: () => _openLink(_kTermsUrl),
                    ),
                    Text(
                      '   ·   ',
                      style: GoogleFonts.notoSansKr(
                        fontSize: 11,
                        color: AppColors.taupe,
                      ),
                    ),
                    _LegalLink(
                      label: useKo ? '개인정보 처리방침' : 'Privacy Policy',
                      onTap: () => _openLink(_kPrivacyUrl),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 가격 라벨 — StoreKit localized price 우선, 없으면 fallback.
  String _priceLabel(PremiumState premium, bool useKo) {
    final p = premium.localizedPrice;
    if (p != null && p.trim().isNotEmpty) return p.trim();
    return useKo ? _kPriceFallbackKo : _kPriceFallbackEn;
  }

  /// 포함 항목 — monetization_playbook.md 확정안 그대로. 미완성 예정 항목 제외.
  List<String> _benefits(bool useKo) {
    if (useKo) {
      return const [
        '내 사주 17개 카테고리 전체 해석',
        '2026 신년운세 12개월 전체',
        '연애·결혼·자녀 궁합 리포트',
        '전생 이야기 66편',
        '자미두수 상세 해석',
        '개인화 운세 알림 확장',
      ];
    }
    return const [
      'All 17 saju categories, fully read',
      'The full 12 months of the 2026 yearly fortune',
      'Love, marriage, and children compatibility reports',
      'All 66 past-life stories',
      'Detailed Zi Wei Dou Shu reading',
      'Expanded personalized fortune alerts',
    ];
  }
}

/// 포함 항목 한 줄 — 체크 글리프 + 텍스트.
class _BenefitRow extends StatelessWidget {
  const _BenefitRow({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(Icons.check, size: 15, color: AppColors.accent),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.notoSansKr(
                fontSize: 13,
                height: 1.55,
                color: AppColors.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 주 CTA 버튼 — ink 채움. busy 면 비활성 + 로딩 표시.
class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.busy,
    required this.onTap,
  });

  final String label;
  final bool busy;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: onTap == null ? AppColors.taupe : AppColors.ink,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (busy) ...[
              const SizedBox(
                width: 15,
                height: 15,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.bg),
                ),
              ),
              const SizedBox(width: 10),
            ],
            Text(
              label.toUpperCase(),
              style: GoogleFonts.inter(
                fontSize: 11,
                letterSpacing: 3,
                fontWeight: FontWeight.w600,
                color: AppColors.bg,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 약관/개인정보 작은 텍스트 링크.
class _LegalLink extends StatelessWidget {
  const _LegalLink({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Text(
        label,
        style: GoogleFonts.notoSansKr(
          fontSize: 11,
          color: AppColors.taupe,
          decoration: TextDecoration.underline,
          decorationColor: AppColors.taupe,
        ),
      ),
    );
  }
}
