// Pillar Seer — 2026 KASI 12절 calendar (source of truth).
//
// 이 파일은 2026년 명리학 월건 계산을 위한 12절 절입시각 KST.
// 출처: KASI 월력요항 (천체력 기반, ±20분 정확도).
// 화면(_NewYear2026Screen) 과 테스트(new_year_2026_test) 가 모두 이 데이터를 참조.

/// 한 절기의 모든 메타.
class JolSlot {
  /// KST 절입 시각.
  final DateTime dateTime;
  /// 月支 (寅 卯 辰 巳 午 未 申 酉 戌 亥 子 丑).
  final String monthBranch;
  /// 月干 — 丙년 五虎遁 기준.
  final String monthStem;
  /// 절기 한국어 이름 (예: '입춘').
  final String nameKo;
  /// 절기 영어/병음 (예: 'Ipchun').
  final String nameEn;
  /// SolarTermService.jolLongitudes 인덱스 (0=입춘 ... 11=소한).
  final int jolIndex;

  const JolSlot({
    required this.dateTime,
    required this.monthBranch,
    required this.monthStem,
    required this.nameKo,
    required this.nameEn,
    required this.jolIndex,
  });

  /// "1/5 17:23" 형식 (KO 화면용).
  String get displayKo =>
      '$nameKo ${dateTime.month}/${dateTime.day} '
      '${dateTime.hour.toString().padLeft(2, '0')}:'
      '${dateTime.minute.toString().padLeft(2, '0')}';

  /// "Ipchun · Feb 4 05:02" 형식 (EN 화면용).
  String get displayEn {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '$nameEn · ${months[dateTime.month - 1]} ${dateTime.day} '
        '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

/// 2026년 KASI 12절 절입시각 (KST).
///
/// 출처: KASI 월력요항 2026 기준 ±20분 권장 허용오차.
/// 명리학 월건 = 12절(입춘·경칩·청명·입하·망종·소서·입추·백로·한로·입동·대설·소한).
/// 중기(우수·춘분 등)는 월건 변경에 사용 X.
///
/// 인덱스 순서 = SolarTermService.jolLongitudes 와 동일 (0=입춘 ... 11=소한).
/// 단, 양력 1월 시점에는 작년의 소한이 이미 시작된 상태 (월건 = 丑).
/// 따라서 화면 표시는 1월=소한 → 12월=대설 순으로 진행.
class JolCalendar2026 {
  /// SolarTermService 인덱스(0=입춘 ... 11=소한) → JolSlot.
  /// 丙년 五虎遁: 寅 庚, 卯 辛, 辰 壬, 巳 癸, 午 甲, 未 乙, 申 丙, 酉 丁, 戌 戊, 亥 己, 子 庚, 丑 辛.
  static final List<JolSlot> _bySolarTermIndex = [
    JolSlot(
      dateTime: DateTime(2026, 2, 4, 5, 2),
      monthBranch: '寅', monthStem: '庚',
      nameKo: '입춘', nameEn: 'Ipchun', jolIndex: 0,
    ),
    JolSlot(
      dateTime: DateTime(2026, 3, 5, 22, 58),
      monthBranch: '卯', monthStem: '辛',
      nameKo: '경칩', nameEn: 'Gyeongchip', jolIndex: 1,
    ),
    JolSlot(
      dateTime: DateTime(2026, 4, 5, 3, 39),
      monthBranch: '辰', monthStem: '壬',
      nameKo: '청명', nameEn: 'Cheongmyeong', jolIndex: 2,
    ),
    JolSlot(
      dateTime: DateTime(2026, 5, 5, 20, 48),
      monthBranch: '巳', monthStem: '癸',
      nameKo: '입하', nameEn: 'Ipha', jolIndex: 3,
    ),
    JolSlot(
      dateTime: DateTime(2026, 6, 6, 0, 48),
      monthBranch: '午', monthStem: '甲',
      nameKo: '망종', nameEn: 'Mangjong', jolIndex: 4,
    ),
    JolSlot(
      dateTime: DateTime(2026, 7, 7, 10, 56),
      monthBranch: '未', monthStem: '乙',
      nameKo: '소서', nameEn: 'Soseo', jolIndex: 5,
    ),
    JolSlot(
      dateTime: DateTime(2026, 8, 7, 20, 42),
      monthBranch: '申', monthStem: '丙',
      nameKo: '입추', nameEn: 'Ipchu', jolIndex: 6,
    ),
    JolSlot(
      dateTime: DateTime(2026, 9, 7, 23, 41),
      monthBranch: '酉', monthStem: '丁',
      nameKo: '백로', nameEn: 'Baekro', jolIndex: 7,
    ),
    JolSlot(
      dateTime: DateTime(2026, 10, 8, 15, 29),
      monthBranch: '戌', monthStem: '戊',
      nameKo: '한로', nameEn: 'Hanro', jolIndex: 8,
    ),
    JolSlot(
      dateTime: DateTime(2026, 11, 7, 18, 52),
      monthBranch: '亥', monthStem: '己',
      nameKo: '입동', nameEn: 'Ipdong', jolIndex: 9,
    ),
    JolSlot(
      dateTime: DateTime(2026, 12, 7, 11, 52),
      monthBranch: '子', monthStem: '庚',
      nameKo: '대설', nameEn: 'Daeseol', jolIndex: 10,
    ),
    JolSlot(
      // 소한 — 양력 1월 5일. (이는 2026년 양력 1월의 소한)
      dateTime: DateTime(2026, 1, 5, 17, 23),
      monthBranch: '丑', monthStem: '辛',
      nameKo: '소한', nameEn: 'Sohan', jolIndex: 11,
    ),
  ];

  /// 화면 표시 순서 = 양력 1월 → 12월 (소한, 입춘, 경칩, ..., 대설).
  /// 양력 1월은 이미 소한 시점(전년 12/7~다음 1/5 사이)이므로 1월 = 丑월.
  static List<JolSlot> get displayOrder => [
        _bySolarTermIndex[11], // 1월 소한 · 丑
        _bySolarTermIndex[0],  // 2월 입춘 · 寅
        _bySolarTermIndex[1],  // 3월 경칩 · 卯
        _bySolarTermIndex[2],  // 4월 청명 · 辰
        _bySolarTermIndex[3],  // 5월 입하 · 巳
        _bySolarTermIndex[4],  // 6월 망종 · 午
        _bySolarTermIndex[5],  // 7월 소서 · 未
        _bySolarTermIndex[6],  // 8월 입추 · 申
        _bySolarTermIndex[7],  // 9월 백로 · 酉
        _bySolarTermIndex[8],  // 10월 한로 · 戌
        _bySolarTermIndex[9],  // 11월 입동 · 亥
        _bySolarTermIndex[10], // 12월 대설 · 子
      ];

  /// SolarTermService 인덱스(0=입춘 ... 11=소한) 기준 슬롯.
  /// 테스트에서 SolarTermService.jolDateTime() 과 직접 비교용.
  static JolSlot byJolIndex(int jolIndex) {
    if (jolIndex < 0 || jolIndex > 11) {
      throw RangeError('jolIndex must be 0..11, got $jolIndex');
    }
    return _bySolarTermIndex[jolIndex];
  }

  /// 12절 전체 (SolarTermService.jolLongitudes 순서).
  static List<JolSlot> get all => List.unmodifiable(_bySolarTermIndex);

}
