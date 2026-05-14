// Pillar Seer — 8글자 십신 인격 풀이 서비스 (Round 73 Sprint 3).
//
// TenGodsService.tableFor(saju) 결과 → 8 십신 분포 → 빈도 (1·2·3+) × 4 카테고리
// (persona / career / wealth / love) phrase array 반환.
//
// 8글자 십신 분포 기반 차별화 — 같은 60갑자 일주 + 다른 천간/지지 사주 두 명
// = phrase ≥30% 차별 (Jaccard distance).
//
// 60갑자 base (saju_deep_slice) 톤 위에 십신 변주 phrase 결합 — 본문은
// _ReadingSection / _DayMasterHero 에서 사용.

import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

import '../models/saju_result.dart';
import 'ten_gods_service.dart';

class SipsinPersonaReading {
  /// 카테고리 별 (persona / career / wealth / love) ko phrase.
  final Map<String, String> ko;

  /// 카테고리 별 en phrase.
  final Map<String, String> en;

  /// 가장 강한 (3+) 십신 (디버깅용).
  final TenGod? dominantSipsin;

  /// 두 번째 강한 십신 (디버깅용).
  final TenGod? secondarySipsin;

  /// 8글자 십신 빈도 분포 (key = TenGod, value = 1~8).
  final Map<TenGod, int> freq;

  const SipsinPersonaReading({
    required this.ko,
    required this.en,
    required this.freq,
    this.dominantSipsin,
    this.secondarySipsin,
  });
}

class SipsinPersonaService {
  static const _path = 'assets/data/sipsin_persona.json';
  static Map<String, dynamic>? _cache;

  /// 4 카테고리 — UI 라벨용.
  static const categories = ['persona', 'career', 'wealth', 'love'];

  /// 한글 라벨 (카테고리 → 한국어).
  static const labelKo = {
    'persona': '성격',
    'career': '진로',
    'wealth': '돈',
    'love': '연애',
  };

  /// 영문 라벨.
  static const labelEn = {
    'persona': 'NATURE',
    'career': 'PATH',
    'wealth': 'WEALTH',
    'love': 'LOVE',
  };

  /// JSON lazy load.
  static Future<Map<String, dynamic>> _pool() async {
    if (_cache != null) return _cache!;
    final raw = await rootBundle.loadString(_path);
    _cache = json.decode(raw) as Map<String, dynamic>;
    return _cache!;
  }

  /// 테스트 주입용.
  static void seedForTest(Map<String, dynamic> map) {
    _cache = map;
  }

  /// 사주 → 십신 인격 풀이.
  static Future<SipsinPersonaReading> compute(SajuResult saju) async {
    final pool = await _pool();

    // 1) TenGodsService.tableFor → 8 십신 분포
    final table = TenGodsService.tableFor(saju);
    final freq = <TenGod, int>{};
    for (final row in table) {
      if (row.chunGanGod != null) {
        freq[row.chunGanGod!] = (freq[row.chunGanGod!] ?? 0) + 1;
      }
      if (row.jiJiGod != null) {
        freq[row.jiJiGod!] = (freq[row.jiJiGod!] ?? 0) + 1;
      }
    }

    if (freq.isEmpty) {
      return SipsinPersonaReading(
        ko: const {
          'persona': '본인 사주는 흔치 않은 분포예요.',
          'career': '본인 길은 본인이 정해가는 쪽이에요.',
          'wealth': '돈은 천천히 모으는 쪽이에요.',
          'love': '인연은 본인이 어떤 사람인지 또렷해진 다음에 와요.',
        },
        en: const {
          'persona': 'Your chart carries a rare distribution.',
          'career': 'You define your own path.',
          'wealth': 'Money gathers slowly for you.',
          'love': 'Love arrives once you know who you are.',
        },
        freq: freq,
      );
    }

    // 2) 상위 2개 십신 선출
    final sorted = freq.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final dom = sorted.first.key;
    final sec = sorted.length > 1 ? sorted[1].key : null;

    // 3) 빈도 키 결정 (1 / 2 / 3+)
    String freqKey(int count) {
      if (count >= 3) return '3+';
      if (count == 2) return '2';
      return '1';
    }

    // 4) 카테고리 별 phrase fetch — 카테고리 별 적절한 십신 매핑.
    String? entryKo(TenGod g, String fk, String cat) {
      final key = '${_sipsinKey(g)}_${fk}_$cat';
      final e = pool[key] as Map<String, dynamic>?;
      return e?['ko'] as String?;
    }

    String? entryEn(TenGod g, String fk, String cat) {
      final key = '${_sipsinKey(g)}_${fk}_$cat';
      final e = pool[key] as Map<String, dynamic>?;
      return e?['en'] as String?;
    }

    String fallback(String cat) {
      return cat == 'persona'
          ? '본인 사주는 균형 잡힌 분포예요.'
          : cat == 'career'
          ? '본인은 본인 길을 찾아가는 사람이에요.'
          : cat == 'wealth'
          ? '돈은 천천히 모이는 쪽이에요.'
          : '인연은 본인 색이 또렷해진 뒤에 와요.';
    }

    String fallbackEn(String cat) {
      return cat == 'persona'
          ? 'Your chart sits in balance.'
          : cat == 'career'
          ? 'You define your own road.'
          : cat == 'wealth'
          ? 'Money builds slowly.'
          : 'Love arrives once you know who you are.';
    }

    // 카테고리 별 십신 매핑 — 단조로움 차단:
    //   persona = dominant (가장 강한 십신)
    //   career  = 일·관련 십신 우선 (jeonggwan/pyeongwan/sanggwan/siksin) → fallback dom
    //   wealth  = 재성 우선 (pyeonjae/jeongjae) → fallback dom
    //   love    = 인성/관성 우선 (jeongin/pyeonin/jeonggwan/pyeongwan) → fallback secondary → dom
    // 같은 dom 두 사주여도 secondary/카테고리 매핑으로 phrase 차별이 나옴.
    TenGod resolveFor(String cat) {
      final priorities = <String, List<TenGod>>{
        'career': const [
          TenGod.jeonggwan,
          TenGod.pyeongwan,
          TenGod.sanggwan,
          TenGod.siksin,
        ],
        'wealth': const [TenGod.pyeonjae, TenGod.jeongjae],
        'love': const [
          TenGod.jeongin,
          TenGod.pyeonin,
          TenGod.jeonggwan,
          TenGod.pyeongwan,
        ],
        'persona': const [],
      };
      final pri = priorities[cat] ?? const <TenGod>[];
      // pri 안에 빈도 ≥1 인 십신 중 최고 빈도 선택
      TenGod? best;
      int bestFreq = 0;
      for (final g in pri) {
        final c = freq[g] ?? 0;
        if (c > bestFreq) {
          best = g;
          bestFreq = c;
        }
      }
      // 우선순위 매칭 X 또는 persona 면 dominant 사용
      return best ?? dom;
    }

    final ko = <String, String>{};
    final en = <String, String>{};
    for (final cat in categories) {
      final g = resolveFor(cat);
      final gFreq = freqKey(freq[g] ?? 1);

      var koPhrase = entryKo(g, gFreq, cat);
      var enPhrase = entryEn(g, gFreq, cat);
      // fallback 1: 같은 십신 다른 freq
      if (koPhrase == null) {
        for (final fk in ['3+', '2', '1']) {
          if (fk == gFreq) continue;
          koPhrase = entryKo(g, fk, cat);
          enPhrase = entryEn(g, fk, cat);
          if (koPhrase != null) break;
        }
      }
      // fallback 2: secondary (dom 우선)
      if (koPhrase == null && sec != null) {
        final secFreq = freqKey(sorted[1].value);
        koPhrase = entryKo(sec, secFreq, cat);
        enPhrase = entryEn(sec, secFreq, cat);
      }
      // fallback 3: hardcoded
      ko[cat] = koPhrase ?? fallback(cat);
      en[cat] = enPhrase ?? fallbackEn(cat);
    }

    return SipsinPersonaReading(
      ko: ko,
      en: en,
      freq: freq,
      dominantSipsin: dom,
      secondarySipsin: sec,
    );
  }

  static String _sipsinKey(TenGod g) {
    switch (g) {
      case TenGod.bigyeon:
        return 'bigyeon';
      case TenGod.geopjae:
        return 'geopjae';
      case TenGod.siksin:
        return 'siksin';
      case TenGod.sanggwan:
        return 'sanggwan';
      case TenGod.pyeonjae:
        return 'pyeonjae';
      case TenGod.jeongjae:
        return 'jeongjae';
      case TenGod.pyeongwan:
        return 'pyeongwan';
      case TenGod.jeonggwan:
        return 'jeonggwan';
      case TenGod.pyeonin:
        return 'pyeonin';
      case TenGod.jeongin:
        return 'jeongin';
    }
  }
}
