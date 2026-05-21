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
///
/// R106 P5: 영어 carrier 추가 (한국어 필드는 schema·id 보존, 영어는 추가만).
/// 화면이 useKo 로 분기. 영어 콘텐츠는 v5 voice — 단정 금지·메타 금지.
class MusicPrescription {
  /// 부족한 5행 (en key) — "wood" / "fire" / "earth" / "metal" / "water".
  final String element;

  /// 부족 5행 한국어 라벨 — "불 (열정)" 류.
  final String elementKo;

  /// 부족 5행 영어 라벨 — "Fire (passion)" 류.
  final String elementEn;

  final String celebId;
  final String celebNameKo;

  /// 셀럽 영어 이름 — celebrities.json nameEn (전 223명 완비).
  final String celebNameEn;

  final String songTitleKo;
  final String songArtistKo;

  /// 처방곡 영어 제목 — 실재 곡의 공식 영어/로마자 표기 (창작 0).
  final String songTitleEn;

  /// 처방곡 아티스트 영어 표기 — 실재 아티스트/그룹 (창작 0).
  final String songArtistEn;

  /// 5~7 줄 처방 본문 (한국어, 영어 leak 없음).
  final String prescriptionText;

  /// 5~7 줄 처방 본문 (영어, 한글 leak 없음). v5 voice.
  final String prescriptionTextEn;

  /// 효능 한 줄 — "[효능: ...]" 의 안쪽 문구만.
  final String effectKo;

  /// 효능 한 줄 — 영어.
  final String effectEn;

  /// 부작용 한 줄.
  final String sideEffectKo;

  /// 부작용 한 줄 — 영어.
  final String sideEffectEn;

  /// 복용법 한 줄 — "하루 3회, 식후 30분" 류.
  final String dosageKo;

  /// 복용법 한 줄 — 영어.
  final String dosageEn;

  const MusicPrescription({
    required this.element,
    required this.elementKo,
    required this.elementEn,
    required this.celebId,
    required this.celebNameKo,
    required this.celebNameEn,
    required this.songTitleKo,
    required this.songArtistKo,
    required this.songTitleEn,
    required this.songArtistEn,
    required this.prescriptionText,
    required this.prescriptionTextEn,
    required this.effectKo,
    required this.effectEn,
    required this.sideEffectKo,
    required this.sideEffectEn,
    required this.dosageKo,
    required this.dosageEn,
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

    // pools — 한국어 / 영어 index 동기 (pool 길이 동일, 같은 index 가 같은 의미).
    final effectPool = _effectPool(element);
    final effectPoolEn = _effectPoolEn(element);
    final sidePool = _sideEffectPool(element);
    final sidePoolEn = _sideEffectPoolEn(element);
    final dosagePool = _dosagePool;
    final dosagePoolEn = _dosagePoolEn;

    final effIdx =
        _XorShift32(_fnv1a('eff:$effectiveSeed:$element')).nextInt(effectPool.length);
    final sideIdx =
        _XorShift32(_fnv1a('side:$effectiveSeed:$element')).nextInt(sidePool.length);
    final doseIdx =
        _XorShift32(_fnv1a('dose:$effectiveSeed:$element')).nextInt(dosagePool.length);

    final effect = effectPool[effIdx];
    final effectEn = effectPoolEn[effIdx % effectPoolEn.length];
    final side = sidePool[sideIdx];
    final sideEn = sidePoolEn[sideIdx % sidePoolEn.length];
    final dosage = dosagePool[doseIdx];
    final dosageEn = dosagePoolEn[doseIdx % dosagePoolEn.length];

    final elementEn = _elementEnLabel(element);
    final whoKo = (userName ?? '').trim().isEmpty ? '당신' : userName!.trim();
    final whoEn = (userName ?? '').trim().isEmpty ? 'you' : userName!.trim();
    final shortName =
        celeb.nameKo.contains('(') ? celeb.nameKo.split('(').first.trim() : celeb.nameKo;
    final celebNameEn = celeb.nameEn.trim().isEmpty ? shortName : celeb.nameEn.trim();
    final shortNameEn = celebNameEn.contains('(')
        ? celebNameEn.split('(').first.trim()
        : celebNameEn;
    final songTitleEn = _songTitleEn(song.titleKo);
    final songArtistEn = _artistEn(song.artistKo);

    // R107 #7 — 부족 5행 외 다른 근거 한 줄 (셀럽 일주 천간 = 그 5행).
    // 부족 오행 하나만 보고 단정하던 본문에 셀럽이 그 기운을 타고났다는
    // 사주 근거를 한 줄 더해, 처방 문구가 "왜 이 곡인지" 를 함께 말하게 한다.
    final body = StringBuffer()
      ..writeln("오늘 $whoKo의 사주를 보면 '$elementKo' 기운이 한 박자 비어 있어요.")
      ..writeln(
          "'${_elementBareKo(element)}'의 기운을 일주에 타고난 [$shortName]${josa.withObj(shortName)} 데려왔어요.")
      ..writeln("처방곡은 [${song.titleKo}] (${song.artistKo}).")
      ..writeln(
          "이 곡을 가만히 들으면 비어 있던 '${_elementBareKo(element)}' 기운을 채우는 데 도움이 돼요.")
      ..writeln('[효능: $effect]')
      ..writeln('[부작용: $side]')
      ..write('[복용법: $dosage]');

    // 영어 본문 — v5 voice: 단정 금지(can / tends to), 메타 금지.
    final bodyEn = StringBuffer()
      ..writeln(
          "Today $whoEn runs a little light on ${_elementBareEn(element)} energy.")
      ..writeln(
          "[$shortNameEn] carries a strong ${_elementBareEn(element)} streak in their day pillar, so they make a good companion for it.")
      ..writeln("The prescription track is [$songTitleEn] ($songArtistEn).")
      ..writeln(
          "Give it a quiet listen and it can help top that ${_elementBareEn(element)} energy back up.")
      ..writeln('[Effect: $effectEn]')
      ..writeln('[Side effect: $sideEn]')
      ..write('[Dosage: $dosageEn]');

    return MusicPrescription(
      element: element,
      elementKo: elementKo,
      elementEn: elementEn,
      celebId: celeb.id,
      celebNameKo: celeb.nameKo,
      celebNameEn: celebNameEn,
      songTitleKo: song.titleKo,
      songArtistKo: song.artistKo,
      songTitleEn: songTitleEn,
      songArtistEn: songArtistEn,
      prescriptionText: body.toString(),
      prescriptionTextEn: bodyEn.toString(),
      effectKo: effect,
      effectEn: effectEn,
      sideEffectKo: side,
      sideEffectEn: sideEn,
      dosageKo: dosage,
      dosageEn: dosageEn,
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

  /// "Fire (passion)" 류 — _elementKoLabel 영어 대응.
  static String _elementEnLabel(String element) {
    switch (element) {
      case 'wood':
        return 'Wood (growth)';
      case 'fire':
        return 'Fire (passion)';
      case 'earth':
        return 'Earth (steadiness)';
      case 'metal':
        return 'Metal (resolve)';
      case 'water':
        return 'Water (wisdom)';
    }
    return 'Wood (growth)';
  }

  /// 본문용 짧은 영어 형 ("fire" / "wood" 등) — _elementBareKo 영어 대응.
  static String _elementBareEn(String element) {
    switch (element) {
      case 'wood':
        return 'wood';
      case 'fire':
        return 'fire';
      case 'earth':
        return 'earth';
      case 'metal':
        return 'metal';
      case 'water':
        return 'water';
    }
    return 'wood';
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

  // ─── 영어 pool — KO pool 과 index 동기 (같은 의미, v5 voice) ────────────
  // 단정 금지(can / might / tends to), 메타 금지. 의료 단정 아님 — 메타포 유지.
  static List<String> _effectPoolEn(String element) {
    switch (element) {
      case 'wood':
        return const <String>[
          'A book you have been carrying around can finally start to flow',
          'You might wake up a beat or two earlier than usual',
          'Tending a plant can feel a little gentler in your hands',
          'The distance you feel like walking might stretch to twice as far',
          'Words you held back can come out more naturally',
          "Today's scenery might look a shade richer in color",
        ];
      case 'fire':
        return const <String>[
          'The chance of a hello from your crush can tick upward',
          'You might feel like adding one more line in the meeting',
          'Your photos today can come out looking good',
          'Your walking pace might pick up a little',
          'Saying hi first to a stranger can feel doable',
          'Even a light sweat might feel pretty good',
        ];
      case 'earth':
        return const <String>[
          'A meal today can taste twice as good',
          'You might feel like tidying up the living room',
          'An old friend can reach out of nowhere',
          'Sleep you missed yesterday might catch up all at once',
          'Money math can wrap up without a slip',
          'You might add two more lines to the family group chat',
        ];
      case 'metal':
        return const <String>[
          'A decision you kept putting off can land today',
          'A test answer might click into place on the first read',
          'Someone who went quiet can send a clean wrap-up message',
          'Your workout form might feel a touch more solid',
          'Your email reply can come out tidy and clear',
          'A promise you said once might hold all the way through',
        ];
      case 'water':
        return const <String>[
          'An idea that surfaced today can land neatly in your notes',
          'You might remember a dawn dream in clear detail',
          'You can feel calm in a review or interview-type moment',
          'A talk that clears up a misunderstanding might happen once',
          'You might finish a book you had been meaning to read',
          'Something you said today can land as comfort for someone',
        ];
    }
    return const ['Your mood today can lift a beat or two'];
  }

  static List<String> _sideEffectPoolEn(String element) {
    switch (element) {
      case 'wood':
        return const <String>[
          'So many ideas at once that your notes might run short',
          'You might swing by a plant shop and walk out with a pot',
          'Words flow so easily that lunch can run about 1.5x the bill',
          'You might linger thirty extra minutes in a bookstore',
          'Your step count can double, so your feet might ache a bit',
        ];
      case 'fire':
        return const <String>[
          'You might feel too hyped to settle into studying',
          'You can end up two cups deep with a friend at the cafe',
          'It might take an extra hour to fall asleep',
          'Two more items can sneak into your shopping cart',
          'Your DM replies might come back so fast it shows a little',
        ];
      case 'earth':
        return const <String>[
          'Your hand might reach for one more snack',
          'A video you were watching can get cut off mid-tidying',
          'Replying in the group chat might make you five minutes late',
          'Sleep can come so easily you wake after two alarms',
          'Old photos might quietly eat thirty minutes',
        ];
      case 'metal':
        return const <String>[
          'A decision so firm that a friend might be a little startled',
          'While tidying you might toss something you meant to keep',
          'Your tone can come out sharper than usual',
          'A slightly harder workout might leave next-day soreness',
          'Keeping a promise all the way through can trim your sleep',
        ];
      case 'water':
        return const <String>[
          'A long dream might wake you once before dawn',
          'A book can keep you up past midnight',
          'Deeper thinking might slow your reply time a touch',
          'A tear or two might quietly well up',
          'You can spend thirty minutes editing a single line',
        ];
    }
    return const ['A slight buzz of restlessness'];
  }

  static const List<String> _dosagePoolEn = <String>[
    'Three times a day, thirty minutes after meals',
    'Once on the morning commute, once before sleep',
    'Once at lunch, once on an evening walk',
    'Once a day, at the lowest moment',
    'Four times a week, once while folding laundry',
    'Once, thirty minutes before a test or presentation',
  ];

  // ─── 결정성 seed ────────────────────────────────────────────────
  static int _deriveSeed(SajuResult user) {
    final s = '${user.dayPillar.text}|${user.yearPillar.text}|'
        '${user.elements.wood}|${user.elements.fire}|'
        '${user.elements.earth}|${user.elements.metal}|${user.elements.water}';
    return _fnv1a(s);
  }

  // ─── 곡 제목 / 아티스트 영어 표기 (실재 곡·아티스트 — 창작 0) ──────────
  // celeb_songs.json 은 한국어 표기만 (titleKo / artistKo). 영어 모드를 위해
  // 실재 K-POP 곡의 공식 영어/로마자 제목을 KO→EN 으로 매핑한다.
  // 매핑에 없는 제목은 KO 그대로 둔다 (창작·오역 방지).
  static String _songTitleEn(String titleKo) {
    return _songTitleEnMap[titleKo.trim()] ?? titleKo;
  }

  static String _artistEn(String artistKo) {
    return _artistEnMap[artistKo.trim()] ?? artistKo;
  }

  /// 아티스트/그룹 KO→EN — celeb_songs.json artistKo 전수 (57종).
  static const Map<String, String> _artistEnMap = <String, String>{
    '권은비': 'Kwon Eun-bi',
    '나연': 'Nayeon',
    '뉴진스': 'NewJeans',
    '라이즈': 'RIIZE',
    '레드벨벳': 'Red Velvet',
    '로제': 'Rosé',
    '르세라핌': 'LE SSERAFIM',
    '리사': 'Lisa',
    '문별': 'Moonbyul',
    '베이비몬스터': 'BABYMONSTER',
    '보이넥스트도어': 'BOYNEXTDOOR',
    '뷔': 'V',
    '선미': 'Sunmi',
    '세븐틴': 'SEVENTEEN',
    '솔라': 'Solar',
    '수지': 'Suzy',
    '스테이씨': 'STAYC',
    '스트레이 키즈': 'Stray Kids',
    '아이들': '(G)I-DLE',
    '아이브': 'IVE',
    '아이유': 'IU',
    '아일릿': 'ILLIT',
    '알엠': 'RM',
    '어거스트 디': 'Agust D',
    '에스파': 'aespa',
    '에이티즈': 'ATEEZ',
    '엑스지': 'XG',
    '엔믹스': 'NMIXX',
    '엔시티 드림': 'NCT DREAM',
    '엔시티 위시': 'NCT WISH',
    '엔하이픈': 'ENHYPEN',
    '웬디': 'Wendy',
    '이준호': 'Lee Jun-ho',
    '있지': 'ITZY',
    '전소미': 'Jeon Somi',
    '정국': 'Jung Kook',
    '제니': 'Jennie',
    '제로베이스원': 'ZEROBASEONE',
    '제이홉': 'j-hope',
    '지드래곤': 'G-Dragon',
    '지민': 'Jimin',
    '지수': 'Jisoo',
    '지효': 'Jihyo',
    '진': 'Jin',
    '차은우': 'Cha Eun-woo',
    '청하': 'Chungha',
    '캣츠아이': 'KATSEYE',
    '키스오브라이프': 'KISS OF LIFE',
    '태연': 'Taeyeon',
    '투바투': 'TOMORROW X TOGETHER',
    '투어스': 'TWS',
    '트레저': 'TREASURE',
    '트와이스': 'TWICE',
    '피원하모니': 'P1Harmony',
    '호시': 'HOSHI',
    '화사': 'Hwasa',
    '휘인': 'Whee In',
  };

  /// 곡 제목 KO→EN — celeb_songs.json 의 실재 K-POP 곡 공식 영어/로마자 표기.
  /// (창작 금지 — 매핑 없으면 KO 유지.)
  static const Map<String, String> _songTitleEnMap = <String, String>{
    '덤덤': 'Dumdum',
    '가브리엘라': 'Gabriela',
    '갓 오브 뮤직': 'God of Music',
    '게릴라': 'Guerrilla',
    '겟 어 기타': 'Get A Guitar',
    '굿 보이 곤 배드': 'Good Boy Gone Bad',
    '굿 소 배드': 'Good So Bad',
    '글리치 모드': 'Glitch Mode',
    '기븐-테이큰': 'Given-Taken',
    '기적 같은 이야기': 'Stay',
    '꼬리': 'Tail',
    '나이스 가이': 'Nice Guy',
    '나인 데이즈': '9 Days',
    '날리': 'Gnarly',
    '내 손을 잡아': 'Hold My Hand',
    '뉴 댄스': 'New Dance',
    '느쥬드': 'Nxde',
    '다라리': 'DARARI',
    '다이스': 'DICE',
    '달라달라': 'DALLA DALLA',
    '대시': 'DASH',
    '대취타': 'Daechwita',
    '댄저러스': 'Dangerous',
    '데뷔': 'Debut',
    '도 더 댄스': 'Do the Dance',
    '도파민': 'Dopamine',
    '둠 두 둠': 'Do or Die',
    '드라마': 'Drama',
    '드립': 'DRIP',
    '들꽃놀이': 'Wild Flower',
    '디 애스트로넛': 'The Astronaut',
    '디토': 'Ditto',
    '디퍼런트': 'Different',
    '라스트 페스티벌': 'Last Festival',
    '라이크 워터': 'Like Water',
    '라이크 크레이지': 'Like Crazy',
    '락': 'Rock',
    '러브 다이브': 'LOVE DIVE',
    '러브 머니 페임': 'LOVE, MONEY, FAME',
    '러브 미 라이크 디스': 'Love Me Like This',
    '러키 걸 신드롬': 'Lucky Girl Syndrome',
    '런투유': 'RUN2U',
    '레프트 라이트': 'LEFT RIGHT',
    '롤러코스터': 'Rock with you',
    '마리아': 'Maria',
    '마스카라': 'MASCARA',
    '마에스트로': 'MAESTRO',
    '마피아 인 더 모닝': 'MAFIA In the morning',
    '매그네틱': 'Magnetic',
    '매니악': 'MANIAC',
    '머니': 'MONEY',
    '메모리즈': 'Memories',
    '무제': 'Untitled, 2014',
    '바운시': 'BOUNCY',
    '배디': 'Baddie',
    '배터 업': 'Batter Up',
    '백 도어': 'Back Door',
    '버블': 'Bubble',
    '보니 앤 클라이드': 'Bonnie & Clyde',
    '본 더 트레저': 'Born the Treasure',
    '부메랑': 'BOOMERANG',
    '붐 붐 베이스': 'Boom Boom Bass',
    '브로큰 멜로디스': 'Broken Melodies',
    '브링 잇 백': 'BRING IT BACK',
    '블러디 메리': 'Bloody Mary',
    '블레싱-인-디스가이즈': 'Blessed-Cursed',
    '블루': 'Blue',
    '비에프에프': 'BFF',
    '비트박스': 'Beatbox',
    '사나 두 잇 어게인': 'I GOT YOU',
    '사이렌': 'SIREN',
    '샤프': 'Sharp',
    '세븐': 'Seven',
    '셋 미 프리': 'SET ME FREE',
    '솔로': 'SOLO',
    '송버드': 'Songbird',
    '수퍼 레이디': 'Super Lady',
    '수퍼노바': 'Supernova',
    '쉬시': 'SHEESH',
    '슈가 러시 라이드': 'Sugar Rush Ride',
    '슈팅 스타': 'SHOOTING STAR',
    '슈퍼': 'Super',
    '슈퍼 샤이': 'Super Shy',
    '스니커즈': 'Sneakers',
    '스마트': 'Smart',
    '스무디': 'Smoothie',
    '스웻': 'SWEAT',
    '스위트 베놈': 'Sweet Venom',
    '스케어드': 'Scared',
    '스턱 인 더 미들': 'Stuck In The Middle',
    '스테레오타입': 'STEREOTYPE',
    '스티키': 'Sticky',
    '스틸 위시': 'Still With You',
    '스파이더': 'Spider',
    '스파이시': 'Spicy',
    '스파이트': 'SPIT IT OUT',
    '슬로 댄싱': 'Slow Dancing',
    '신난다': 'Hellevator',
    '신메뉴': 'New Menu',
    '써클': 'Circle',
    '썬더': 'THUNDER',
    '아 진짜요': 'Yeah',
    '아리랑': 'Arson',
    '아이 엠': 'I AM',
    '아이에스티제이': 'ISTJ',
    '아이엔브이유': 'INVU',
    '아주 나이스': 'Super',
    '아파트': 'APT.',
    '안티-로맨틱': 'Anti-Romantic',
    '안티프래자일': 'ANTIFRAGILE',
    '애프터 라이크': 'After LIKE',
    '어스, 윈드 앤 파이어': 'Earth, Wind & Fire',
    '언더': 'Underwater',
    '언플러그드 보이': 'Plot Twist',
    '에이셉': 'ASAP',
    '에프엠엘': 'F*ck My Life',
    '예스 오어 예스': 'YES or YES',
    '오 마이마이 세븐스': 'Oh Mymy : 7th Sky',
    '오 오': 'O.O',
    '와이프': 'Wife',
    '워너비': 'WANNABE',
    '워크': 'WORK',
    '워크 업': 'WOKE UP',
    '원 스파크': 'ONE SPARK',
    '원더랜드': 'WONDERLAND',
    '월플라워': 'water flower',
    '위시': 'WISH',
    '위플래쉬': 'Whiplash',
    '유스 인 더 셰이드': 'Youth in the Shade',
    '유어 룰스': 'YURA YURA',
    '이글루': 'Igloo',
    '이지': 'EASY',
    '이티에이': 'ETA',
    '이프 아이 세이 아이 러브 유': 'If I Say, I Love You',
    '인 블룸': 'In Bloom',
    '일레븐': 'ELEVEN',
    '임파서블': 'Impossible',
    '점프': 'JUMP',
    '체리쉬': 'Cherish',
    '체셔': 'Cheshire',
    '체이싱 댓 필링': 'Chasing That Feeling',
    '치얼 업': 'Cheer Up',
    '치키 아이시 탱': 'Cheeky Icy Thang',
    '캔디': 'Candy',
    '케이스 143': 'CASE 143',
    '코스믹': 'Cosmic',
    '쿠키': 'Cookie',
    '퀸카': 'Queencard',
    '크라운': 'CROWN',
    '크레이지': 'CRAZY',
    '크레이지 폼': 'Crazy Form',
    '키치': 'Kitsch',
    '킬린 잇': 'Killin It',
    '킬링 미 굿': 'Killin\' Me Good',
    '킹 콩': 'KING KONG',
    '탑': 'TOP',
    '탬버린': 'TAMBOURINE',
    '탱크': 'TANK',
    '터치': 'Touch',
    '테디 베어': 'Teddy Bear',
    '토크 쌕시': 'Talk Saxy',
    '톰보이': 'TOMBOY',
    '티 셔츠': 'T-SHIRT',
    '티티': 'TT',
    '티피 토스': 'Tippy Toes',
    '틱-택': 'Tick-Tack',
    '파티 오 클락': 'Party O\'Clock',
    '팝': 'POP!',
    '팬시': 'FANCY',
    '퍼펙트 나잇': 'Perfect Night',
    '퍼펫 쇼': 'PUPPET SHOW',
    '포에버': 'FOREVER',
    '폴라로이드 러브': 'Polaroid Love',
    '퓨처 퍼펙트': 'Future Perfect (Pass the MIC)',
    '플라워': 'FLOWER',
    '플롯 트위스트': 'Plot Twist',
    '피버': 'Fever',
    '필 더 팝': 'Feel the POP',
    '필 마이 리듬': 'Feel My Rhythm',
    '필 스페셜': 'Feel Special',
    '하우 스위트': 'How Sweet',
    '할라지아': 'HALAZIA',
    '할라할라': 'HALA HALA',
    '핫': 'HOT',
    '행복한 척': 'Pretend',
    '헤븐': 'Heaven',
    '헬로 퓨처': 'Hello Future',
    '히어': 'Here',
    '힙': 'HIT',
  };

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

  /// celebrities.json 의 nameEn — 전 223명 완비 (R106 P5 영어 carrier).
  final String nameEn;

  final String dayPillar;

  /// celebrities.json 의 kind — "idol" / "actor" / "athlete" / "icon".
  /// 누락된 entry 는 "idol" 로 안전 기본값 (legacy seedForTest 호환).
  final String kind;

  const _Celeb({
    required this.id,
    required this.nameKo,
    required this.nameEn,
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
        nameEn: j['nameEn'] as String? ?? '',
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
