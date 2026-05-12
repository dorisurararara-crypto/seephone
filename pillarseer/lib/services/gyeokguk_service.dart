// Pillar Seer — 격국(格局) 분류 서비스.
//
// 격국: 사주 원국의 구조 분류. 명리학에서 가장 핵심.
// 월지(月支)의 본기(本氣) 가 일간 기준 어떤 십신이냐로 결정.
//
// 정격(正格) 8개:
// 1. 정관격 (正官格) — 월지 정관
// 2. 편관격 (偏官格, 七殺) — 월지 편관
// 3. 정인격 (正印格) — 월지 정인
// 4. 편인격 (偏印格) — 월지 편인
// 5. 정재격 (正財格) — 월지 정재
// 6. 편재격 (偏財格) — 월지 편재
// 7. 식신격 (食神格) — 월지 식신
// 8. 상관격 (傷官格) — 월지 상관
//
// 그 외 일간이 월지 본기인 경우 → "건록격(建祿格)" 또는 "양인격(陽刃格)" (특수격).

import 'ten_gods_service.dart';
import '../models/saju_result.dart';

class GyeokgukService {
  /// 일간 + 월지 → 격국 이름.
  /// dayMaster: 천간 (甲乙丙丁戊己庚辛壬癸).
  /// monthJi: 지지 (子丑寅...亥).
  static ({String name, String nameEn, String desc, String descEn}) judge({
    required String dayMaster,
    required String monthJi,
  }) {
    final god = TenGodsService.godForJiJi(dayMaster, monthJi);
    if (god == null) {
      return (
        name: '불명',
        nameEn: 'Unknown',
        desc: '월지 본기 십신을 판정할 수 없습니다.',
        descEn: 'Cannot determine month-branch ten-god.',
      );
    }
    return _gyeokgukOf(god);
  }

  /// 십신 → 격국 + 설명.
  static ({String name, String nameEn, String desc, String descEn})
      _gyeokgukOf(TenGod god) {
    switch (god) {
      case TenGod.jeonggwan:
        return (
          name: '정관격 (正官格)',
          nameEn: 'Right Officer (正官)',
          desc: '책임감·명예·사회적 인정의 결. 조직·공직·관리직에서 빛납니다. 보수적이고 안정적인 길.',
          descEn:
              'Responsibility, honor, social recognition. Shines in organization/civic roles. Conservative, stable path.',
        );
      case TenGod.pyeongwan:
        return (
          name: '편관격 (偏官格 / 七殺)',
          nameEn: 'Seven Killings (七殺)',
          desc: '강한 추진력·승부근성. 도전적·창업가형. 잘 다루면 큰 권위, 못 다루면 사고.',
          descEn:
              'Strong drive, competitive edge. Entrepreneur type. Handled well: big authority. Poorly: trouble.',
        );
      case TenGod.jeongin:
        return (
          name: '정인격 (正印格)',
          nameEn: 'Right Seal (正印)',
          desc: '학문·교육·자비의 결. 멘토·교수·연구원형. 후원받고 공부하는 사주.',
          descEn:
              'Study, teaching, compassion. Mentor/professor/researcher type. Supported by elders.',
        );
      case TenGod.pyeonin:
        return (
          name: '편인격 (偏印格)',
          nameEn: 'Oblique Seal (偏印)',
          desc: '특수 학문·종교·예술의 결. 직관·외길. 학자·종교가·예술가형.',
          descEn:
              'Specialized study, religion, art. Intuitive and singular path. Scholar/clergy/artist type.',
        );
      case TenGod.jeongjae:
        return (
          name: '정재격 (正財格)',
          nameEn: 'Right Wealth (正財)',
          desc: '안정된 재물·결혼·가정의 결. 꾸준한 수입·신용. 사업·재정 관리에 강.',
          descEn:
              'Stable wealth, marriage, family. Steady income and credit. Strong in business/finance management.',
        );
      case TenGod.pyeonjae:
        return (
          name: '편재격 (偏財格)',
          nameEn: 'Oblique Wealth (偏財)',
          desc: '큰 재물·기회 포착의 결. 무역·투자·사교형. 돈이 들어오는 만큼 나가기도.',
          descEn:
              'Big money, opportunity-spotter. Trade/investment/socializer. Money flows in and out big.',
        );
      case TenGod.siksin:
        return (
          name: '식신격 (食神格)',
          nameEn: 'Eating God (食神)',
          desc: '표현·창작·여유의 결. 작가·강사·요리·예술 등. 베푸는 만큼 받는 사주.',
          descEn:
              'Expression, creation, ease. Writer/teacher/cook/artist. Giving brings receiving.',
        );
      case TenGod.sanggwan:
        return (
          name: '상관격 (傷官格)',
          nameEn: 'Hurting Officer (傷官)',
          desc: '재능·예술·반골의 결. 똑똑하지만 권위에 약함. 자기 표현이 자원.',
          descEn:
              'Talent, art, rebellion. Brilliant but anti-authority. Self-expression is the asset.',
        );
      case TenGod.bigyeon:
        return (
          name: '건록격 (建祿格)',
          nameEn: 'Salaried Rank (建祿)',
          desc: '월지 비견 — 일간 강함. 독립적·자수성가형. 자기 결로 사는 사주.',
          descEn:
              'Month-branch matches day stem — strong. Independent, self-made. Lives by own grain.',
        );
      case TenGod.geopjae:
        return (
          name: '양인격 (陽刃格)',
          nameEn: 'Sun Blade (陽刃)',
          desc: '월지 겁재 — 강한 살. 무관·검사·체육 등 강한 결의 직군. 잘 다루면 권위, 못 다루면 충돌.',
          descEn:
              'Month-branch is rob-wealth — strong blade. Military/legal/athletic types. Handled well: authority.',
        );
    }
  }
}
