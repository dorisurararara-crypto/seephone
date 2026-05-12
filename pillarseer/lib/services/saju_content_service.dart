import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

/// SajuContentService — `assets/data/saju_60ji.json` 로더 + 캐시
///
/// 60일주(60 갑자) × {summary, personality, love, money, career} 콘텐츠 제공.
/// JSON 형식: List<{index, ji60, name, summary, personality, love, money, career}>
class SajuContentService {
  static List<Map<String, dynamic>>? _cached;

  /// 콘텐츠 lazy load + 메모리 캐시
  static Future<List<Map<String, dynamic>>> load() async {
    if (_cached != null) return _cached!;
    final raw = await rootBundle.loadString('assets/data/saju_60ji.json');
    _cached = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    return _cached!;
  }

  /// 60갑자 텍스트(예: "戊寅")로 entry 검색
  static Future<Map<String, dynamic>?> findByJi60(String ji60) async {
    final list = await load();
    try {
      return list.firstWhere((e) => e['ji60'] == ji60);
    } catch (_) {
      return null;
    }
  }

  /// summary 한 줄 (없으면 locale fallback).
  /// [useKo] true 면 한국어 fallback, false 면 영어.
  static Future<String> summaryFor(String ji60, {bool useKo = false}) async {
    final entry = await findByJi60(ji60);
    final raw = entry?['summary'] as String?;
    if (raw != null && raw.isNotEmpty) return raw;
    return useKo
        ? '$ji60 일주는 정통 명리학 기준에서 매우 구체적인 결을 가집니다.'
        : 'Your destiny carries the rhythm of $ji60 — ancient, specific, yours alone.';
  }

  /// 카테고리별 readings (personality / love / money / career)
  /// JSON 콘텐츠는 영어. Korean 모드는 deep_content_service 의 readings 를 우선 사용.
  static Future<Map<String, String>> readingsFor(String ji60) async {
    final entry = await findByJi60(ji60);
    if (entry == null) {
      return {
        'personality': 'Your $ji60 day pillar carries an ancient signature.',
        'love': 'Love arrives slowly for $ji60 — beginning in depth.',
        'money': 'Wealth flows toward $ji60 when rooted in essence.',
        'career': '$ji60 thrives where five-element balance expresses itself.',
      };
    }
    return {
      'personality': entry['personality'] as String? ?? '',
      'love': entry['love'] as String? ?? '',
      'money': entry['money'] as String? ?? '',
      'career': entry['career'] as String? ?? '',
    };
  }
}
