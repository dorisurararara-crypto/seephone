import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// 사용자가 과거 던졌던 질문 로컬 저장소.
///
/// SharedPreferences 에 JSON 배열로 저장. 30일 TTL 로 자동 정리.
/// 같은/유사한 질문이 들어오면 "또 그 질문이냐" 멘트 트리거 신호.
class QuestionHistory {
  static const _kKey = 'bbaksin_question_history';
  static const _kTtl = Duration(days: 30);
  static const _kMaxEntries = 200;

  /// 과거 질문 목록 로드 (TTL 지난 건 정리됨).
  static Future<List<_Entry>> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = (jsonDecode(raw) as List)
          .map((e) => _Entry.fromJson(e as Map<String, dynamic>))
          .toList();
      final cutoff = DateTime.now().subtract(_kTtl);
      return list.where((e) => e.at.isAfter(cutoff)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> _save(List<_Entry> entries) async {
    final prefs = await SharedPreferences.getInstance();
    final trimmed = entries.length > _kMaxEntries
        ? entries.sublist(entries.length - _kMaxEntries)
        : entries;
    await prefs.setString(
        _kKey, jsonEncode(trimmed.map((e) => e.toJson()).toList()));
  }

  /// 새 질문이 과거 질문과 유사한지 검사. 유사하면 true.
  ///
  /// 유사도 = 추출된 키워드 (2글자 이상 단어) 의 50%+ 겹침
  /// 또는 첫 6글자 동일.
  static Future<bool> isRepeat(String question) async {
    final entries = await _load();
    if (entries.isEmpty) return false;
    final newKeys = _extractKeywords(question);
    if (newKeys.isEmpty) return false;
    for (final e in entries) {
      // 첫 6자 같으면 즉시 repeat
      final n = question.replaceAll(' ', '');
      final p = e.q.replaceAll(' ', '');
      if (n.length >= 6 && p.length >= 6 && n.substring(0, 6) == p.substring(0, 6)) {
        return true;
      }
      final pastKeys = _extractKeywords(e.q);
      if (pastKeys.isEmpty) continue;
      final common = newKeys.intersection(pastKeys).length;
      final smaller = newKeys.length < pastKeys.length ? newKeys.length : pastKeys.length;
      if (smaller > 0 && common / smaller >= 0.5) {
        return true;
      }
    }
    return false;
  }

  /// 새 질문 기록.
  static Future<void> record(String question) async {
    final entries = await _load();
    entries.add(_Entry(q: question.trim(), at: DateTime.now()));
    await _save(entries);
  }

  static Set<String> _extractKeywords(String text) {
    final cleaned = text
        .replaceAll(RegExp(r'[?!.,~\s]'), ' ')
        .toLowerCase();
    return cleaned
        .split(RegExp(r'\s+'))
        .where((w) => w.length >= 2)
        .toSet();
  }
}

class _Entry {
  final String q;
  final DateTime at;
  const _Entry({required this.q, required this.at});

  Map<String, dynamic> toJson() => {'q': q, 'at': at.millisecondsSinceEpoch};

  factory _Entry.fromJson(Map<String, dynamic> j) => _Entry(
        q: j['q'] as String,
        at: DateTime.fromMillisecondsSinceEpoch(j['at'] as int),
      );
}
