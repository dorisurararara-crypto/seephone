// R91 sprint 7 — pattern baseline guard test
// 본인 3+ violation 0 / 일간 prefix 0 / fragment >=200 / same-entry anchor 5+ 0
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('R91 pattern baseline guard', () {
    late Map<String, dynamic> paragraphs;
    late Map<String, dynamic> fragments;

    setUpAll(() async {
      final pf = File('assets/data/life_paragraphs.json');
      final ff = File('assets/data/life_fragments.json');
      paragraphs = jsonDecode(await pf.readAsString()) as Map<String, dynamic>;
      fragments = jsonDecode(await ff.readAsString()) as Map<String, dynamic>;
    });

    test('R91 B1 — paragraph 내 "본인" 3+ 회 0건', () {
      int violation = 0;
      paragraphs.forEach((k, entRaw) {
        if (entRaw is! Map) return;
        entRaw.forEach((c, v) {
          if (v is String) {
            final count = '본인'.allMatches(v).length;
            if (count >= 3) {
              violation++;
            }
          } else if (v is Map) {
            v.forEach((g, body) {
              if (body is String) {
                final count = '본인'.allMatches(body).length;
                if (count >= 3) violation++;
              }
            });
          }
        });
      });
      expect(violation, equals(0),
          reason: 'R91 baseline 1: 본인 3+ 회 paragraph violation = $violation');
    });

    test('R91 B2 — 일간 prefix "(갑|...|계) 일간은" 0건', () {
      final re = RegExp(r'([갑을병정무기경신임계])\s*일간\s*은');
      int violation = 0;
      paragraphs.forEach((k, entRaw) {
        if (entRaw is! Map) return;
        entRaw.forEach((c, v) {
          if (v is String) {
            if (re.hasMatch(v)) violation++;
          } else if (v is Map) {
            v.forEach((g, body) {
              if (body is String && re.hasMatch(body)) violation++;
            });
          }
        });
      });
      expect(violation, equals(0),
          reason: 'R91 baseline 2: 일간 prefix violation = $violation');
    });

    test('R91 B3 — same-entry anchor sentence 5+ 카테고리 반복 0건', () {
      int violation = 0;
      paragraphs.forEach((k, entRaw) {
        if (entRaw is! Map) return;
        final counts = <String, int>{};
        entRaw.forEach((c, v) {
          final texts = <String>[];
          if (v is String) {
            texts.add(v);
          } else if (v is Map) {
            v.values.forEach((body) {
              if (body is String) texts.add(body);
            });
          }
          for (final t in texts) {
            final sents =
                t.split(RegExp(r'(?<=[.!?])\s+')).where((s) => s.trim().length > 8);
            if (sents.isEmpty) continue;
            final last = sents.last.replaceAll(RegExp(r'[.!?]\s*$'), '').trim();
            if (last.length > 8) {
              counts[last] = (counts[last] ?? 0) + 1;
            }
          }
        });
        counts.forEach((s, c) {
          if (c >= 5) violation++;
        });
      });
      expect(violation, equals(0),
          reason: 'R91 baseline 3: same-entry anchor 5+ violation = $violation');
    });

    test('R91 B4 — fragment DB total >=200', () {
      int total = 0;
      const axes = ['5행압도', '5행공허', '월령', '십성주력', '격국'];
      for (final axis in axes) {
        final sub = fragments[axis];
        if (sub is Map) {
          sub.forEach((k, lst) {
            if (lst is List) total += lst.length;
          });
        }
      }
      expect(total, greaterThanOrEqualTo(200),
          reason: 'R91 baseline 4: fragment total = $total');
    });
  });
}
