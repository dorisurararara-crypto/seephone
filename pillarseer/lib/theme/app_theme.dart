import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Pillar Seer — Aesop Luxury palette.
///
/// 새 canonical 토큰: bg / paper / ink / inkLight / taupe / line / accent.
/// 이전 토큰(`cosmicBlack`, `midnightPurple` 등)은 alias 로 남아 기존 화면이 그대로 컴파일.
class AppColors {
  // ===== Aesop canonical palette =====
  static const bg = Color(0xFFEDE6D6);        // apothecary cream — scaffold
  static const paper = Color(0xFFE5DCC8);     // slightly darker cream — section accent
  static const ink = Color(0xFF2A2520);       // primary text (deep brown-black)
  static const inkLight = Color(0xFF5A5247);  // secondary text (warm gray-brown)
  static const taupe = Color(0xFF7C7166);     // muted label / divider tone
  static const line = Color(0xFFC9BFA9);      // 1px hairline border
  static const accent = Color(0xFFA88A4E);    // single gold-brown accent (강조 단어 한 곳)

  // ===== Legacy aliases (backwards compat — DO NOT remove without screen audit) =====
  static const cosmicBlack = bg;
  static const midnightPurple = paper;
  static const spiritIndigo = ink;
  static const mysticViolet = inkLight;
  static const celestialGold = accent;
  static const ghostlyWhite = ink;
  static const moonlightGray = inkLight;
  static const fadedSilver = taupe;
  static const cardSurface = paper;
  static const cardBorder = line;
  static const cardBorderStrong = taupe;

  // ===== Five Elements — warm muted tones (Aesop 톤 유지) =====
  static const woodJade = Color(0xFF7A8C5F);     // sage green
  static const fireRed = Color(0xFFB55A3C);      // muted terracotta
  static const earthBronze = Color(0xFFA88A4E);  // = accent (gold-brown)
  static const metalSilver = Color(0xFF9A938A);  // warm silver-gray
  static const waterOcean = Color(0xFF4A5C6B);   // deep slate

  /// 5행 → 색상 매핑
  static Color forElement(String element) {
    switch (element) {
      case '木': case 'Wood': return woodJade;
      case '火': case 'Fire': return fireRed;
      case '土': case 'Earth': return earthBronze;
      case '金': case 'Metal': return metalSilver;
      case '水': case 'Water': return waterOcean;
      default: return accent;
    }
  }
}

/// Aesop Luxury 톤 typography 헬퍼.
/// 화면이 직접 호출해서 letter-spacing UPPERCASE 라벨, serif hero, italic accent 적용.
class AppType {
  /// Section / detail label — 9px, letter-spacing 5, UPPERCASE, taupe.
  static TextStyle label({Color? color, double size = 9, double spacing = 5}) =>
      GoogleFonts.inter(
        fontSize: size,
        letterSpacing: spacing,
        fontWeight: FontWeight.w500,
        color: color ?? AppColors.taupe,
        height: 1.0,
      );

  /// Section meta (DAY MASTER · 日 柱) — 9px, letter-spacing 5, taupe.
  static TextStyle meta({Color? color}) => label(color: color);

  /// Hero serif (한자 일주 + Fire Rabbit) — 36, weight 300.
  static TextStyle hero({double size = 36, Color? color}) =>
      GoogleFonts.notoSerifKr(
        fontSize: size,
        fontWeight: FontWeight.w300,
        letterSpacing: -0.5,
        height: 1.2,
        color: color ?? AppColors.ink,
      );

  /// Body — 15, line-height 1.85 (긴 한국어 단락).
  static TextStyle body({double size = 15, Color? color}) =>
      GoogleFonts.notoSansKr(
        fontSize: size,
        fontWeight: FontWeight.w400,
        height: 1.85,
        color: color ?? AppColors.ink,
      );

  /// Italic emphasis (Cormorant Garamond) — 강조 phrase 한 곳.
  static TextStyle italicAccent({double size = 15, Color? color}) =>
      GoogleFonts.cormorantGaramond(
        fontSize: size,
        fontStyle: FontStyle.italic,
        fontWeight: FontWeight.w400,
        height: 1.85,
        color: color ?? AppColors.accent,
      );

  /// Serif value (CHART ATTRIBUTES grid cell 의 한자) — 18, weight 400.
  static TextStyle serifValue({double size = 18, Color? color}) =>
      GoogleFonts.notoSerifKr(
        fontSize: size,
        fontWeight: FontWeight.w400,
        height: 1.2,
        color: color ?? AppColors.ink,
      );

  /// CTA — 11px, letter-spacing 5, UPPERCASE.
  static TextStyle cta({Color? color}) => GoogleFonts.inter(
        fontSize: 11,
        letterSpacing: 5,
        fontWeight: FontWeight.w500,
        color: color ?? AppColors.bg,
      );
}

class AppTheme {
  static ThemeData get darkTheme {
    // 한국어 가독성 — Noto Sans KR 우선. 본문 ink (light bg) 톤.
    final base = GoogleFonts.notoSansKrTextTheme(
      const TextTheme(
        bodyMedium: TextStyle(color: AppColors.ink, fontSize: 14, height: 1.6),
        bodyLarge: TextStyle(color: AppColors.ink, fontSize: 15, height: 1.7),
      ),
    );
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.bg,
      dividerColor: AppColors.line,
      canvasColor: AppColors.bg,
      cardColor: AppColors.paper,
      colorScheme: const ColorScheme.light(
        primary: AppColors.ink,
        onPrimary: AppColors.bg,
        secondary: AppColors.accent,
        onSecondary: AppColors.ink,
        surface: AppColors.bg,
        onSurface: AppColors.ink,
        surfaceContainerHighest: AppColors.paper,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.bg,
        foregroundColor: AppColors.ink,
        surfaceTintColor: AppColors.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          color: AppColors.ink,
          fontSize: 12,
          letterSpacing: 5,
          fontWeight: FontWeight.w500,
        ),
        iconTheme: const IconThemeData(color: AppColors.ink, size: 20),
        shape: const Border(
          bottom: BorderSide(color: AppColors.line, width: 1),
        ),
      ),
      iconTheme: const IconThemeData(color: AppColors.ink, size: 20),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.ink,
        linearTrackColor: AppColors.line,
        circularTrackColor: AppColors.line,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.line,
        thickness: 1,
        space: 1,
      ),
      cardTheme: const CardThemeData(
        color: AppColors.paper,
        surfaceTintColor: AppColors.paper,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: BorderSide(color: AppColors.line, width: 1),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.ink,
          foregroundColor: AppColors.bg,
          textStyle: AppType.cta(),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
          ),
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 28),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.ink,
          foregroundColor: AppColors.bg,
          elevation: 0,
          textStyle: AppType.cta(),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
          ),
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 28),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.ink,
          textStyle: AppType.label(color: AppColors.ink, spacing: 3),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.ink,
          side: const BorderSide(color: AppColors.ink, width: 1),
          textStyle: AppType.cta(color: AppColors.ink),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
          ),
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 28),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.bg,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        labelStyle: AppType.label(color: AppColors.taupe, spacing: 3),
        floatingLabelStyle: AppType.label(color: AppColors.ink, spacing: 3),
        hintStyle: GoogleFonts.notoSansKr(
          color: AppColors.taupe,
          fontSize: 14,
        ),
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(2)),
          borderSide: BorderSide(color: AppColors.line, width: 1),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(2)),
          borderSide: BorderSide(color: AppColors.line, width: 1),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(2)),
          borderSide: BorderSide(color: AppColors.ink, width: 1),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.bg,
        selectedColor: AppColors.ink,
        secondarySelectedColor: AppColors.ink,
        labelStyle:
            AppType.label(color: AppColors.inkLight, size: 10, spacing: 3),
        secondaryLabelStyle:
            AppType.label(color: AppColors.bg, size: 10, spacing: 3),
        side: const BorderSide(color: AppColors.line, width: 1),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(2)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.bg,
        surfaceTintColor: AppColors.bg,
        modalBackgroundColor: AppColors.bg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(2)),
          side: BorderSide(color: AppColors.line, width: 1),
        ),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: AppColors.bg,
        surfaceTintColor: AppColors.bg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: BorderSide(color: AppColors.line, width: 1),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.ink,
        contentTextStyle: GoogleFonts.notoSansKr(
          color: AppColors.bg,
          fontSize: 13,
        ),
        actionTextColor: AppColors.accent,
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(2)),
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.ink,
        unselectedLabelColor: AppColors.taupe,
        labelStyle: AppType.label(color: AppColors.ink, spacing: 3),
        unselectedLabelStyle: AppType.label(color: AppColors.taupe, spacing: 3),
        indicatorColor: AppColors.ink,
        dividerColor: AppColors.line,
      ),
      sliderTheme: const SliderThemeData(
        activeTrackColor: AppColors.ink,
        inactiveTrackColor: AppColors.line,
        thumbColor: AppColors.ink,
        overlayColor: Color(0x14000000),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStatePropertyAll(AppColors.ink),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? AppColors.ink.withValues(alpha: 0.4)
              : AppColors.line,
        ),
      ),
      textTheme: base.copyWith(
        displayLarge: GoogleFonts.notoSerifKr(
          fontSize: 36,
          fontWeight: FontWeight.w300,
          letterSpacing: -0.5,
          color: AppColors.ink,
        ),
        displayMedium: GoogleFonts.notoSerifKr(
          fontSize: 28,
          fontWeight: FontWeight.w300,
          color: AppColors.ink,
        ),
        headlineMedium: GoogleFonts.notoSerifKr(
          fontSize: 22,
          fontWeight: FontWeight.w400,
          color: AppColors.ink,
        ),
        titleLarge: GoogleFonts.notoSerifKr(
          fontSize: 18,
          fontWeight: FontWeight.w400,
          color: AppColors.ink,
        ),
        bodyLarge: GoogleFonts.notoSansKr(
          color: AppColors.ink,
          fontSize: 15,
          height: 1.7,
        ),
        bodyMedium: GoogleFonts.notoSansKr(
          color: AppColors.ink,
          fontSize: 14,
          height: 1.7,
        ),
        bodySmall: GoogleFonts.notoSansKr(
          color: AppColors.inkLight,
          fontSize: 12,
          height: 1.6,
        ),
        labelLarge: AppType.label(color: AppColors.ink, size: 11, spacing: 5),
        labelMedium:
            AppType.label(color: AppColors.taupe, size: 10, spacing: 4),
        labelSmall: AppType.label(color: AppColors.taupe, size: 9, spacing: 3),
      ),
    );
  }
}
