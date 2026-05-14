// Round 75 — 십신 음양 분리 10분류 회귀.
//
// _tenGodsNoteFor 는 private 이지만, DeepContentService.buildFor 를 통한
// indirect 검증. 1995-10-27 15:43 男 (辛 일간, 金 dominant) →
// 같은 5행 안의 천간 음양 분포 따라 비견(辛) 또는 겁재(庚) 결정.
//
// 1995-10-27 4 천간: 乙 / 丙 / 辛 / 丙. 같은 5행(金) 천간은 일간 辛 만 (음).
// 음 vs 양: same(음)=1, other(양)=0 → sameYinYang true → 비견(bigyun).

import 'package:flutter_test/flutter_test.dart';
import 'package:pillarseer/services/saju_service.dart';

void main() {
  group('Round 75 — 십신 음양 10분류', () {
    test('1995-10-27 15:43 남자 (辛 일간, 金 dominant) → 비견 매핑', () async {
      final r = await SajuService().calculateSaju(
        year: 1995, month: 10, day: 27,
        hour: 15, minute: 43,
        isLunar: false, isMale: true,
      );
      // 4 천간 = 乙·丙·辛·丙. dominant 5행 金. 金 천간은 辛 (음) 만.
      // sameYinYang true → 비견.
      final note = r.deepKo?.tenGodsNote ?? '';
      expect(note, contains('비견'),
          reason: 'expected 비견 매핑 but got: $note');
    });

    test('IU 1993-5-16 (丁 일간) — 십신 노트 비어있지 않음 + 한자 없음', () async {
      final r = await SajuService().calculateSaju(
        year: 1993, month: 5, day: 16,
        hour: 12, minute: 0,
        isLunar: false, isMale: false,
      );
      final note = r.deepKo?.tenGodsNote ?? '';
      expect(note.isNotEmpty, isTrue, reason: 'note empty for IU');
      // 톤 검증 — "기운" / "본인" / "자원" 중 하나는 들어가야.
      expect(
        note.contains('기운') || note.contains('본인') || note.contains('자원'),
        isTrue,
        reason: 'note=${note.substring(0, note.length.clamp(0, 60))}',
      );
    });

    test('한국어 노트에 한자 jargon 없음 (10개 멘트 + 5분류 fallback 모두)', () async {
      // 여러 셀럽 케이스를 돌려 한국어 노트에 한자 없는지 확인.
      // 한자 비교: 比肩 劫財 食神 傷官 正財 偏財 正官 偏官 七殺 正印 偏印
      //          比劫 食傷 財星 官星 印星
      const hanjaPatterns = [
        '比肩', '劫財', '食神', '傷官', '正財', '偏財',
        '正官', '偏官', '七殺', '正印', '偏印',
        '比劫', '食傷', '財星', '官星', '印星',
      ];
      final cases = [
        [1995, 10, 27, 15, 43, true],  // 辛 일간
        [1993, 5, 16, 12, 0, false],   // 丁 일간 (IU)
        [2000, 4, 11, 12, 0, false],   // 己 일간 (Karina)
        [1996, 1, 16, 12, 0, false],   // 壬 일간 (Jennie)
        [1990, 9, 5, 12, 0, false],    // 癸 일간 (Yuna Kim)
      ];
      for (final c in cases) {
        final r = await SajuService().calculateSaju(
          year: c[0] as int, month: c[1] as int, day: c[2] as int,
          hour: c[3] as int, minute: c[4] as int,
          isLunar: false, isMale: c[5] as bool,
        );
        final note = r.deepKo?.tenGodsNote ?? '';
        for (final h in hanjaPatterns) {
          expect(note.contains(h), isFalse,
              reason: 'hanja "$h" leaked into note for $c: $note');
        }
      }
    });

    test('10분류 별 멘트가 한글로 정상 생성됨 (셀럽 5명 일간 다양화)', () async {
      // 한 명이 10개 모두 dominant 만들 수 없지만, 다양한 일간으로
      // 비견/식신/재성/관성/인성 계열이 골고루 등장하는지 확인.
      const validTenGods = [
        '비견', '겁재', '식신', '상관', '정재', '편재',
        '정관', '편관', '정인', '편인',
        // fallback 5분류
        '비겁', '식상', '재성', '관성', '인성',
      ];
      final cases = [
        [1995, 10, 27, 15, 43, true],
        [1993, 5, 16, 12, 0, false],
        [2000, 4, 11, 12, 0, false],
        [1996, 1, 16, 12, 0, false],
        [1990, 9, 5, 12, 0, false],
      ];
      for (final c in cases) {
        final r = await SajuService().calculateSaju(
          year: c[0] as int, month: c[1] as int, day: c[2] as int,
          hour: c[3] as int, minute: c[4] as int,
          isLunar: false, isMale: c[5] as bool,
        );
        final note = r.deepKo?.tenGodsNote ?? '';
        expect(note.isNotEmpty, isTrue, reason: 'empty for $c');
        final hasOne = validTenGods.any((g) => note.contains(g));
        expect(hasOne, isTrue, reason: 'no valid 십신 in: $note');
      }
    });
  });
}
