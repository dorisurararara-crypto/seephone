// Test ziwei_core 1995-10-27 15:43 사용자
// ignore_for_file: avoid_print
import 'package:ziwei_core/ziwei_core.dart';

void main() {
  final ruleset = ConfigLoader.getDefault();
  final birthday = AstroDateTime(1995, 10, 27, 15, 43);
  final ziweiDate = ZiweiDate.fromSolar(birthday, gender: Gender.male);
  final plate = ZiweiEngine.calculate(ziweiDate, ruleset);

  print('=== 1995-10-27 15:43 남자 자미두수 명반 ===');
  print('命主: ${plate.mingZhu}');
  print('身主: ${plate.shenZhu}');
  print('');
  print('명궁 index: ${plate.originMingPalace.index}');
  print('신궁 index: ${plate.bodyPalace.index}');
  print('');
  print('=== 12궁 별성 분포 ===');
  for (var palace in plate.palaces) {
    String tags = '';
    if (palace.index == plate.originMingPalace.index) tags += '[命宮] ';
    if (palace.index == plate.bodyPalace.index) tags += '[身宮] ';
    final allStarKeys = palace.allStars
        .map((s) => '${s.key}(${s.type.name})')
        .toList();
    print(
        '地支[${palace.branch.name}] 宫干[${palace.stem?.name ?? ""}] $tags');
    print('  - 星曜: $allStarKeys');
  }
}
