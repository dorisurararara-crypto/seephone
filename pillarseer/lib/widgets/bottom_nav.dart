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
