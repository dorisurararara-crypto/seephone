// Pillar Seer — Round 106 (P1) — 로컬 자기검증 피드백 서비스.
//
// R106 design doc §4-D / §4-E / §4-F ground truth:
//  - 저장소 = SharedPreferences 로컬 only. 서버 전송 0.
//  - 자기검증 점수: 맞았어요 +1 / 애매해요 -1 / 아니에요 -3.
//  - shownCount >= 3 && score < 0 인 주제 → 14일 cooldown suppress.
//  - cooldown 지나면 다시 eligible.
//  - 추가 추적 신호(알림 탭 / 스크롤 깊이 / 자주 여는 메뉴 / 푸는 시간대)를
//    로컬 2주 슬라이딩 윈도우로 저장하는 최소 API 를 열어둠. 오래된 기록 prune.
//  - resetPersonalization() 으로 개인화 데이터 전체 초기화 가능 (§10).
//
// 본 sprint 는 core service + tests 만. UI 변경 0.
// 계산 엔진 (DailyService / TenGods / Gyeokguk / Yongsin / Shinsa / Hapchung) 은
// 1 bit 도 건드리지 않는다.

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// 자기검증 응답 3종 — design doc §7 버튼 3개와 1:1.
enum RecallVerdict {
  correct, // 맞았어요  → +1
  unsure, // 애매해요  → -1
  wrong, // 아니에요  → -3
}

extension RecallVerdictScore on RecallVerdict {
  /// design doc §4-D 점수표 — 절대 변경 금지.
  int get scoreDelta {
    switch (this) {
      case RecallVerdict.correct:
        return 1;
      case RecallVerdict.unsure:
        return -1;
      case RecallVerdict.wrong:
        return -3;
    }
  }
}

/// 추가 추적 신호 종류 — design doc §4-F. 로컬 2주 윈도우.
/// userPref 보강용 보조 신호. 이번 sprint 는 저장 API 만 — UI/소비는 P2+ 위임.
enum TrackingSignalKind {
  notificationTap, // 알림 탭 여부
  sectionScrollDepth, // 섹션 스크롤 깊이
  menuOpen, // 자주 여는 메뉴
  appOpenHour, // 앱을 푸는 시간대
}

extension TrackingSignalKindKey on TrackingSignalKind {
  String get key {
    switch (this) {
      case TrackingSignalKind.notificationTap:
        return 'notificationTap';
      case TrackingSignalKind.sectionScrollDepth:
        return 'sectionScrollDepth';
      case TrackingSignalKind.menuOpen:
        return 'menuOpen';
      case TrackingSignalKind.appOpenHour:
        return 'appOpenHour';
    }
  }
}

/// 주제별 누적 피드백 상태 (읽기 전용 snapshot).
class TopicFeedbackState {
  /// 주제 id (R106 10 주제 string 중 하나).
  final String topic;

  /// 자기검증 누적 점수 (+1 / -1 / -3 합산).
  final int score;

  /// 해당 주제가 사용자에게 노출된 횟수.
  final int shownCount;

  /// 마지막 노출 일자 (yyyy-MM-dd). 없으면 null.
  final DateTime? lastShown;

  /// suppress cooldown 종료 일자. 없으면 null (= cooldown 아님).
  final DateTime? cooldownUntil;

  const TopicFeedbackState({
    required this.topic,
    this.score = 0,
    this.shownCount = 0,
    this.lastShown,
    this.cooldownUntil,
  });

  TopicFeedbackState copyWith({
    int? score,
    int? shownCount,
    DateTime? lastShown,
    DateTime? cooldownUntil,
    bool clearCooldown = false,
  }) {
    return TopicFeedbackState(
      topic: topic,
      score: score ?? this.score,
      shownCount: shownCount ?? this.shownCount,
      lastShown: lastShown ?? this.lastShown,
      cooldownUntil: clearCooldown ? null : (cooldownUntil ?? this.cooldownUntil),
    );
  }
}

/// 추가 추적 신호 한 건 (로컬 2주 윈도우 저장 단위).
class TrackingSignalEntry {
  final TrackingSignalKind kind;

  /// 신호 발생 일시 (윈도우 prune 기준).
  final DateTime at;

  /// 신호별 페이로드 — 메뉴 id / 섹션 깊이 / 시간대 등. 자유 string.
  final String value;

  const TrackingSignalEntry({
    required this.kind,
    required this.at,
    this.value = '',
  });

  Map<String, dynamic> _toJson() => {
        'k': kind.key,
        't': at.toUtc().millisecondsSinceEpoch,
        'v': value,
      };

  static TrackingSignalEntry? _fromJson(Map<String, dynamic> j) {
    final kStr = j['k'] as String?;
    final tMs = j['t'] as int?;
    if (kStr == null || tMs == null) return null;
    TrackingSignalKind? kind;
    for (final candidate in TrackingSignalKind.values) {
      if (candidate.key == kStr) {
        kind = candidate;
        break;
      }
    }
    if (kind == null) return null;
    return TrackingSignalEntry(
      kind: kind,
      at: DateTime.fromMillisecondsSinceEpoch(tMs, isUtc: true).toLocal(),
      value: (j['v'] as String?) ?? '',
    );
  }
}

/// 로컬 자기검증 피드백 서비스 — SharedPreferences only.
class RecallFeedbackService {
  /// design doc §4-D — 버린 주제 14일 cooldown. 절대 줄이지 않는다.
  static const int cooldownDays = 14;

  /// design doc §4-D — 전환 트리거 노출 최소 횟수.
  static const int suppressMinShown = 3;

  /// design doc §4-F — 추가 추적 신호 슬라이딩 윈도우 (일).
  static const int trackingWindowDays = 14;

  /// userPref 계산 시 점수 한계 — 한쪽으로 무한히 쏠리지 않게 clamp.
  /// finalScore component 는 0~1 double 이어야 하므로 normalize 기준값.
  static const int _prefScoreCap = 9;

  // ── SharedPreferences key ──
  static const _kScorePrefix = 'r106.topic.score.';
  static const _kShownPrefix = 'r106.topic.shown.';
  static const _kLastShownPrefix = 'r106.topic.lastshown.';
  static const _kCooldownPrefix = 'r106.topic.cooldown.';
  static const _kTracking = 'r106.tracking.signals';
  // R106 P2a-fix #5 — "마지막으로 노출된 topic + date" 단일 슬롯.
  // 자기검증 카드가 *어제 본 풀이* 에 feedback 을 기록하기 위한 anchor.
  static const _kLastReadingTopic = 'r106.lastreading.topic';
  static const _kLastReadingDate = 'r106.lastreading.date';
  // 본 서비스가 쓴 모든 키 prefix — resetPersonalization 일괄 삭제용.
  static const List<String> _allKeyPrefixes = [
    _kScorePrefix,
    _kShownPrefix,
    _kLastShownPrefix,
    _kCooldownPrefix,
  ];
  // resetPersonalization 일괄 삭제 대상 단일 키.
  static const List<String> _allSingleKeys = [
    _kTracking,
    _kLastReadingTopic,
    _kLastReadingDate,
  ];

  static String _ymd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  static DateTime? _parseYmd(String? s) {
    if (s == null || s.isEmpty) return null;
    final parts = s.split('-');
    if (parts.length != 3) return null;
    final y = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    final d = int.tryParse(parts[2]);
    if (y == null || m == null || d == null) return null;
    return DateTime(y, m, d);
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  /// 주제별 현재 누적 상태 읽기.
  static Future<TopicFeedbackState> stateOf(String topic) async {
    final prefs = await SharedPreferences.getInstance();
    return TopicFeedbackState(
      topic: topic,
      score: prefs.getInt('$_kScorePrefix$topic') ?? 0,
      shownCount: prefs.getInt('$_kShownPrefix$topic') ?? 0,
      lastShown: _parseYmd(prefs.getString('$_kLastShownPrefix$topic')),
      cooldownUntil: _parseYmd(prefs.getString('$_kCooldownPrefix$topic')),
    );
  }

  /// 자기검증 응답 기록 — 점수 누적 + suppress cooldown 진입 판정.
  /// shownCount >= suppressMinShown && score < 0 → cooldownUntil = today+14d.
  /// score 가 다시 0 이상으로 회복하면 cooldown 해제.
  static Future<TopicFeedbackState> recordFeedback(
    String topic,
    RecallVerdict verdict, {
    DateTime? date,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final today = _dateOnly(date ?? DateTime.now());
    final newScore =
        (prefs.getInt('$_kScorePrefix$topic') ?? 0) + verdict.scoreDelta;
    final shown = prefs.getInt('$_kShownPrefix$topic') ?? 0;
    await prefs.setInt('$_kScorePrefix$topic', newScore);

    final shouldSuppress = shown >= suppressMinShown && newScore < 0;
    if (shouldSuppress) {
      final until = today.add(const Duration(days: cooldownDays));
      await prefs.setString('$_kCooldownPrefix$topic', _ymd(until));
    } else if (newScore >= 0) {
      // 점수 회복 → cooldown 해제.
      await prefs.remove('$_kCooldownPrefix$topic');
    }
    return stateOf(topic);
  }

  /// 주제 노출 기록 — shownCount +1, lastShown 갱신.
  /// 같은 날 중복 호출돼도 노출 1회로 본다 (lastShown 동일일 → shownCount 미증가).
  ///
  /// R106 P2a-fix #5 — 노출 시 "마지막 노출 topic + date" 단일 슬롯도 갱신한다.
  /// 다음 날 자기검증 카드가 이 슬롯을 읽어 *어제 본 풀이* 에 feedback 을 건다.
  /// shownCount 증가 여부와 무관하게 매번 갱신 (그 날 마지막으로 본 topic 이 기준).
  static Future<void> recordShown(String topic, DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    final today = _dateOnly(date);
    final last = _parseYmd(prefs.getString('$_kLastShownPrefix$topic'));
    // "마지막 노출 풀이" 슬롯 — count 고정 여부와 무관하게 항상 갱신.
    await prefs.setString(_kLastReadingTopic, topic);
    await prefs.setString(_kLastReadingDate, _ymd(today));
    if (last != null && last == today) {
      return; // 같은 날 이미 노출 — count 고정.
    }
    final shown = prefs.getInt('$_kShownPrefix$topic') ?? 0;
    await prefs.setInt('$_kShownPrefix$topic', shown + 1);
    await prefs.setString('$_kLastShownPrefix$topic', _ymd(today));
  }

  /// R106 P2a-fix #5 — 직전에 노출된 풀이 (topic + date).
  /// 자기검증 카드가 "어제 본 풀이" 를 찾는 데 쓴다. 기록 없으면 null.
  static Future<({String topic, DateTime date})?> lastReading() async {
    final prefs = await SharedPreferences.getInstance();
    final topic = prefs.getString(_kLastReadingTopic);
    final date = _parseYmd(prefs.getString(_kLastReadingDate));
    if (topic == null || topic.isEmpty || date == null) return null;
    return (topic: topic, date: date);
  }

  /// 해당 주제가 [date] 기준 suppress (cooldown 중) 인지.
  /// cooldownUntil 이 date 보다 미래면 suppress. date >= cooldownUntil 이면 다시 eligible.
  static Future<bool> isSuppressed(String topic, DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    final until = _parseYmd(prefs.getString('$_kCooldownPrefix$topic'));
    if (until == null) return false;
    final today = _dateOnly(date);
    if (!today.isBefore(until)) {
      // cooldown 만료 — 키 정리 후 eligible.
      await prefs.remove('$_kCooldownPrefix$topic');
      return false;
    }
    return true;
  }

  /// 사용자 선호도 0.0~1.0 — finalScore 의 userPref component.
  /// 누적 score 를 [-cap, +cap] clamp 후 0~1 로 normalize. 기록 없으면 중립 0.5.
  static Future<double> userPref(String topic) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getInt('$_kScorePrefix$topic');
    return userPrefFromScore(raw ?? 0);
  }

  /// pure — 점수 → userPref. 테스트·selector deterministic 검증 공용.
  static double userPrefFromScore(int score) {
    final clamped = score.clamp(-_prefScoreCap, _prefScoreCap).toDouble();
    return (clamped + _prefScoreCap) / (2 * _prefScoreCap);
  }

  // ── 추가 추적 신호 (design doc §4-F) ──

  /// 추적 신호 1건 기록 + 2주 윈도우 밖 prune.
  static Future<void> recordTrackingSignal(
    TrackingSignalKind kind, {
    String value = '',
    DateTime? at,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final now = at ?? DateTime.now();
    final list = _readTracking(prefs)
      ..add(TrackingSignalEntry(kind: kind, at: now, value: value));
    final pruned = _pruneTracking(list, now);
    await prefs.setString(
      _kTracking,
      jsonEncode(pruned.map((e) => e._toJson()).toList()),
    );
  }

  /// 현재 윈도우 안의 추적 신호 — [now] 기준 14일 이내만. prune 후 반환.
  static Future<List<TrackingSignalEntry>> trackingSignals({
    DateTime? now,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final ref = now ?? DateTime.now();
    final pruned = _pruneTracking(_readTracking(prefs), ref);
    // 읽기 시점에도 prune 결과를 영속화해 기록이 무한히 자라지 않게 한다.
    await prefs.setString(
      _kTracking,
      jsonEncode(pruned.map((e) => e._toJson()).toList()),
    );
    return pruned;
  }

  static List<TrackingSignalEntry> _readTracking(SharedPreferences prefs) {
    final raw = prefs.getString(_kTracking);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      final out = <TrackingSignalEntry>[];
      for (final e in decoded) {
        if (e is Map) {
          final entry =
              TrackingSignalEntry._fromJson(e.cast<String, dynamic>());
          if (entry != null) out.add(entry);
        }
      }
      return out;
    } catch (_) {
      return [];
    }
  }

  static List<TrackingSignalEntry> _pruneTracking(
    List<TrackingSignalEntry> list,
    DateTime now,
  ) {
    final cutoff = now.subtract(const Duration(days: trackingWindowDays));
    return list.where((e) => e.at.isAfter(cutoff)).toList();
  }

  /// 개인화 데이터 전체 초기화 — design doc §10.
  /// 자기검증 점수 / 노출 기록 / cooldown / 추적 신호 모두 삭제.
  static Future<void> resetPersonalization() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().toList();
    for (final k in keys) {
      final isTopicKey =
          _allKeyPrefixes.any((prefix) => k.startsWith(prefix));
      if (isTopicKey || _allSingleKeys.contains(k)) {
        await prefs.remove(k);
      }
    }
  }
}
