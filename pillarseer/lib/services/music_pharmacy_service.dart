// Pillar Seer — 디지털 기운 처방전 서비스 (R101 sprint 6, 팬심 2순위).
//
// 입력: 사용자 SajuResult (+ 옵션 userName, seed).
// 출력: MusicPrescription — 부족한 5행 + 그 5행 셀럽 1명 + 곡 1개 + 처방 문구.
//
// 사용자 mandate verbatim 예시:
//   "오늘 당신의 사주에 '열정(불)'이 부족합니다.
//    '불'의 기운을 타고난 [솔라]를 데려왔습니다.
//    이 곡을 들으면 부족한 기운이 100% 충전됩니다."
//   "[부작용: 너무 신나서 공부 안 될 수 있음]"
//   "[효능: 짝남에게 연락 올 확률 상승]"
//
// 데이터 소스:
//   - assets/data/celebrities.json — 223명 (id / nameKo / dayPillar)
//   - assets/data/celeb_songs.json — id → [{titleKo, artistKo, element, moodKo}]
//
// 셀럽 5행 매핑 — dayPillar 천간 1자:
//   甲乙 → wood, 丙丁 → fire, 戊己 → earth, 庚辛 → metal, 壬癸 → water
//
// 데터미니스틱 — seed 미명시 시 사용자 일주 + yearPillar 해시. 같은 seed → 같은 처방.

import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/saju_result.dart';
import 'korean_josa.dart' as josa;

/// 처방전 결과 1편.
class MusicPrescription {
  /// 부족한 5행 (en key) — "wood" / "fire" / "earth" / "metal" / "water".
  final String element;

  /// 부족 5행 한국어 라벨 — "불 (열정)" 류.
  final String elementKo;

  final String celebId;
  final String celebNameKo;
  final String songTitleKo;
  final String songArtistKo;

  /// 5~7 줄 처방 본문 (한국어, 영어 leak 없음).
  final String prescriptionText;

  /// 효능 한 줄 — "[효능: ...]" 의 안쪽 문구만.
  final String effectKo;

  /// 부작용 한 줄.
  final String sideEffectKo;

  /// 복용법 한 줄 — "하루 3회, 식후 30분" 류.
  final String dosageKo;

  const MusicPrescription({
    required this.element,
    required this.elementKo,
    required this.celebId,
    required this.celebNameKo,
    required this.songTitleKo,
    required this.songArtistKo,
    required this.prescriptionText,
    required this.effectKo,
    required this.sideEffectKo,
    required this.dosageKo,
  });
}

class MusicPharmacyService {
  static const String _pathCelebs = 'assets/data/celebrities.json';
  static const String _pathSongs = 'assets/data/celeb_songs.json';

  static List<_Celeb>? _celebsCache;
  static Map<String, List<_Song>>? _songsCache;

  /// rootBundle 로드 후 캐시 채움 (sync API 사용 직전 호출).
  static Future<void> primeCache() async {
    await _loadAll();
  }

  /// 테스트용 — 데이터 직접 주입.
  static void seedForTest({
    required List<Map<String, dynamic>> celebs,
    required Map<String, dynamic> songs,
  }) {
    _celebsCache = celebs.map((j) => _Celeb.fromJson(j)).toList();
    _songsCache = songs.map((id, raw) {
      final list = (raw as List)
          .cast<Map<String, dynamic>>()
          .map(_Song.fromJson)
          .toList();
      return MapEntry(id, list);
    });
  }

  /// 캐시 초기화 (테스트 격리용).
  static void resetCacheForTest() {
    _celebsCache = null;
    _songsCache = null;
  }

  /// 사용자 사주 + (옵션) 이름 + seed → 처방전.
  ///
  /// 알고리즘:
  ///   1. user.elements 의 5행 중 가장 약한 값 = deficit (한자 한 글자).
  ///   2. 한자 → en key 변환 (木→wood ...).
  ///   3. 셀럽 중 dayPillar 천간 5행 == deficit 인 후보 list.
  ///   4. FNV-1a + xorshift32 seed → 후보 중 1명 선택.
  ///   5. 그 셀럽의 곡 list 중 첫 곡 (현재 1곡씩) 선택.
  ///   6. effect / sideEffect / dosage pool 에서 seed 회전 선택.
  ///   7. 처방 본문 합성 (5~7 줄).
  ///
  /// 후보 0 (edge case) — fallback: 어느 5행이든 가장 가까운 셀럽 1명 (전체 후보).
  /// 그래도 0 이면 null.
  static Future<MusicPrescription?> prescribe({
    required SajuResult user,
    String? userName,
    int? seed,
  }) async {
    await _loadAll();
    return _prescribeSync(user: user, userName: userName, seed: seed);
  }

  /// 테스트 환경에서 cache 가 이미 seedForTest 로 채워졌을 때 호출 가능한
  /// 동기 버전. production 진입은 [prescribe] 를 통과.
  static MusicPrescription? prescribeSync({
    required SajuResult user,
    String? userName,
    int? seed,
  }) {
    if (_celebsCache == null || _songsCache == null) return null;
    return _prescribeSync(user: user, userName: userName, seed: seed);
  }

  static MusicPrescription? _prescribeSync({
    required SajuResult user,
    String? userName,
    int? seed,
  }) {
    final celebs = _celebsCache!;
    final songs = _songsCache!;

    final deficitHanja = user.elements.deficit; // 木/火/土/金/水
    final element = _hanjaToEnKey(deficitHanja);
    final elementKo = _elementKoLabel(element);

    // 후보 — 셀럽 dayPillar 천간 5행 == deficit + musicEligible (가수 only).
    // R102 Sprint 3: actor / athlete / icon 은 music pharmacy 처방 불가
    // (한소희 / 김연아 / 손흥민 등이 처방되던 버그 차단). 단 idol 활동
    // 이력이 있는 actor 4명 (차은우 / 이준호 / 배수지 / 지드래곤) 은 예외 retain.
    final candidates = celebs.where((c) {
      if (!c.musicEligible) return false;
      final chun = c.dayPillar.isNotEmpty ? c.dayPillar[0] : '';
      return _chunGanToEnKey(chun) == element;
    }).where((c) => songs.containsKey(c.id)).toList();

    // fallback — 후보 0 일 경우 musicEligible 셀럽 중 곡 데이터 있는 자.
    // (가드 동일 — fallback 으로 actor/athlete 가 빠지면 X.)
    final pool = candidates.isNotEmpty
        ? candidates
        : celebs
            .where((c) => c.musicEligible && songs.containsKey(c.id))
            .toList();
    if (pool.isEmpty) return null;

    // deterministic seed.
    final effectiveSeed = seed ?? _deriveSeed(user);
    final rng = _XorShift32(_fnv1a('celeb_pick:$effectiveSeed'));
    final celeb = pool[rng.nextInt(pool.length)];
    final celebSongs = songs[celeb.id]!;
    final song = celebSongs[
        _XorShift32(_fnv1a('song_pick:$effectiveSeed:${celeb.id}'))
            .nextInt(celebSongs.length)];

    // pools — 한국어 only.
    final effectPool = _effectPool(element);
    final sidePool = _sideEffectPool(element);
    final dosagePool = _dosagePool;

    final effect = effectPool[
        _XorShift32(_fnv1a('eff:$effectiveSeed:$element')).nextInt(effectPool.length)];
    final side = sidePool[
        _XorShift32(_fnv1a('side:$effectiveSeed:$element')).nextInt(sidePool.length)];
    final dosage = dosagePool[
        _XorShift32(_fnv1a('dose:$effectiveSeed:$element')).nextInt(dosagePool.length)];

    final whoKo = (userName ?? '').trim().isEmpty ? '당신' : userName!.trim();
    final shortName =
        celeb.nameKo.contains('(') ? celeb.nameKo.split('(').first.trim() : celeb.nameKo;

    final body = StringBuffer()
      ..writeln("오늘 $whoKo의 사주에 '$elementKo' 기운이 부족합니다.")
      ..writeln(
          "'${_elementBareKo(element)}'의 기운을 타고난 [$shortName]${josa.withObj(shortName)} 데려왔어요.")
      ..writeln("처방곡은 [${song.titleKo}] (${song.artistKo}).")
      ..writeln("이 곡을 들으면 부족한 기운이 100% 충전됩니다.")
      ..writeln('[효능: $effect]')
      ..writeln('[부작용: $side]')
      ..write('[복용법: $dosage]');

    return MusicPrescription(
      element: element,
      elementKo: elementKo,
      celebId: celeb.id,
      celebNameKo: celeb.nameKo,
      songTitleKo: song.titleKo,
      songArtistKo: song.artistKo,
      prescriptionText: body.toString(),
      effectKo: effect,
      sideEffectKo: side,
      dosageKo: dosage,
    );
  }

  // ─── 내부: 캐시 로드 ───────────────────────────────────────────────
  static Future<void> _loadAll() async {
    if (_celebsCache != null && _songsCache != null) return;
    final rawCelebs = await rootBundle.loadString(_pathCelebs);
    final rawSongs = await rootBundle.loadString(_pathSongs);
    final list = (json.decode(rawCelebs) as List).cast<Map<String, dynamic>>();
    final songMap = (json.decode(rawSongs) as Map<String, dynamic>);
    _celebsCache = list.map(_Celeb.fromJson).toList();
    _songsCache = songMap.map((id, raw) {
      final l = (raw as List).cast<Map<String, dynamic>>().map(_Song.fromJson).toList();
      return MapEntry(id, l);
    });
  }

  // ─── 5행 라벨 매핑 ─────────────────────────────────────────────────
  static String _chunGanToEnKey(String chunGan) {
    const map = {
      '甲': 'wood', '乙': 'wood',
      '丙': 'fire', '丁': 'fire',
      '戊': 'earth', '己': 'earth',
      '庚': 'metal', '辛': 'metal',
      '壬': 'water', '癸': 'water',
    };
    return map[chunGan] ?? 'wood';
  }

  static String _hanjaToEnKey(String hanja) {
    const map = {
      '木': 'wood',
      '火': 'fire',
      '土': 'earth',
      '金': 'metal',
      '水': 'water',
    };
    return map[hanja] ?? 'wood';
  }

  /// "불 (열정)" 류.
  static String _elementKoLabel(String element) {
    switch (element) {
      case 'wood':
        return '나무 (성장)';
      case 'fire':
        return '불 (열정)';
      case 'earth':
        return '흙 (안정)';
      case 'metal':
        return '쇠 (결단)';
      case 'water':
        return '물 (지혜)';
    }
    return '나무 (성장)';
  }

  /// 본문 안 두 번째 줄용 — 짧은 형 ("불" / "나무" 등).
  static String _elementBareKo(String element) {
    switch (element) {
      case 'wood':
        return '나무';
      case 'fire':
        return '불';
      case 'earth':
        return '흙';
      case 'metal':
        return '쇠';
      case 'water':
        return '물';
    }
    return '나무';
  }

  // ─── 효능 / 부작용 / 복용법 pool ──────────────────────────────────
  // 모두 사용자 mandate 의 verbatim 톤 (덕질·일상·연애·시험·운동 등 K-MZ 친밀).
  static List<String> _effectPool(String element) {
    switch (element) {
      case 'wood':
        return const <String>[
          '오랜만에 들고 다닌 책이 술술 읽힘',
          '아침에 평소보다 두 박자 일찍 일어남',
          '식물 키우는 손이 부드러워지는 기분',
          '걷고 싶은 거리가 평소보다 두 배',
          '말 못한 말이 자연스럽게 입에서 나옴',
          '오늘 본 풍경 색이 조금 더 진해 보임',
        ];
      case 'fire':
        return const <String>[
          '짝남에게 연락 올 확률 상승',
          '회의에서 한 마디 더 보태고 싶어짐',
          '오늘 사진 잘 받음',
          '걷는 속도가 평소보다 빨라짐',
          '낯선 사람에게 먼저 인사 가능',
          '땀이 살짝 나도 기분 좋음',
        ];
      case 'earth':
        return const <String>[
          '오늘 밥맛이 두 배',
          '거실 정리하고 싶은 마음',
          '예전 친구에게서 연락이 옴',
          '어제 못 잔 잠이 한 번에 보충됨',
          '돈 계산 실수 없이 마무리',
          '가족 단톡에 답장 두 줄 더 보탬',
        ];
      case 'metal':
        return const <String>[
          '미루던 결정 오늘 끝남',
          '시험 문제 정답이 한 번에 보임',
          '연락 끊긴 그 사람에게서 정리 메시지가 옴',
          '운동 자세 단단해진 느낌',
          '메일 답장이 깔끔하게 정리됨',
          '한 번 말한 약속을 끝까지 지킴',
        ];
      case 'water':
        return const <String>[
          '오늘 떠오른 아이디어가 노트에 정리됨',
          '잘 잠든 새벽 꿈을 자세히 기억',
          '심사·면접 같은 자리에서 침착함',
          '오해가 풀리는 대화가 한 번 생김',
          '읽고 싶었던 책 한 권을 끝까지 봄',
          '오늘 흘린 말이 누군가에게 위로가 됨',
        ];
    }
    return const ['오늘 컨디션 두 박자 위로'];
  }

  static List<String> _sideEffectPool(String element) {
    switch (element) {
      case 'wood':
        return const <String>[
          '머릿속 아이디어가 너무 많아져서 메모 부족',
          '갑자기 식물 가게 들러서 한 화분 사 옴',
          '말이 술술 나와서 점심값 1.5배',
          '서점에서 30분 더 머무름',
          '걸음 수가 두 배라 발 좀 아픔',
        ];
      case 'fire':
        return const <String>[
          '너무 신나서 공부 안 될 수 있음',
          '카페에서 친구랑 두 잔 더 마심',
          '잠들기까지 한 시간 더 걸림',
          '쇼핑 카트에 아이템 두 개 더 들어감',
          'DM 답장 속도가 너무 빨라서 좀 들킴',
        ];
      case 'earth':
        return const <String>[
          '간식 한 번 더 손이 감',
          '청소하느라 본 영상 중간에 끊김',
          '단톡 답장하다 약속에 5분 늦음',
          '잠이 너무 잘 와서 알람 두 번 듣고 일어남',
          '예전 사진 보다가 30분 사라짐',
        ];
      case 'metal':
        return const <String>[
          '결정이 너무 단호해서 친구가 살짝 놀람',
          '정리하다가 버리지 말아야 할 걸 버림',
          '말투가 평소보다 칼 같음',
          '운동 강도가 살짝 셈, 다음 날 근육통',
          '약속 끝까지 지키려다 잠이 줄어듦',
        ];
      case 'water':
        return const <String>[
          '꿈이 너무 길어서 새벽에 한 번 깸',
          '책 읽다가 자정 넘김',
          '생각이 깊어져서 답장 속도 살짝 느림',
          '눈물 한 번 살짝 고임',
          '말 한 줄을 30분 동안 고침',
        ];
    }
    return const ['살짝 들뜸'];
  }

  static const List<String> _dosagePool = <String>[
    '하루 3회, 식후 30분',
    '아침 출근 길 1회, 자기 전 1회',
    '점심시간 1회, 저녁 산책 중 1회',
    '하루 1회, 가장 우울한 순간에',
    '주 4회, 빨래 개면서 1회',
    '시험·발표 30분 전 1회',
  ];

  // ─── 결정성 seed ────────────────────────────────────────────────
  static int _deriveSeed(SajuResult user) {
    final s = '${user.dayPillar.text}|${user.yearPillar.text}|'
        '${user.elements.wood}|${user.elements.fire}|'
        '${user.elements.earth}|${user.elements.metal}|${user.elements.water}';
    return _fnv1a(s);
  }

  /// FNV-1a 32bit — 입력 문자열 기반 안정 hash.
  static int _fnv1a(String s) {
    var h = 0x811c9dc5;
    for (final r in s.runes) {
      h ^= r & 0xff;
      h = (h * 0x01000193) & 0xffffffff;
    }
    return h & 0x7fffffff;
  }
}

class _XorShift32 {
  int _state;
  _XorShift32(int seed)
      : _state = (seed == 0) ? 0x1 : (seed & 0xffffffff);

  int nextInt(int max) {
    if (max <= 0) return 0;
    var x = _state;
    x ^= (x << 13) & 0xffffffff;
    x ^= (x >> 17) & 0xffffffff;
    x ^= (x << 5) & 0xffffffff;
    _state = x & 0xffffffff;
    return (_state & 0x7fffffff) % max;
  }
}

class _Celeb {
  final String id;
  final String nameKo;
  final String dayPillar;

  /// celebrities.json 의 kind — "idol" / "actor" / "athlete" / "icon".
  /// 누락된 entry 는 "idol" 로 안전 기본값 (legacy seedForTest 호환).
  final String kind;

  const _Celeb({
    required this.id,
    required this.nameKo,
    required this.dayPillar,
    required this.kind,
  });

  /// R102 Sprint 3 — music pharmacy 처방 가능 여부.
  /// 기본 정책:
  ///   - kind == 'idol' → true
  ///   - kind == 'actor' / 'athlete' / 'icon' → false
  /// 예외 (idol 활동 이력 있는 actor / icon — Sprint 4 데이터 cleanup 전까지
  ///       hardcoded retain):
  ///   - cha-eunwoo (ASTRO 멤버)
  ///   - lee-junho (2PM 멤버)
  ///   - bae-suzy (Miss A → 솔로 수지)
  ///   - gdragon (BIGBANG / 솔로)
  bool get musicEligible {
    if (_musicEligibleException.contains(id)) return true;
    return kind == 'idol';
  }

  static const Set<String> _musicEligibleException = <String>{
    'cha-eunwoo',
    'lee-junho',
    'bae-suzy',
    'gdragon',
  };

  factory _Celeb.fromJson(Map<String, dynamic> j) => _Celeb(
        id: j['id'] as String? ?? '',
        nameKo: j['nameKo'] as String? ?? '',
        dayPillar: j['dayPillar'] as String? ?? '',
        kind: (j['kind'] as String?)?.trim().isNotEmpty == true
            ? (j['kind'] as String).trim()
            : 'idol',
      );
}

class _Song {
  final String titleKo;
  final String artistKo;
  final String element;
  final String moodKo;
  const _Song({
    required this.titleKo,
    required this.artistKo,
    required this.element,
    required this.moodKo,
  });
  factory _Song.fromJson(Map<String, dynamic> j) => _Song(
        titleKo: j['titleKo'] as String? ?? '',
        artistKo: j['artistKo'] as String? ?? '',
        element: j['element'] as String? ?? '',
        moodKo: j['moodKo'] as String? ?? '',
      );
}
