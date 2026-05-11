// Dev tool — KASI 일주 검증용. lint suppression.
// ignore_for_file: avoid_print
import 'package:klc/klc.dart';
void main() {
  final dates = [
    (1993, 5, 16, 'IU'),
    (1995, 12, 30, 'BTS V'),
    (1995, 1, 3, 'Jisoo'),
    (1997, 9, 1, 'Jungkook'),
    (1990, 9, 5, 'Yuna Kim'),
    (1992, 7, 8, 'Son Heung-min'),
    (1996, 1, 16, 'Jennie'),
    (2000, 4, 11, 'Karina'),
    (1997, 2, 11, 'Rose'),
    (1997, 3, 27, 'Lisa'),
    (1990, 1, 25, 'Junho'),
    (1981, 11, 22, 'Song Hye-kyo'),
    (1988, 12, 16, 'Park Seo-joon'),
    (2000, 3, 20, 'Hyunjin'),
    (1995, 7, 23, 'Hwasa'),
    (1989, 3, 9, 'Taeyeon'),
    (1988, 8, 18, 'GD'),
    (1992, 12, 4, 'Jin'),
    (1994, 4, 22, 'Jin Se-yeon'),
    (1972, 12, 15, 'Lee Jung-jae'),
  ];
  for (final d in dates) {
    setSolarDate(d.$1, d.$2, d.$3);
    print('${d.$1}-${d.$2.toString().padLeft(2,'0')}-${d.$3.toString().padLeft(2,'0')} ${d.$4}: ${getChineseGapJaString()}');
  }
}
