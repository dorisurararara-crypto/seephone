import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';

/// Aesop Luxury bottom nav — 4탭, hairline top border, letter-spacing UPPERCASE label.
/// Active = ink text + 1px underline. Inactive = taupe.
///
/// R109 FIX 2 — StatefulShellRoute 의 shell 이 주입하는 [StatefulNavigationShell]
/// 로 동작한다. 탭 onTap = navigationShell.goBranch(idx) — branch 를 IndexedStack
/// 으로 살려둬 탭 전환·복귀 시 스크롤·State 가 보존된다. active = currentIndex.
class PillarBottomNav extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const PillarBottomNav({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final currentBranch = navigationShell.currentIndex;
    final items = <String>[
      l.navHome,
      l.navReading,
      l.navReports,
      l.navProfile,
    ];
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bg,
        border: Border(top: BorderSide(color: AppColors.line, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 56,
          child: Row(
            children: items.asMap().entries.map((entry) {
              final i = entry.key;
              final label = entry.value;
              final isActive = i == currentBranch;
              return Expanded(
                child: Semantics(
                  button: true,
                  selected: isActive,
                  label: label,
                  child: InkWell(
                    onTap: () {
                      // goBranch — 같은 branch 면 그 branch 의 초기 location 으로
                      // (initialLocation: true), 다른 branch 면 그 branch 로 전환.
                      // IndexedStack 이라 이전 branch State 는 dispose 안 됨.
                      navigationShell.goBranch(
                        i,
                        initialLocation: i == navigationShell.currentIndex,
                      );
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // 한국어 메인 (큼, 명확)
                        Text(
                          label,
                          style: GoogleFonts.notoSansKr(
                            fontSize: 13,
                            fontWeight: isActive
                                ? FontWeight.w500
                                : FontWeight.w400,
                            letterSpacing: 0.3,
                            color: isActive ? AppColors.ink : AppColors.taupe,
                          ),
                        ),
                        const SizedBox(height: 6),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          width: isActive ? 22 : 0,
                          height: 1,
                          color: AppColors.ink,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

/// R109 — shell 밖(top-level push) 화면용 정적 하단 탭. 리포트 상세 9화면 +
/// discover 처럼 StatefulShellRoute branch 가 아닌 화면이 사용한다.
/// onTap = context.go(탭 route) — shell 은 이 화면 아래에 살아 있으므로,
/// 탭을 누르면 그 탭(branch)으로 가며 branch State(스크롤)는 그대로 보존된다.
class PillarBottomNavStatic extends StatelessWidget {
  /// 활성 탭 index — 리포트 상세·discover 는 모두 2(리포트).
  final int activeIdx;

  const PillarBottomNavStatic({super.key, required this.activeIdx});

  static const _routes = <String>['/home', '/result', '/reports', '/profile'];

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final items = <String>[
      l.navHome,
      l.navReading,
      l.navReports,
      l.navProfile,
    ];
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bg,
        border: Border(top: BorderSide(color: AppColors.line, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 56,
          child: Row(
            children: items.asMap().entries.map((entry) {
              final i = entry.key;
              final label = entry.value;
              final isActive = i == activeIdx;
              return Expanded(
                child: Semantics(
                  button: true,
                  selected: isActive,
                  label: label,
                  child: InkWell(
                    onTap: () {
                      if (i == activeIdx) return;
                      context.go(_routes[i]);
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          label,
                          style: GoogleFonts.notoSansKr(
                            fontSize: 13,
                            fontWeight: isActive
                                ? FontWeight.w500
                                : FontWeight.w400,
                            letterSpacing: 0.3,
                            color: isActive ? AppColors.ink : AppColors.taupe,
                          ),
                        ),
                        const SizedBox(height: 6),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          width: isActive ? 22 : 0,
                          height: 1,
                          color: AppColors.ink,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
