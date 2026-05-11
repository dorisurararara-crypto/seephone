// Pillar Seer — 60일주 deep content 로더.
// 8섹션 × ko/en 콘텐츠 + 대운/세운 procedural 보강.
//
// JSON 소스: assets/data/saju_deep_slice_0_19.json, 20_39.json, 40_59.json
// 누락된 슬라이스가 있어도 fallback 으로 동작.

import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../models/saju_result.dart';

class DeepContentService {
  static Map<String, Map<String, dynamic>>? _enCache;
  static Map<String, Map<String, dynamic>>? _koCache;
  static bool _loaded = false;

  static Future<void> _ensureLoaded() async {
    if (_loaded) return;
    final en = <String, Map<String, dynamic>>{};
    final ko = <String, Map<String, dynamic>>{};
    const slices = [
      'assets/data/saju_deep_slice_0_19.json',
      'assets/data/saju_deep_slice_20_39.json',
      'assets/data/saju_deep_slice_40_59.json',
    ];
    for (final path in slices) {
      try {
        final raw = await rootBundle.loadString(path);
        final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
        for (final entry in list) {
          final ji = entry['ji60'] as String?;
          if (ji == null) continue;
          if (entry['en'] is Map) {
            en[ji] = (entry['en'] as Map).cast<String, dynamic>();
          }
          if (entry['ko'] is Map) {
            ko[ji] = (entry['ko'] as Map).cast<String, dynamic>();
          }
        }
      } catch (_) {
        // missing slice OK, fallback will cover
      }
    }
    _enCache = en;
    _koCache = ko;
    _loaded = true;
  }

  /// 8섹션 풀이 (en + ko) 빌드. 대운/세운/Lucky 는 procedural 추가.
  static Future<({DeepReading en, DeepReading ko})> buildFor({
    required String day60ji,
    required String dayMasterName,
    required String currentYearGanji,
    required int userAge,
    required String dominantElement,
    required String deficitElement,
    required Map<String, String> shortReadings,
  }) async {
    await _ensureLoaded();
    final enRaw = _enCache?[day60ji];
    final koRaw = _koCache?[day60ji];

    final en = _buildLang(
      lang: 'en',
      day60ji: day60ji,
      name: dayMasterName,
      raw: enRaw,
      shortReadings: shortReadings,
      currentYearGanji: currentYearGanji,
      userAge: userAge,
      dominant: dominantElement,
      deficit: deficitElement,
    );
    final ko = _buildLang(
      lang: 'ko',
      day60ji: day60ji,
      name: dayMasterName,
      raw: koRaw,
      shortReadings: shortReadings,
      currentYearGanji: currentYearGanji,
      userAge: userAge,
      dominant: dominantElement,
      deficit: deficitElement,
    );
    return (en: en, ko: ko);
  }

  static DeepReading _buildLang({
    required String lang,
    required String day60ji,
    required String name,
    required Map<String, dynamic>? raw,
    required Map<String, String> shortReadings,
    required String currentYearGanji,
    required int userAge,
    required String dominant,
    required String deficit,
  }) {
    final isKo = lang == 'ko';
    final dmDeep = raw?['dayMasterDeep'] as String? ??
        _fallbackDayMasterDeep(isKo, day60ji, name);
    final career = raw?['career'] as String? ??
        _expandShort(shortReadings['career'] ?? '', isKo, 'career', day60ji);
    final wealth = raw?['wealth'] as String? ??
        _expandShort(shortReadings['money'] ?? '', isKo, 'wealth', day60ji);
    final love = raw?['love'] as String? ??
        _expandShort(shortReadings['love'] ?? '', isKo, 'love', day60ji);
    final health = raw?['health'] as String? ??
        _fallbackHealth(isKo, day60ji, deficit);
    final family = raw?['family'] as String? ??
        _fallbackFamily(isKo, day60ji);
    final fame = raw?['fame'] as String? ??
        _fallbackFame(isKo, day60ji, name);
    final luckyColor = raw?['luckyColor'] as String? ??
        _luckyColorFor(isKo, dominant);
    final luckyNumber = (raw?['luckyNumber'] is int)
        ? raw!['luckyNumber'] as int
        : _luckyNumberFor(dominant);
    final luckyDirection = raw?['luckyDirection'] as String? ??
        _luckyDirectionFor(isKo, dominant);

    return DeepReading(
      dayMasterDeep: dmDeep,
      career: career,
      wealth: wealth,
      love: love,
      health: health,
      family: family,
      fame: fame,
      luckyColor: luckyColor,
      luckyNumber: luckyNumber,
      luckyDirection: luckyDirection,
      tenYearLuck: _tenYearLuck(isKo, day60ji, userAge),
      thisYear: _thisYear(isKo, day60ji, currentYearGanji),
    );
  }

  // ──────── fallback content (콘텐츠 부족 시 사용)

  static String _fallbackDayMasterDeep(bool ko, String ji, String name) {
    if (ko) {
      return '당신의 일간 $ji ($name) 은 60갑자 사이클 속에서 고유한 진동을 가집니다. '
          '$name 다운 본능은 환경의 압력을 견디며 결을 다듬는 데서 강해집니다. '
          '내면의 리듬을 따라갈 때 가장 자기다운 결과를 만듭니다. '
          '서두름보다는 결의 흐름을, 흉내보다는 본질을 따르는 사주입니다.';
    }
    return 'Your $ji day master ($name) carries a singular pulse within the '
        '60-pillar cycle. The $name nature sharpens under steady pressure, '
        'shaping its grain rather than performing identity. When you obey '
        'your inner rhythm — not market trends — your work reads as inevitable.';
  }

  static String _expandShort(String short, bool ko, String key, String ji) {
    if (short.isEmpty) {
      return ko
          ? '당신의 $ji 일주는 $key 영역에서 자기 결을 따를 때 가장 빛납니다.'
          : 'Your $ji day pillar grows in $key when you follow your native '
              'grain rather than copy strategies built for other charts.';
    }
    // existing short reading already authored — use it as-is
    return short;
  }

  static String _fallbackHealth(bool ko, String ji, String deficit) {
    const koMap = {
      '木': '간·담·근육·신경계',
      '火': '심장·소장·혈액순환',
      '土': '비위·소화·근육 피로',
      '金': '폐·대장·피부',
      '水': '신장·방광·호르몬',
    };
    const enMap = {
      '木': 'liver, gallbladder, muscles, nervous system',
      '火': 'heart, small intestine, circulation',
      '土': 'spleen, stomach, digestion, muscle fatigue',
      '金': 'lungs, large intestine, skin',
      '水': 'kidneys, bladder, hormonal axis',
    };
    final koArea = koMap[deficit] ?? '오장육부의 미세한 균형';
    final enArea = enMap[deficit] ?? 'subtle five-organ balance';
    if (ko) {
      return '$ji 의 몸은 결핍 오행($deficit)이 약속한 신호를 가장 먼저 알립니다. '
          '특히 $koArea 의 컨디션을 정기적으로 점검하세요. 작은 신호를 무시하지 않을 때 장기적인 안정이 옵니다.';
    }
    return 'Your $ji body whispers first through the deficit element ($deficit). '
        'Track $enArea regularly — what you notice early, you never have to fix late.';
  }

  static String _fallbackFamily(bool ko, String ji) {
    if (ko) {
      return '$ji 일주의 가정은 자기 정체성을 닦는 거울입니다. '
          '말보다는 함께 보내는 시간의 결이 가족 운을 만듭니다. 사랑의 형태가 표현될 때, 관계의 운도 함께 살아납니다.';
    }
    return 'Family for $ji is the soft mirror that returns your real self. '
        'Time spent together — not perfect words — composes the chord of belonging '
        'that quietly heals the rest of your chart.';
  }

  static String _fallbackFame(bool ko, String ji, String name) {
    if (ko) {
      return '$name 의 무대는 진정성에서 빛납니다. 흉내가 아닌 자신만의 결로 공개될 때, '
          '$ji 의 명예 운이 환경을 끌어옵니다. 검색량보다 깊이가 자산입니다.';
    }
    return 'The $name stage glows brightest in authenticity. When $ji shows its '
        'own grain — not a replicated formula — public energy moves toward you. '
        'Depth, not algorithm gymnastics, is the asset.';
  }

  static String _tenYearLuck(bool ko, String ji, int age) {
    final decade = (age ~/ 10) * 10;
    final next = decade + 10;
    if (ko) {
      return '현재 대운: $decade대 흐름. '
          '이번 10년은 $ji 의 깊이가 외부에 인정받기 시작하는 게이트입니다. '
          '특히 ${next - 3}~${next - 1}살 구간이 대운 정점에 가깝습니다. '
          '대운은 주(週)가 아니라 10년 단위 흐름으로 읽어야 합니다.';
    }
    final nextEnd = next - 1;
    return 'Current 大運 window: your $decade-decade. '
        'This is the gate where $ji depth becomes externally legible. '
        'The years between $age and $nextEnd tend to compound — '
        'read this decade as one continuous breath, not isolated months.';
  }

  static String _thisYear(bool ko, String ji, String yearGanji) {
    if (ko) {
      return '올해 세운: $yearGanji. '
          '$ji 의 일간이 $yearGanji 환경 속에서 어떤 색으로 발현될지가 올해의 주제입니다. '
          '여름 ~ 가을 구간에 변동성이 가장 크고, 봄에 심은 결이 가을에 거두어집니다. '
          '한 해의 결정은 절기(節氣) 기준 입춘부터 한 사이클입니다.';
    }
    return "This year (歲運): $yearGanji. "
        'The theme is how your $ji day master expresses inside $yearGanji '
        'energy. Volatility is highest mid-summer through autumn, while the '
        'grain you set in spring compounds by harvest. The annual cycle '
        'begins at 立春 — not January 1st.';
  }

  static String _luckyColorFor(bool ko, String element) {
    const koMap = {
      '木': '심해 청록',
      '火': '주작 진홍',
      '土': '고대 황금',
      '金': '월광 은백',
      '水': '심해 청남',
    };
    const enMap = {
      '木': 'Forest Jade',
      '火': 'Phoenix Red',
      '土': 'Ancient Bronze',
      '金': 'Lunar Silver',
      '水': 'Deep Ocean Blue',
    };
    return (ko ? koMap[element] : enMap[element]) ?? (ko ? '천상의 금빛' : 'Celestial Gold');
  }

  static int _luckyNumberFor(String element) {
    const map = {'木': 3, '火': 7, '土': 5, '金': 9, '水': 1};
    return map[element] ?? 7;
  }

  static String _luckyDirectionFor(bool ko, String element) {
    const koMap = {'木': '동', '火': '남', '土': '중앙', '金': '서', '水': '북'};
    const enMap = {
      '木': 'East', '火': 'South', '土': 'Center', '金': 'West', '水': 'North',
    };
    return (ko ? koMap[element] : enMap[element]) ?? (ko ? '동' : 'East');
  }

  /// 현재 연도의 60갑자 (1900년 庚子 기준)
  static String currentYearGanji([DateTime? now]) {
    final t = now ?? DateTime.now();
    int adjustedYear = t.year;
    // 입춘(2월 4일) 이전이면 전년도 처리
    if (t.month < 2 || (t.month == 2 && t.day < 4)) {
      adjustedYear -= 1;
    }
    const chunGan = ['庚', '辛', '壬', '癸', '甲', '乙', '丙', '丁', '戊', '己'];
    const jiJi = ['子', '丑', '寅', '卯', '辰', '巳', '午', '未', '申', '酉', '戌', '亥'];
    final offset = adjustedYear - 1900;
    final gIdx = ((offset % 10) + 10) % 10;
    final jIdx = ((offset % 12) + 12) % 12;
    return '${chunGan[gIdx]}${jiJi[jIdx]}';
  }
}
