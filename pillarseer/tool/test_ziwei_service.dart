// ZiweiService 테스트 — 1995-10-27 15:43 남자.
// ignore_for_file: avoid_print

import 'package:pillarseer/services/ziwei_service.dart';

void main() {
  final r = ZiweiService.calculate(
    year: 1995,
    month: 10,
    day: 27,
    hour: 15,
    minute: 43,
    isMale: true,
  );

  print('=== 자미두수 명반 (1995-10-27 15:43 남) ===');
  print('명주: ${r.mingZhuKo} (${r.mingZhuKey})');
  print('신주: ${r.shenZhuKo} (${r.shenZhuKey})');
  print('');
  print('명궁: ${r.mingPalace.headerKo}');
  print('  주성: ${r.mingPalace.majorStars.map((s) => s.nameKo).toList()}');
  print('  길성: ${r.mingPalace.luckyStars}');
  print('  흉성: ${r.mingPalace.badStars}');
  print('');
  print('신궁: ${r.shenPalace.headerKo}');
  print('  주성: ${r.shenPalace.majorStars.map((s) => s.nameKo).toList()}');
  print('  길성: ${r.shenPalace.luckyStars}');
  print('  흉성: ${r.shenPalace.badStars}');
  print('');
  print('=== 12궁 전체 ===');
  for (final p in r.by12Gung) {
    final tag =
        '${p.isMingPalace ? '[명궁] ' : ''}${p.isShenPalace ? '[신궁] ' : ''}';
    print('${p.headerKo}$tag');
    if (p.majorStars.isNotEmpty) {
      print('  주성: ${p.majorStars.map((s) => s.nameKo).toList()}');
      print('  풀이: ${p.majorStars.first.oneLineKo}');
    }
    if (p.luckyStars.isNotEmpty) print('  길성: ${p.luckyStars}');
    if (p.badStars.isNotEmpty) print('  흉성: ${p.badStars}');
  }
}
