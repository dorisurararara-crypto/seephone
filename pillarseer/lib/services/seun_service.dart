// Pillar Seer — 세운(歲運) 서비스.
//
// 세운: 매년의 운기 흐름. 현재 년도 60갑자가 사주 원국에 어떻게 작용하는지.
//
// 분석:
// 1. 올해의 60갑자 (예: 2024 = 甲辰)
// 2. 일간(日干) 기준 올해 천간/지지의 십신 → 운기 성격
// 3. 일주 vs 올해 합/충/형 → 변동성

import 'ten_gods_service.dart';
import '../models/saju_result.dart';

class SeunService {
  /// 양력 년도 → 60갑자 (1900 = 庚子 인덱스 36).
  static String yearGanji(int solarYear) {
    const gan = ['甲', '乙', '丙', '丁', '戊', '己', '庚', '辛', '壬', '癸'];
    const ji = ['子', '丑', '寅', '卯', '辰', '巳', '午', '未', '申', '酉', '戌', '亥'];
    final idx = ((36 + (solarYear - 1900)) % 60 + 60) % 60;
    return '${gan[idx % 10]}${ji[idx % 12]}';
  }

  /// 일간 기준 올해 천간/지지 십신 → 운기 의미.
  static ({String themeKo, String themeEn, TenGod? godGan, TenGod? godJi})
      annualTheme({
    required String dayMaster,
    required int solarYear,
  }) {
    final yg = yearGanji(solarYear);
    final ganChar = yg[0];
    final jiChar = yg[1];
    final godGan = TenGodsService.godFor(dayMaster, ganChar);
    final godJi = TenGodsService.godForJiJi(dayMaster, jiChar);

    String themeKo = '';
    String themeEn = '';
    if (godGan != null) {
      themeKo = _themeKoFor(godGan);
      themeEn = _themeEnFor(godGan);
    }
    return (themeKo: themeKo, themeEn: themeEn, godGan: godGan, godJi: godJi);
  }

  static String _themeKoFor(TenGod g) {
    switch (g) {
      case TenGod.bigyeon:
        return '비견 — 동료·경쟁자가 함께 움직이는 결.';
      case TenGod.geopjae:
        return '겁재 — 동업·재물 변동의 결. 신뢰 점검의 해.';
      case TenGod.siksin:
        return '식신 — 표현·창작이 자원이 되는 해.';
      case TenGod.sanggwan:
        return '상관 — 재능 폭발. 권위와의 마찰 조심.';
      case TenGod.pyeonjae:
        return '편재 — 큰 돈·기회. 사교의 해.';
      case TenGod.jeongjae:
        return '정재 — 안정된 수입·결혼·가정의 해.';
      case TenGod.pyeongwan:
        return '편관 — 강한 도전·승부의 결. 책임이 옵니다.';
      case TenGod.jeonggwan:
        return '정관 — 인정·승진·공직 운 좋은 해.';
      case TenGod.pyeonin:
        return '편인 — 특수 학문·외길·종교 결.';
      case TenGod.jeongin:
        return '정인 — 배움·멘토·후원의 해.';
    }
  }

  static String _themeEnFor(TenGod g) {
    switch (g) {
      case TenGod.bigyeon:
        return 'Peer — colleagues and rivals move with you.';
      case TenGod.geopjae:
        return 'Rival — partnership/wealth shifts; trust audit.';
      case TenGod.siksin:
        return 'Output — expression and creation as resource.';
      case TenGod.sanggwan:
        return 'Hurting Output — talent peak, mind authority friction.';
      case TenGod.pyeonjae:
        return 'Windfall Wealth — big money and connections.';
      case TenGod.jeongjae:
        return 'Stable Wealth — steady income, marriage, family.';
      case TenGod.pyeongwan:
        return 'Seven Killings — fierce challenge; responsibility lands.';
      case TenGod.jeonggwan:
        return 'Right Officer — recognition, promotion, civic luck.';
      case TenGod.pyeonin:
        return 'Oblique Seal — specialized study, singular path, religion.';
      case TenGod.jeongin:
        return 'Right Seal — learning, mentors, sponsorship.';
    }
  }
}
