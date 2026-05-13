// Pillar Seer — 추가 6 섹션 서비스 (Round 73 Sprint 4).
//
// 운세의신 17 섹션 중 미커버 6 섹션:
//   건강운 / 체질운 / 사회운 / 사회적성격 / 타고난성향 / 타고난인품
//
// 입력: 사주 5행 dominant (saju.elements.dominant)
// 출력: 6 paragraph (ko/en)

import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

import '../models/saju_result.dart';

class AdditionalLifeReading {
  final String healthKo;
  final String healthEn;
  final String bodyKo;
  final String bodyEn;
  final String socialKo;
  final String socialEn;
  final String socialPersonaKo;
  final String socialPersonaEn;
  final String innateNatureKo;
  final String innateNatureEn;
  final String innateCharacterKo;
  final String innateCharacterEn;

  /// dominant 5행 (디버깅용).
  final String dominantEl;

  const AdditionalLifeReading({
    required this.healthKo,
    required this.healthEn,
    required this.bodyKo,
    required this.bodyEn,
    required this.socialKo,
    required this.socialEn,
    required this.socialPersonaKo,
    required this.socialPersonaEn,
    required this.innateNatureKo,
    required this.innateNatureEn,
    required this.innateCharacterKo,
    required this.innateCharacterEn,
    required this.dominantEl,
  });
}

class AdditionalLifeService {
  static const _path = 'assets/data/additional_life_pool.json';
  static Map<String, dynamic>? _cache;

  static Future<Map<String, dynamic>> _pool() async {
    if (_cache != null) return _cache!;
    final raw = await rootBundle.loadString(_path);
    _cache = json.decode(raw) as Map<String, dynamic>;
    return _cache!;
  }

  static void seedForTest(Map<String, dynamic> map) {
    _cache = map;
  }

  /// 사주 → 6 추가 paragraph.
  static Future<AdditionalLifeReading> compute(SajuResult saju) async {
    final pool = await _pool();
    final dom = saju.elements.dominant;
    final entry = (pool[dom] as Map<String, dynamic>?) ??
        (pool['土'] as Map<String, dynamic>); // fallback 土

    return AdditionalLifeReading(
      healthKo: entry['healthKo'] as String,
      healthEn: entry['healthEn'] as String,
      bodyKo: entry['bodyKo'] as String,
      bodyEn: entry['bodyEn'] as String,
      socialKo: entry['socialKo'] as String,
      socialEn: entry['socialEn'] as String,
      socialPersonaKo: entry['socialPersonaKo'] as String,
      socialPersonaEn: entry['socialPersonaEn'] as String,
      innateNatureKo: entry['innateNatureKo'] as String,
      innateNatureEn: entry['innateNatureEn'] as String,
      innateCharacterKo: entry['innateCharacterKo'] as String,
      innateCharacterEn: entry['innateCharacterEn'] as String,
      dominantEl: dom,
    );
  }
}
