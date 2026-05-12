import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';

/// Aesop Luxury bottom nav — 4탭, hairline top border, letter-spacing UPPERCASE label.
/// Active = ink text + 1px underline. Inactive = taupe.
class PillarBottomNav extends StatelessWidget {
  final int activeIdx;

  const PillarBottomNav({super.key, required this.activeIdx});

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final items = <_NavItem>[
      _NavItem(label: l.navHome, route: '/home', glyph: '日'),
      _NavItem(label: l.navReading, route: '/result', glyph: '柱'),
      _NavItem(label: l.navReports, route: '/reports', glyph: '譜'),
      _NavItem(label: l.navProfile, route: '/profile', glyph: '我'),
    ];
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bg,
        border: Border(top: BorderSide(color: AppColors.line, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: items.asMap().entries.map((entry) {
              final i = entry.key;
              final item = entry.value;
              final isActive = i == activeIdx;
              return Expanded(
                child: Semantics(
                  button: true,
                  selected: isActive,
                  label: item.label,
                  child: InkWell(
                    onTap: () {
                      // codex nav fix: 같은 탭이라도 sub-route 에 있을 때는
                      // 탭 루트로 가야 함 (예: /discover 에서 리포트 탭 → /reports).
                      final loc = GoRouterState.of(context).matchedLocation;
                      if (loc == item.route) return;
                      context.go(item.route);
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // 한국어 메인 (큼, 명확)
                        Text(
                          item.label,
                          style: GoogleFonts.notoSansKr(
                            fontSize: 12,
                            fontWeight: isActive
                                ? FontWeight.w500
                                : FontWeight.w400,
                            letterSpacing: 0.3,
                            color: isActive
                                ? AppColors.ink
                                : AppColors.taupe,
                          ),
                        ),
                        const SizedBox(height: 3),
                        // 한자는 작은 sub-accent (장식)
                        Text(
                          item.glyph,
                          style: GoogleFonts.notoSerifKr(
                            fontSize: 10,
                            fontWeight: FontWeight.w300,
                            color: isActive
                                ? AppColors.accent
                                : AppColors.taupe.withValues(alpha: 0.55),
                            height: 1.0,
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

class _NavItem {
  final String label;
  final String route;
  final String glyph;
  const _NavItem({
    required this.label,
    required this.route,
    required this.glyph,
  });
}
