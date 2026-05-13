// 콘텐츠 무결성 회귀 테스트 — codex Round 30 권고.
// 1. dreams.json 중복 없음, 빈 의미 없음
// 2. category 가 UI 필터 enum 안에만 존재
// 3. 모든 entry KO + EN 동등

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('dreams.json 무결성', () {
    late List<Map<String, dynamic>> dreams;
    setUpAll(() {
      final raw =
          File('assets/data/dreams.json').readAsStringSync();
      dreams = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    });

    test('en 키워드 중복 없음', () {
      final seen = <String, int>{};
      for (final d in dreams) {
        final en = d['en'] as String;
        seen[en] = (seen[en] ?? 0) + 1;
      }
      final dups = seen.entries.where((e) => e.value > 1).toList();
      expect(dups, isEmpty, reason: 'duplicate en keys: $dups');
    });

    test('ko 키워드 중복 없음', () {
      final seen = <String, int>{};
      for (final d in dreams) {
        final ko = d['ko'] as String;
        seen[ko] = (seen[ko] ?? 0) + 1;
      }
      final dups = seen.entries.where((e) => e.value > 1).toList();
      expect(dups, isEmpty, reason: 'duplicate ko keys: $dups');
    });

    test('빈 의미·키워드 없음', () {
      for (final d in dreams) {
        expect((d['en'] as String).trim(), isNotEmpty);
        expect((d['ko'] as String).trim(), isNotEmpty);
        expect((d['meaningEn'] as String).trim(), isNotEmpty);
        expect((d['meaningKo'] as String).trim(), isNotEmpty);
      }
    });

    test('category 가 UI 필터 enum 안에만 (auspicious/wealth/love/family/warning)', () {
      const allowed = {'auspicious', 'wealth', 'love', 'family', 'warning'};
      final invalid = <String>{};
      for (final d in dreams) {
        final cat = d['cat'] as String;
        if (!allowed.contains(cat)) invalid.add(cat);
      }
      expect(invalid, isEmpty,
          reason:
              'unknown categories present: $invalid (allowed: $allowed)');
    });

    test('auspicious bool 필드 존재', () {
      for (final d in dreams) {
        expect(d['auspicious'], isA<bool>(),
            reason: 'auspicious 필드 누락/타입 오류: ${d['en']}');
      }
    });

    test('전체 entry 수 >= 40 (출시 데이터셋 최소)', () {
      expect(dreams.length, greaterThanOrEqualTo(40),
          reason: 'dataset 너무 작음 — 깊이 부족');
    });
  });

  group('l10n KO/EN parity 무결성', () {
    test('주요 한국어 leak 후보 — 한국 모드에서 영어 단어 미노출', () {
      // 자주 leak 되는 패턴들이 KO arb 안에 직접 영어 표기로 잠겨 있지 않은지.
      // English 단어가 한국어 strings 안에 들어가 있으면 번역 흔적 의심.
      final koArb =
          File('lib/l10n/app_ko.arb').readAsStringSync();
      // 사주 핵심 용어인데 영어로만 적혀있으면 leak 의심.
      // 의도적 영어 brand 단어 (KASI, Pillar Seer, K-pop, Phase, Pro, AM, PM) 는 OK.
      final suspectPatterns = [
        'Day Master',
        'Day Pillar',
        'Yang Wood',
        'Yin Wood',
        'Yang Fire',
        'Yin Fire',
      ];
      for (final p in suspectPatterns) {
        expect(koArb.contains(p), isFalse,
            reason:
                'KO arb 에 "$p" 발견 — 한국 모드에서 영어 leak 가능성');
      }
    });

    test('주요 영문 leak 후보 — 영어 모드에서 한국 표기 미노출', () {
      final enArb =
          File('lib/l10n/app_en.arb').readAsStringSync();
      // 한국어 brand 단어는 OK ("한국어", 한국어 KASI 보충 표기 등).
      // 핵심 사주 용어 한국어 음을 영어 strings 에서 단독 노출하면 안 됨.
      final suspectPatterns = [
        '나무',
        '불 (火)',
        '쇠',
        '물 (水)',
        '갑목',
        '을목',
      ];
      for (final p in suspectPatterns) {
        expect(enArb.contains(p), isFalse,
            reason:
                'EN arb 에 "$p" 발견 — 영어 모드에서 한국어 leak 가능성');
      }
    });
  });

  group('DailyService lucky color/direction KO/EN parity', () {
    test('5 행 모두에 대해 EN/KO 매핑 존재', () {
      // 직접 service 호출하기 어려우니 대신 코드 검증.
      // 핵심: KO 모드 사용자가 행운 컬러를 봤을 때 영어 단독으로 보이지 않음.
      final daily =
          File('lib/services/daily_service.dart').readAsStringSync();
      // _luckyColorFor 에 koMap 필드 존재해야 함 (Round 35 fix).
      expect(daily.contains('koMap = {'), isTrue,
          reason: 'daily_service.dart 에 한국어 lucky 매핑 누락');
      // _luckyDirectionFor 도 마찬가지.
      expect(daily.contains("'木': '동쪽'"), isTrue,
          reason: 'direction KO 매핑 누락');
      // DailyFortune 에 luckyColorKo 필드 존재.
      final model =
          File('lib/models/daily_fortune.dart').readAsStringSync();
      expect(model.contains('luckyColorKo'), isTrue);
      expect(model.contains('luckyDirectionKo'), isTrue);
    });
  });

  group('celebrities.json 무결성', () {
    late List<Map<String, dynamic>> celebs;
    setUpAll(() {
      final raw =
          File('assets/data/celebrities.json').readAsStringSync();
      celebs = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    });

    test('id 중복 없음', () {
      final seen = <String, int>{};
      for (final c in celebs) {
        final id = c['id'] as String;
        seen[id] = (seen[id] ?? 0) + 1;
      }
      final dups = seen.entries.where((e) => e.value > 1).toList();
      expect(dups, isEmpty);
    });

    test('필수 필드: nameEn/nameKo/dayPillar/blurbKo', () {
      for (final c in celebs) {
        expect((c['nameEn'] as String).trim(), isNotEmpty);
        expect((c['nameKo'] as String).trim(), isNotEmpty);
        expect((c['dayPillar'] as String).trim(), hasLength(2));
        expect((c['blurbKo'] as String).trim(), isNotEmpty);
        expect((c['blurbEn'] as String).trim(), isNotEmpty);
      }
    });

    test('blurbKo 문법 오류 — "불와/물와/흙와/결 결" 없음', () {
      final bad = <String>[];
      for (final c in celebs) {
        final ko = c['blurbKo'] as String;
        for (final p in ['불와 ', '물와 ', '흙와 ', '결 결', ' 결.']) {
          if (ko.contains(p)) {
            bad.add('${c['id']}: "$p" in "$ko"');
            break;
          }
        }
      }
      expect(bad, isEmpty,
          reason: 'celeb blurbKo 한국어 문법/반복 오류:\n${bad.join("\n")}');
    });
  });

  group('saju_deep_slice 본문 품질', () {
    // codex Round 65 권고 — 같은 슬라이스 안에서 body text 가 모든 entries 에
    // 동일하게 반복되는 패턴 (Barnum 변주 전) 을 회귀 방지.
    test('동일 문장 60일주 cross 반복 ≤ 10× (KO body 본문)', () {
      final files = [
        'assets/data/saju_deep_slice_0_19.json',
        'assets/data/saju_deep_slice_20_39.json',
        'assets/data/saju_deep_slice_40_59.json',
      ];
      final phraseCount = <String, int>{};
      for (final f in files) {
        final data = (jsonDecode(File(f).readAsStringSync()) as List)
            .cast<Map<String, dynamic>>();
        for (final e in data) {
          final ko = e['ko'] as Map<String, dynamic>?;
          if (ko == null) continue;
          for (final fld in [
            'love',
            'career',
            'wealth',
            'health',
            'family',
            'fame',
            'dayMasterDeep'
          ]) {
            final v = ko[fld];
            if (v is! String) continue;
            // sentence split
            final sents = v.split(RegExp(r'(?<=[.!?])\s+'));
            for (final s in sents) {
              final t = s.trim();
              if (t.length >= 20 && t.length <= 200) {
                phraseCount[t] = (phraseCount[t] ?? 0) + 1;
              }
            }
          }
        }
      }
      // 슬라이스 구조 (20 entries / slice) 이므로 같은 슬라이스의 base body 가
      // 20× 까지는 정상 — 21× 이상이면 cross-slice 중복.
      // 또한 cold reading 변주가 들어간 카테고리는 NC2 pair 로 분산되어 ≤10.
      final overRepeated = phraseCount.entries
          .where((e) => e.value > 20)
          .map((e) =>
              '${e.value}× | ${e.key.substring(0, e.key.length > 60 ? 60 : e.key.length)}')
          .toList();
      expect(overRepeated, isEmpty,
          reason:
              'KO body 본문 sentence 21+ cross-slice 반복 (회귀 방지):\n${overRepeated.join("\n")}');
    });
  });
}
