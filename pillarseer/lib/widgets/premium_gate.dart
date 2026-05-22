// Pillar Seer — R110 Sprint 2: 무료/프리미엄 기능 게이트 helper.
//
// monetization_playbook.md 기준:
//   - 본문 중간 truncate/blur 금지. 카테고리·항목·섹션 단위로만 잠근다.
//   - 잠긴 항목 = 제목 + 짧은 설명 + 프리미엄 CTA placeholder 만 노출.
//     기능 고장/미완성처럼 보이면 안 된다.
//   - "준비 중" 기능을 프리미엄 혜택으로 팔지 않는다.
//
// 이 Sprint 의 책임:
//   - premium 게이트 진입점(`PremiumGate`)과, 잠긴 섹션이 정상적으로 보이는
//     placeholder UI(`PremiumLockedSection`) 를 마련한다.
//   - 잠긴 항목 탭을 단일 hook(`onPremiumLockedTap`)으로 모은다.
//   - Sprint 3 의 실제 paywall route 는 *아직 추가하지 않는다*. 이번 임시
//     구현은 SnackBar 안내 + 콜백 호출까지만 한다.
//
// Sprint 3 연결 방식:
//   - paywall 은 `PremiumLockContext`(feature id + 사람이 읽는 라벨 + 원본
//     BuildContext) 를 받는 콜백으로 호출된다. ProviderScope 어디서든
//     `kPremiumLockedTapOverride` 를 교체하면 Sprint 3 가 실제 route push 로
//     이 hook 을 대체할 수 있다(테스트도 이 override 로 tap 을 가로챈다).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../providers/premium_provider.dart';
import '../theme/app_theme.dart';

/// 프리미엄 게이트가 걸린 기능 식별자. Sprint 3 paywall 이 진입 맥락별로
/// 업셀 문구/스크린샷을 고를 수 있도록 9개 기능 + 세부 섹션을 구분한다.
enum PremiumFeature {
  /// ① 내 사주 17카테고리 — 프리미엄 12개 영역.
  mySajuCategory,

  /// ① 내 사주 — 깊은 종합 결론.
  mySajuConclusion,

  /// ② 오늘의 사주 — 심층 해석·5일 흐름·개인화 확장.
  todayDeep,

  /// ③ 궁합 — 상세 케미(끌림/마찰/연애·결혼·자녀/실천).
  compatibilityDetail,

  /// ④ 2026 신년운세 — 12개월 전체·테마별 상세.
  newYearAreas,

  /// ⑤ 최애의 사주 — Top 30 추가 열람/비교.
  celebrityMore,

  /// ⑥ 전생 이야기 — 다른 최애로 추가 생성.
  pastLifeMore,

  /// ⑦ 음악 처방 — 상세 처방(효능/부작용/복용법/본문)·다시 처방.
  musicDetail,

  /// ⑧ 자미두수 명반 — 궁·별 상세 해석·교차해석.
  ziweiDetail,

  /// ⑨ 매일 운세 알림 — 시간대별·주제별 개인화 알림.
  notificationSlots,
}

/// 잠긴 항목 탭 시 paywall 로 넘길 맥락.
@immutable
class PremiumLockContext {
  const PremiumLockContext({
    required this.feature,
    required this.label,
    this.context,
  });

  /// 어떤 기능에서 막혔는지 — Sprint 3 paywall 업셀 분기용.
  final PremiumFeature feature;

  /// 사람이 읽는 진입 맥락 라벨(예: '재물운', '오늘의 사주 심층').
  final String label;

  /// 탭이 일어난 위젯의 BuildContext — Sprint 3 가 route push 에 사용.
  final BuildContext? context;
}

/// 잠긴 항목 탭 hook. 기본 구현은 SnackBar 안내만 — Sprint 3 가 실제
/// paywall route push 로 교체할 수 있도록 교체 가능한 전역 함수로 둔다.
typedef PremiumLockedTap = void Function(PremiumLockContext lock);

/// 기본 hook — Sprint 3 전까지 SnackBar 안내 + (있으면) debugPrint.
/// 실제 paywall route 는 추가하지 않는다(Sprint 3 범위).
void _defaultPremiumLockedTap(PremiumLockContext lock) {
  final ctx = lock.context;
  if (ctx != null && ctx.mounted) {
    final useKo =
        (Localizations.maybeLocaleOf(ctx)?.languageCode ?? 'en') == 'ko';
    ScaffoldMessenger.of(ctx)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.ink,
        content: Text(
          useKo
              ? '프리미엄팩에서 ${lock.label}을(를) 더 깊게 볼 수 있어요.'
              : 'The Premium Pack opens a deeper look at ${lock.label}.',
          style: GoogleFonts.notoSansKr(fontSize: 13, color: AppColors.bg),
        ),
      ));
  }
  debugPrint('[PremiumGate] locked tap → ${lock.feature.name} (${lock.label})');
}

/// 잠긴 항목 탭 hook. Sprint 3 paywall 이 `kPremiumLockedTapOverride =` 로
/// 실제 route push 구현을 주입한다. 테스트도 이 변수로 tap 을 가로챈다.
PremiumLockedTap kPremiumLockedTapOverride = _defaultPremiumLockedTap;

/// 어디서든 잠긴 항목 탭을 발생시키는 단일 진입점.
void onPremiumLockedTap(PremiumLockContext lock) =>
    kPremiumLockedTapOverride(lock);

/// 프리미엄 게이트 — `unlocked` 면 [unlocked] 본문을, 아니면 [locked]
/// placeholder 를 mount 한다.
///
/// 핵심 규칙(playbook §3): 잠금 시 [unlocked] 본문 위젯은 *아예 build 되지
/// 않는다*. 본문을 만든 뒤 blur/truncate 하지 않는다 — 섹션 단위 교체.
class PremiumGate extends ConsumerWidget {
  const PremiumGate({
    super.key,
    required this.feature,
    required this.label,
    required this.unlocked,
    required this.locked,
  });

  /// 게이트가 걸린 기능.
  final PremiumFeature feature;

  /// paywall 로 넘길 사람이 읽는 라벨.
  final String label;

  /// 프리미엄 보유 시 보여줄 실제 본문 빌더.
  final WidgetBuilder unlocked;

  /// 미보유 시 보여줄 잠금 placeholder 빌더.
  final WidgetBuilder locked;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isUnlocked = ref.watch(isPremiumUnlockedProvider);
    return isUnlocked ? unlocked(context) : locked(context);
  }
}

/// 잠긴 섹션 표준 placeholder.
///
/// 섹션 제목 + 짧은 설명 + 프리미엄 CTA 만 노출한다. 본문 일부를 흐리거나
/// 자르지 않는다(playbook §3·§4). 탭하면 [onPremiumLockedTap] 으로 모인다.
class PremiumLockedSection extends StatelessWidget {
  const PremiumLockedSection({
    super.key,
    required this.feature,
    required this.title,
    required this.description,
    this.background,
    this.padding = const EdgeInsets.fromLTRB(24, 28, 24, 28),
    this.bottomBorder = true,
    this.compact = false,
  });

  /// 잠긴 기능.
  final PremiumFeature feature;

  /// 잠긴 섹션 제목(예: '재물운', '오늘의 사주 심층 해석').
  final String title;

  /// 한 줄 안내 — 무엇을 더 볼 수 있는지. "준비 중" 톤 금지.
  final String description;

  /// 섹션 배경색. null 이면 paper.
  final Color? background;

  final EdgeInsets padding;

  /// 하단 hairline border 표시 여부.
  final bool bottomBorder;

  /// 좁은 inline 잠금(예: 알림 슬롯 행) 용 컴팩트 레이아웃.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final useKo =
        (Localizations.maybeLocaleOf(context)?.languageCode ?? 'en') == 'ko';
    final ctaLabel = useKo ? '프리미엄팩 열기' : 'Open Premium Pack';

    final inner = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.lock_outline,
                size: 15, color: AppColors.taupe),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.notoSerifKr(
                  fontSize: compact ? 14 : 15,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.2,
                  color: AppColors.ink,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: compact ? 6 : 10),
        Text(
          description,
          style: GoogleFonts.notoSansKr(
            fontSize: 12.5,
            color: AppColors.taupe,
            height: 1.65,
          ),
        ),
        SizedBox(height: compact ? 10 : 14),
        // 프리미엄 CTA placeholder — Sprint 3 가 paywall 로 연결.
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.accent, width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  ctaLabel.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    letterSpacing: 2.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.accent,
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.arrow_forward,
                    size: 13, color: AppColors.accent),
              ],
            ),
          ),
        ),
      ],
    );

    return InkWell(
      key: Key('premium_locked_${feature.name}'),
      onTap: () => onPremiumLockedTap(PremiumLockContext(
        feature: feature,
        label: title,
        context: context,
      )),
      child: Container(
        width: double.infinity,
        padding: padding,
        decoration: BoxDecoration(
          color: background ?? AppColors.paper,
          border: bottomBorder
              ? const Border(
                  bottom: BorderSide(color: AppColors.line, width: 0.6))
              : null,
        ),
        child: inner,
      ),
    );
  }
}
