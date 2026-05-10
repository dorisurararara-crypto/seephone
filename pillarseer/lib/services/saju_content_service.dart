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

  /// summary 한 줄 (없으면 fallback)
  static Future<String> summaryFor(String ji60) async {
    final entry = await findByJi60(ji60);
    return entry?['summary'] as String? ??
        'Your destiny carries the rhythm of $ji60 — ancient, specific, yours alone.';
  }

  /// 카테고리별 readings (personality / love / money / career)
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
