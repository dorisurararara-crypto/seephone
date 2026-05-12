// Pillar Seer — 12 운성(運星) 서비스.
//
// 12 운성: 일간(천간)이 12지지 각각에 대해 가지는 생애 단계 강약.
// 사람의 일생 (잉태~죽음~다시 잉태) 12 phase 으로 표현.
//
// 12 단계:
//   장생(長生) - 새 생명의 시작 (강함의 첫 단계)
//   목욕(沐浴) - 갓 태어난 단계 (불안정)
//   관대(冠帶) - 청소년기 (성장)
//   임관(臨官) - 성인 입신 (강함의 절정 직전)
//   제왕(帝王) - 절정 (가장 강함)
//   쇠(衰)    - 절정 후 쇠퇴
//   병(病)    - 약해짐
//   사(死)    - 죽음 (약함의 절정 직전)
//   묘(墓)    - 무덤 (저장)
//   절(絶)    - 단절 (가장 약함)
//   태(胎)    - 다시 잉태 (재시작)
//   양(養)    - 양육 (회복)
//
// 일간별 12 운성 시작 지지 (장생):
//   甲 → 亥, 乙 → 午, 丙 → 寅, 丁 → 酉, 戊 → 寅, 己 → 酉,
//   庚 → 巳, 辛 → 子, 壬 → 申, 癸 → 卯
// 음양 천간별 진행 방향:
//   양 천간(甲丙戊庚壬) → 12지 순행 (자→축→인...)
//   음 천간(乙丁己辛癸) → 12지 역행

class TwelveUnsungService {
  static const List<String> stages = [
    '장생', '목욕', '관대', '임관', '제왕',
    '쇠', '병', '사', '묘', '절', '태', '양',
  ];

  static const List<String> stagesEn = [
    'Birth', 'Bath', 'Cap', 'Office', 'Peak',
    'Decline', 'Illness', 'Death', 'Tomb', 'Severed', 'Womb', 'Nurture',
  ];

  /// 12 지지 인덱스 (子=0 ... 亥=11).
  static const List<String> _ji = [
    '子', '丑', '寅', '卯', '辰', '巳', '午', '未', '申', '酉', '戌', '亥',
  ];

  /// 양 천간 → true, 음 → false.
  static const Map<String, bool> _isYang = {
    '甲': true, '丙': true, '戊': true, '庚': true, '壬': true,
    '乙': false, '丁': false, '己': false, '辛': false, '癸': false,
  };

  /// 일간 천간 → 장생 지지.
  static const Map<String, String> _jangsaengStart = {
    '甲': '亥',
    '乙': '午',
    '丙': '寅',
    '丁': '酉',
    '戊': '寅',
    '己': '酉',
    '庚': '巳',
    '辛': '子',
    '壬': '申',
    '癸': '卯',
  };

  /// 일간 천간 + 임의 지지 → 12 운성 단계 (인덱스 0=장생 ... 11=양).
  static int stageIndex(String dayChunGan, String ji) {
    final start = _jangsaengStart[dayChunGan];
    final yang = _isYang[dayChunGan];
    if (start == null || yang == null) return -1;
    final startIdx = _ji.indexOf(start);
    final jiIdx = _ji.indexOf(ji);
    if (startIdx < 0 || jiIdx < 0) return -1;
    if (yang) {
      // 순행: startIdx → 0번 stage, startIdx+1 → 1번 stage, ... mod 12
      return ((jiIdx - startIdx) % 12 + 12) % 12;
    } else {
      // 역행: startIdx → 0, startIdx-1 → 1, ...
      return ((startIdx - jiIdx) % 12 + 12) % 12;
    }
  }

  /// 일간 + 지지 → 단계 이름 (한국어).
  static String stageNameKo(String dayChunGan, String ji) {
    final idx = stageIndex(dayChunGan, ji);
    if (idx < 0) return '';
    return stages[idx];
  }

  static String stageNameEn(String dayChunGan, String ji) {
    final idx = stageIndex(dayChunGan, ji);
    if (idx < 0) return '';
    return stagesEn[idx];
  }

  /// 사주 4기둥의 일간 vs 4지지 → 4개 운성 단계.
  /// year/month/day/hour 각각의 강약 (12 운성) 반환.
  /// 강함 순: 제왕(4) > 임관(3) > 관대(2) > 장생(0) ≈ 양(11) > 목욕(1) > 쇠(5) > 병(6) > 양(11) > 태(10) > 묘(8) > 사(7) > 절(9)
  /// 단순화: idx 0~5 = 강함 계열, 6~9 = 약함, 10~11 = 회복.
  static Map<String, String> chartStages({
    required String dayChunGan,
    required String yearJi,
    required String monthJi,
    required String dayJi,
    String? hourJi,
  }) {
    final out = <String, String>{
      'year': stageNameKo(dayChunGan, yearJi),
      'month': stageNameKo(dayChunGan, monthJi),
      'day': stageNameKo(dayChunGan, dayJi),
    };
    if (hourJi != null) {
      out['hour'] = stageNameKo(dayChunGan, hourJi);
    }
    return out;
  }

  /// 단계 → 한 줄 의미 (한국어).
  static String interpretation(String stage, {bool ko = false}) {
    if (ko) {
      const koMap = {
        '장생': '갓 태어난 결 — 새 일의 시작에 강합니다.',
        '목욕': '청소년기 결 — 불안정하지만 매력 있음.',
        '관대': '청년 결 — 성장 속도가 빠릅니다.',
        '임관': '성인 결 — 사회적 입신에 강.',
        '제왕': '절정 결 — 가장 강한 운기.',
        '쇠': '절정 후 — 한 박자 늦춰야 할 시기.',
        '병': '약해짐 — 보호하고 회복하세요.',
        '사': '결의 끝 — 정리와 마무리.',
        '묘': '저장 — 보이지 않는 축적이 큼.',
        '절': '단절 — 가장 약하지만 새 사이클의 시작 전.',
        '태': '다시 잉태 — 새 가능성의 씨앗.',
        '양': '양육 결 — 부드럽게 키워가는 시기.',
      };
      return koMap[stage] ?? '';
    }
    const enMap = {
      '장생': 'Birth — strong at fresh beginnings.',
      '목욕': 'Bath — unstable but magnetic.',
      '관대': 'Cap — rapid growth phase.',
      '임관': 'Office — strong civic/social positioning.',
      '제왕': 'Peak — strongest momentum.',
      '쇠': 'Decline — slow by one beat.',
      '병': 'Illness — protect and recover.',
      '사': 'Death — wrap up and close.',
      '묘': 'Tomb — unseen accumulation matters.',
      '절': 'Severed — weakest yet pre-cycle.',
      '태': 'Womb — seed of new possibility.',
      '양': 'Nurture — gentle cultivation.',
    };
    return enMap[stage] ?? '';
  }
}
