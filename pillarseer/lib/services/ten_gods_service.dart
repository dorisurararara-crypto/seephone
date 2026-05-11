// Pillar Seer — 십신(十神) 계산 서비스.
// 일간(日干) 기준으로 다른 천간/지지의 5행 + 음양 관계를 10가지 십신으로 분류.

import '../models/saju_result.dart';

class TenGodsService {
  /// 천간 음양 (양=true, 음=false)
  static const _ganYang = {
    '甲': true, '乙': false,
    '丙': true, '丁': false,
    '戊': true, '己': false,
    '庚': true, '辛': false,
    '壬': true, '癸': false,
  };

  /// 천간 5행
  static const _ganElement = {
    '甲': '木', '乙': '木',
    '丙': '火', '丁': '火',
    '戊': '土', '己': '土',
    '庚': '金', '辛': '金',
    '壬': '水', '癸': '水',
  };

  /// 지지 본기 천간 — 지지의 대표 천간(5행 + 음양)
  /// 지지 자체는 6양/6음, 지장간(支藏干) 중 본기로 단순화
  static const _jiBongi = {
    '子': '癸', '丑': '己', '寅': '甲', '卯': '乙',
    '辰': '戊', '巳': '丙', '午': '丁', '未': '己',
    '申': '庚', '酉': '辛', '戌': '戊', '亥': '壬',
  };

  /// 5행 상생: 木→火→土→金→水→木
  static const _generates = {
    '木': '火', '火': '土', '土': '金', '金': '水', '水': '木',
  };

  /// 5행 상극: 木→土→水→火→金→木
  static const _overcomes = {
    '木': '土', '土': '水', '水': '火', '火': '金', '金': '木',
  };

  /// 일간 기준, 다른 천간의 십신 결정
  static TenGod? godFor(String dayMaster, String otherGan) {
    final dmEl = _ganElement[dayMaster];
    final otEl = _ganElement[otherGan];
    if (dmEl == null || otEl == null) return null;
    final dmYang = _ganYang[dayMaster] ?? true;
    final otYang = _ganYang[otherGan] ?? true;
    final samePolar = dmYang == otYang;

    if (dmEl == otEl) {
      return samePolar ? TenGod.bigyeon : TenGod.geopjae;
    }
    // 내가 생함 (output)
    if (_generates[dmEl] == otEl) {
      return samePolar ? TenGod.siksin : TenGod.sanggwan;
    }
    // 내가 극함 (wealth)
    if (_overcomes[dmEl] == otEl) {
      return samePolar ? TenGod.pyeonjae : TenGod.jeongjae;
    }
    // 나를 극함 (authority)
    if (_overcomes[otEl] == dmEl) {
      return samePolar ? TenGod.pyeongwan : TenGod.jeonggwan;
    }
    // 나를 생함 (resource)
    if (_generates[otEl] == dmEl) {
      return samePolar ? TenGod.pyeonin : TenGod.jeongin;
    }
    return null;
  }

  /// 지지의 십신 (본기 기준)
  static TenGod? godForJiJi(String dayMaster, String jiJi) {
    final bongi = _jiBongi[jiJi];
    if (bongi == null) return null;
    return godFor(dayMaster, bongi);
  }

  /// 사주 4기둥 → 십신 row 리스트
  static List<TenGodRow> tableFor(SajuResult saju) {
    final dm = saju.dayMaster;
    final rows = <TenGodRow>[
      TenGodRow(
        position: 'year',
        chunGanGod: godFor(dm, saju.yearPillar.chunGan),
        jiJiGod: godForJiJi(dm, saju.yearPillar.jiJi),
      ),
      TenGodRow(
        position: 'month',
        chunGanGod: godFor(dm, saju.monthPillar.chunGan),
        jiJiGod: godForJiJi(dm, saju.monthPillar.jiJi),
      ),
      TenGodRow(
        position: 'day',
        chunGanGod: null, // 일간 자신은 비견
        jiJiGod: godForJiJi(dm, saju.dayPillar.jiJi),
      ),
      if (saju.hourPillar != null)
        TenGodRow(
          position: 'hour',
          chunGanGod: godFor(dm, saju.hourPillar!.chunGan),
          jiJiGod: godForJiJi(dm, saju.hourPillar!.jiJi),
        ),
    ];
    return rows;
  }
}
