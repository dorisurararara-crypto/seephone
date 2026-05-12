import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Background
  static const midnightPurple = Color(0xFF1A0B2E);
  static const cosmicBlack = Color(0xFF0A0612);

  // Accent (Round 14 tone-down: gold 은 CTA + 핵심 숫자만)
  static const celestialGold = Color(0xFFD4AF37);
  static const spiritIndigo = Color(0xFF311B92);
  static const mysticViolet = Color(0xFF6B46C1);

  // Text / surface (한국어 가독성)
  static const ghostlyWhite = Color(0xFFF5F5F5);
  static const moonlightGray = Color(0xFFA8A8C0);
  static const fadedSilver = Color(0xFF6B6B82);

  // Round 14: 차분한 carded surface (gold 대신 사용)
  static const cardSurface = Color(0xFF1F1430);
  static const cardBorder = Color(0xFF2D2148);
  static const cardBorderStrong = Color(0xFF4A3974);

  // Element Colors (Wood/Fire/Earth/Metal/Water)
  static const woodJade = Color(0xFF27AE60);
  static const fireRed = Color(0xFFE74C3C);
  static const earthBronze = Color(0xFFC19A6B);
  static const metalSilver = Color(0xFFBDC3C7);
  static const waterOcean = Color(0xFF2980B9);

  /// 5행 → 색상 매핑
  static Color forElement(String element) {
    switch (element) {
      case '木': case 'Wood': return woodJade;
      case '火': case 'Fire': return fireRed;
      case '土': case 'Earth': return earthBronze;
      case '金': case 'Metal': return metalSilver;
      case '水': case 'Water': return waterOcean;
      default: return celestialGold;
    }
  }
}

class AppTheme {
  static ThemeData get darkTheme {
    // 한국어 가독성 향상 — NotoSansKR 우선 (Pretendard 비슷한 무게감).
    final koTextTheme = GoogleFonts.notoSansKrTextTheme(
      const TextTheme(
        bodyMedium: TextStyle(color: AppColors.ghostlyWhite, fontSize: 14),
        bodyLarge: TextStyle(color: AppColors.ghostlyWhite, fontSize: 15),
      ),
    );
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.cosmicBlack,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.celestialGold,
        secondary: AppColors.mysticViolet,
        surface: AppColors.midnightPurple,
        onSurface: AppColors.ghostlyWhite,
      ),
      textTheme: koTextTheme.copyWith(
        // 브랜드/제목만 serif (Playfair) — 본문은 한국어 우선
        displayLarge: GoogleFonts.playfairDisplay(
          fontSize: 36,
          fontWeight: FontWeight.bold,
          color: AppColors.ghostlyWhite,
        ),
        headlineMedium: GoogleFonts.playfairDisplay(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: AppColors.celestialGold,
        ),
      ),
    );
  }
}
