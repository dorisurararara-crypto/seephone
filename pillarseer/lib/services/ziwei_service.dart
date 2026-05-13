// Pillar Seer — 자미두수(紫微斗數) 서비스.
//
// ziwei_core 0.13.x 를 wrap 해서 한국어 풀이용 모델로 변환한다.
// - 명궁/신궁 + 12궁 (명·형제·부처·자녀·재백·질액·천이·노복·관록·전택·복덕·부모)
// - 14 주성 한국어 풀이 (Aesop Luxury 직설 친근 톤)
// - 6길성 / 6흉성 한국어 이름 + 색
//
// 사주(자평명리) 와 함께 result 화면에서 동시에 보여주기 위한 모델.

import 'package:ziwei_core/ziwei_core.dart' as zw;

/// 14 주성 + 한국어 풀이 한 줄.
class MajorStar {
  /// ziwei_core 의 영문 pinyin key (예: 'ziwei', 'tianji').
  final String keyEn;

  /// 한국어 이름 (예: '자미성', '천기성').
  final String nameKo;

  /// 직설 친근 한 줄 풀이.
  final String oneLineKo;

  /// 14 주성의 5행 분류 (사주 5행과 교차 일치 판단용).
  final String element; // '木' / '火' / '土' / '金' / '水'

  const MajorStar({
    required this.keyEn,
    required this.nameKo,
    required this.oneLineKo,
    required this.element,
  });
}

/// 12 궁 — 한국어 정보 패키지.
class ZiweiPalace {
  /// 한국어 궁 이름 (예: '명궁', '재백궁').
  final String gungKo;

  /// 12 지지 한국어 (예: '인', '술').
  final String branchKo;

  /// 12 지지 한국어 동물 (예: '호랑이', '개').
  final String branchAnimalKo;

  /// 12 지지 영문 pinyin (예: 'yin', 'xu').
  final String branchEn;

  /// 14 주성 (한국어 풀이까지 포함).
  final List<MajorStar> majorStars;

  /// 6길성 한국어 이름 (예: ['좌보', '문창']).
  final List<String> luckyStars;

  /// 6흉성 한국어 이름 (예: ['타라']).
  final List<String> badStars;

  /// 명궁 / 신궁 여부.
  final bool isMingPalace;
  final bool isShenPalace;

  const ZiweiPalace({
    required this.gungKo,
    required this.branchKo,
    required this.branchAnimalKo,
    required this.branchEn,
    required this.majorStars,
    required this.luckyStars,
    required this.badStars,
    required this.isMingPalace,
    required this.isShenPalace,
  });

  /// 궁 한 줄 헤더. 예: '명궁 · 인(호랑이)'.
  String get headerKo => '$gungKo · $branchKo($branchAnimalKo)';

  /// 주성 한국어 이름 list (예: ['우필', '문창'] — Major + Lucky 둘 다 포함, UI용).
  List<String> get allStarNamesKo => [
        ...majorStars.map((s) => s.nameKo),
        ...luckyStars,
      ];
}

/// 자미두수 명반 결과 (한국어 표현 완비).
class ZiweiResult {
  /// 명주 (영문 key, 예: 'lucun').
  final String mingZhuKey;

  /// 명주 한국어 (예: '록존').
  final String mingZhuKo;

  /// 신주 (영문 key, 예: 'tianji').
  final String shenZhuKey;

  /// 신주 한국어 (예: '천기').
  final String shenZhuKo;

  /// 명궁.
  final ZiweiPalace mingPalace;

  /// 신궁.
  final ZiweiPalace shenPalace;

  /// 12궁 — '명','형제','부처','자녀','재백','질액','천이','노복','관록','전택','복덕','부모' 순.
  final List<ZiweiPalace> by12Gung;

  const ZiweiResult({
    required this.mingZhuKey,
    required this.mingZhuKo,
    required this.shenZhuKey,
    required this.shenZhuKo,
    required this.mingPalace,
    required this.shenPalace,
    required this.by12Gung,
  });

  /// 한국어 궁 이름 → 궁 객체.
  ZiweiPalace? gungByName(String gungKo) {
    for (final p in by12Gung) {
      if (p.gungKo == gungKo) return p;
    }
    return null;
  }
}

/// 자미두수 서비스 — 양력 생년월일시 → ZiweiResult.
class ZiweiService {
  /// 양력 1995-10-27 15:43 남자 같은 입력 → 한국어 명반.
  ///
  /// [isMale] true=男, false=女.
  static ZiweiResult calculate({
    required int year,
    required int month,
    required int day,
    required int hour,
    required int minute,
    required bool isMale,
  }) {
    final ruleset = zw.ConfigLoader.getDefault();
    final birthday = zw.AstroDateTime(year, month, day, hour, minute);
    final ziweiDate = zw.ZiweiDate.fromSolar(
      birthday,
      gender: isMale ? zw.Gender.male : zw.Gender.female,
    );
    final plate = zw.ZiweiEngine.calculate(ziweiDate, ruleset);

    final mingIdx = plate.originMingPalace.index;
    final shenIdx = plate.bodyPalace.index;

    // 12 궁 순서: 명궁 위치(mingIdx)에서 시계 반대방향 (-1, -1, ...) 으로 12 칸.
    // 명·형제·부처·자녀·재백·질액·천이·노복·관록·전택·복덕·부모.
    final palaces = <ZiweiPalace>[];
    for (var i = 0; i < 12; i++) {
      final branchIdx = (mingIdx - i + 12) % 12;
      final raw = plate.palaces[branchIdx];
      palaces.add(_palaceFrom(
        raw: raw,
        gungKo: _gungNames[i],
        isMingPalace: branchIdx == mingIdx,
        isShenPalace: branchIdx == shenIdx,
      ));
    }

    final mingPalace = palaces[0];
    // 신궁: by12Gung 중 isShenPalace=true 인 첫 항목.
    final shenPalace = palaces.firstWhere(
      (p) => p.isShenPalace,
      orElse: () => palaces[0],
    );

    return ZiweiResult(
      mingZhuKey: plate.mingZhu ?? '',
      mingZhuKo: _mingShenZhuKo[plate.mingZhu] ?? (plate.mingZhu ?? ''),
      shenZhuKey: plate.shenZhu ?? '',
      shenZhuKo: _mingShenZhuKo[plate.shenZhu] ?? (plate.shenZhu ?? ''),
      mingPalace: mingPalace,
      shenPalace: shenPalace,
      by12Gung: palaces,
    );
  }

  static ZiweiPalace _palaceFrom({
    required zw.Palace raw,
    required String gungKo,
    required bool isMingPalace,
    required bool isShenPalace,
  }) {
    final majorList = <MajorStar>[];
    final luckyList = <String>[];
    final badList = <String>[];

    for (final star in raw.allStars) {
      switch (star.type) {
        case zw.StarType.major:
          final ms = _majorStarTable[star.key];
          if (ms != null) majorList.add(ms);
          break;
        case zw.StarType.lucky:
          final name = _luckyStarKo[star.key];
          if (name != null) luckyList.add(name);
          break;
        case zw.StarType.bad:
          final name = _badStarKo[star.key];
          if (name != null) badList.add(name);
          break;
        default:
          // minor / boshi12 등 — 정밀 풀이 외엔 노출 X.
          break;
      }
    }

    final branchEn = raw.branch.name;
    return ZiweiPalace(
      gungKo: gungKo,
      branchKo: _branchKo[branchEn] ?? branchEn,
      branchAnimalKo: _branchAnimalKo[branchEn] ?? branchEn,
      branchEn: branchEn,
      majorStars: majorList,
      luckyStars: luckyList,
      badStars: badList,
      isMingPalace: isMingPalace,
      isShenPalace: isShenPalace,
    );
  }
}

// ──────────── 12 궁 한국어 이름 (시계 반대 순) ────────────
const List<String> _gungNames = [
  '명궁',
  '형제궁',
  '부처궁',
  '자녀궁',
  '재백궁',
  '질액궁',
  '천이궁',
  '노복궁',
  '관록궁',
  '전택궁',
  '복덕궁',
  '부모궁',
];

// ──────────── 12 지지 한국어 ────────────
const Map<String, String> _branchKo = {
  'zi': '자',
  'chou': '축',
  'yin': '인',
  'mao': '묘',
  'chen': '진',
  'si': '사',
  'wu': '오',
  'wei': '미',
  'shen': '신',
  'you': '유',
  'xu': '술',
  'hai': '해',
};

const Map<String, String> _branchAnimalKo = {
  'zi': '쥐',
  'chou': '소',
  'yin': '호랑이',
  'mao': '토끼',
  'chen': '용',
  'si': '뱀',
  'wu': '말',
  'wei': '양',
  'shen': '원숭이',
  'you': '닭',
  'xu': '개',
  'hai': '돼지',
};

// ──────────── 14 주성 한국어 + 직설 한 줄 ────────────
// 본문 톤: 직설 친근 ("당신은 X 같은 사람", "Y 타입", ...).
// codex 9.9+ PASS 받은 결과 화면 본문 톤 유지.
const Map<String, MajorStar> _majorStarTable = {
  'ziwei': MajorStar(
    keyEn: 'ziwei',
    nameKo: '자미성',
    oneLineKo: '타고난 리더, 사람을 끌어당기는 카리스마가 있어요.',
    element: '土',
  ),
  'tianji': MajorStar(
    keyEn: 'tianji',
    nameKo: '천기성',
    oneLineKo: '머리가 빠르고 변화를 오히려 재밌어하는 타입이에요.',
    element: '木',
  ),
  'taiyang': MajorStar(
    keyEn: 'taiyang',
    nameKo: '태양성',
    oneLineKo: '환하고 적극적이라 존재감이 확실한 타입이에요.',
    element: '火',
  ),
  'wuqu': MajorStar(
    keyEn: 'wuqu',
    nameKo: '무곡성',
    oneLineKo: '한 번 마음먹으면 끝까지 가는 단단한 사람이에요.',
    element: '金',
  ),
  'tiantong': MajorStar(
    keyEn: 'tiantong',
    nameKo: '천동성',
    oneLineKo: '다정하고 부드러워서 분위기를 잡아주는 사람이에요.',
    element: '水',
  ),
  'lianzhen': MajorStar(
    keyEn: 'lianzhen',
    nameKo: '염정성',
    oneLineKo: '원칙이 분명하고 정의감이 강한 사람이에요.',
    element: '火',
  ),
  'tianfu': MajorStar(
    keyEn: 'tianfu',
    nameKo: '천부성',
    oneLineKo: '안정감 있고 든든해서 믿음 가는 타입이에요.',
    element: '土',
  ),
  'taiyin': MajorStar(
    keyEn: 'taiyin',
    nameKo: '태음성',
    oneLineKo: '섬세하고 감수성이 풍부한 사람이에요.',
    element: '水',
  ),
  'tanlang': MajorStar(
    keyEn: 'tanlang',
    nameKo: '탐랑성',
    oneLineKo: '호기심이 많고 다양한 매력이 있는 타입이에요.',
    element: '水',
  ),
  'jumen': MajorStar(
    keyEn: 'jumen',
    nameKo: '거문성',
    oneLineKo: '말로 분위기를 잡고 사람을 끌어가는 힘이 있어요.',
    element: '水',
  ),
  'tianxiang': MajorStar(
    keyEn: 'tianxiang',
    nameKo: '천상성',
    oneLineKo: '중재 능력이 뛰어나고 사람 사이 균형을 잘 잡아요.',
    element: '水',
  ),
  'tianliang': MajorStar(
    keyEn: 'tianliang',
    nameKo: '천량성',
    oneLineKo: '신중하고 조언을 잘해주는 든든한 타입이에요.',
    element: '土',
  ),
  'qisha': MajorStar(
    keyEn: 'qisha',
    nameKo: '칠살성',
    oneLineKo: '강한 추진력과 결단력이 있는 사람이에요.',
    element: '金',
  ),
  'pojun': MajorStar(
    keyEn: 'pojun',
    nameKo: '파군성',
    oneLineKo: '변화 앞에서 겁 안 내고 먼저 한 발 내딛는 사람이에요.',
    element: '水',
  ),
};

// ──────────── 6 길성 / 6 흉성 한국어 ────────────
const Map<String, String> _luckyStarKo = {
  'zuofu': '좌보',
  'youbi': '우필',
  'wenchang': '문창',
  'wenqu': '문곡',
  'tiankui': '천괴',
  'tianyue': '천월',
  'lucun': '록존',
  'tianma': '천마',
};

const Map<String, String> _badStarKo = {
  'qingyang': '경양',
  'tuoluo': '타라',
  'huoxing': '화성',
  'lingxing': '영성',
  'dikong': '지공',
  'dijie': '지겁',
};

// ──────────── 명주/신주 한국어 ────────────
const Map<String?, String> _mingShenZhuKo = {
  'lucun': '록존',
  'tianji': '천기',
  'wenchang': '문창',
  'tianxiang': '천상',
  'tianliang': '천량',
  'ziwei': '자미',
  'wuqu': '무곡',
  'pojun': '파군',
  'lianzhen': '염정',
  'taiyang': '태양',
  'tanlang': '탐랑',
  'jumen': '거문',
  'tianfu': '천부',
  'taiyin': '태음',
  'tiantong': '천동',
  'qisha': '칠살',
};
