// R103 Sprint 4 — celeb_songs.json 전수 quality audit 회귀 테스트.
//
// 사용자 verbatim (1.0.0+63 실기기 mandate):
//   "사진 1,2 처럼 디지털 처방전 메뉴에는 없는 곡들이 너무 많아
//    이거 제대로 검증해서 올려야지"
//
// 본 테스트는 R103 sprint 4 audit (74 entries replace) 결과를 lock.
// 검증 항목:
//   1. P0 OCR 직발 2건 — pharita_bm 의 "두 라이크 댓" / j_stayc 의 "샵 아저씨" 둘 다
//      JSON 에 다시 등장하지 않음.
//   2. P1 confirmed fake titles 27 항목 — JSON 에 다시 등장하지 않음 (회귀 가드).
//   3. JSON parse + entry count == 207 (R102 207 보존).
//   4. element distribution (5행 별) ≥ 12 — fallback pool 안전 (R102 sprint 0
//      baseline §4 정확 일치).
//   5. P0 replace target 검증 — pharita_bm + j_stayc 의 after title 이 verified
//      hit 곡으로 정확 매핑.
//   6. artist 오기 fix — wendy_rv "라이크 워터" 의 artistKo 는 "웬디" (R102 sprint 0
//      §5-3 #7 정정 mandate).
//   7. 콤마 디스플레이 자연화 — "러브, 머니, 페임" 류는 콤마 제거 또는 자연 표기.
//   8. placeholder artist 0 (R102 가드 회귀).
//   9. drama stopword leak 0 (R102 가드 회귀).
//   10. titleKo / artistKo 비어 있지 않음 (R102 가드 회귀).

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'fixtures/r103_song_stopwords.dart';

void main() {
  late Map<String, dynamic> songs;
  late List<Map<String, dynamic>> celebs;
  late Set<String> celebIds;

  setUpAll(() async {
    final songsFile = File('assets/data/celeb_songs.json');
    final celebsFile = File('assets/data/celebrities.json');
    songs = json.decode(await songsFile.readAsString()) as Map<String, dynamic>;
    celebs = (json.decode(await celebsFile.readAsString()) as List)
        .cast<Map<String, dynamic>>();
    celebIds = celebs.map((c) => c['id'] as String).toSet();
  });

  group('R103 Sprint 4 — P0 OCR 직발 2건 회귀 가드', () {
    test('pharita_bm 의 titleKo 는 더 이상 "두 라이크 댓" 아님', () {
      expect(songs.containsKey('pharita_bm'), isTrue,
          reason: 'pharita_bm entry must exist');
      final list = (songs['pharita_bm'] as List).cast<Map<String, dynamic>>();
      expect(list, isNotEmpty);
      final title = (list.first['titleKo'] as String).trim();
      expect(title, isNot(equals('두 라이크 댓')),
          reason: 'R103 sprint 4 — pharita_bm fake title leak detected');
      // verified hit 곡 매핑 — R103 sprint 4 audit §2 #1
      expect(title, equals('포에버'),
          reason: 'pharita_bm should be replaced with verified '
              'BABYMONSTER hit "포에버" (FOREVER)');
      expect((list.first['artistKo'] as String).trim(), equals('베이비몬스터'));
    });

    test('j_stayc 의 titleKo 는 더 이상 "샵 아저씨" 아님', () {
      expect(songs.containsKey('j_stayc'), isTrue);
      final list = (songs['j_stayc'] as List).cast<Map<String, dynamic>>();
      expect(list, isNotEmpty);
      final title = (list.first['titleKo'] as String).trim();
      expect(title, isNot(equals('샵 아저씨')),
          reason: 'R103 sprint 4 — j_stayc fake title leak detected');
      expect(title, equals('치키 아이시 탱'),
          reason: 'j_stayc should be replaced with STAYC verified hit '
              '"치키 아이시 탱" (Cheeky Icy Thang)');
      expect((list.first['artistKo'] as String).trim(), equals('스테이씨'));
    });
  });

  group('R103 Sprint 4 — confirmed fake title 27 항목 회귀 가드', () {
    test('r103ConfirmedFakeTitles 의 어떤 title 도 JSON 에 등장하지 않음', () {
      final violations = <String>[];
      songs.forEach((id, raw) {
        final list = (raw as List).cast<Map<String, dynamic>>();
        for (final song in list) {
          final title = (song['titleKo'] as String?)?.trim() ?? '';
          if (r103ConfirmedFakeTitles.contains(title)) {
            violations.add('$id: title="$title" artist="${song['artistKo']}"');
          }
        }
      });
      expect(violations, isEmpty,
          reason: 'R103 sprint 4 confirmed fake title leak:\n  '
              '${violations.join("\n  ")}');
    });
  });

  group('R103 Sprint 4 — JSON validity + count', () {
    test('parse 성공 + entry count == 207 (R102 sprint 4 결과 보존)', () {
      expect(songs.length, equals(207),
          reason: 'R102 dropped 16 entries -> 207 keys. '
              'R103 sprint 4 도 count 보존 (replace only).');
    });

    test('모든 song entry 의 titleKo / artistKo 비어 있지 않음', () {
      final violations = <String>[];
      songs.forEach((id, raw) {
        final list = (raw as List).cast<Map<String, dynamic>>();
        if (list.isEmpty) {
          violations.add('$id has empty song list');
        }
        for (final song in list) {
          final title = (song['titleKo'] as String?)?.trim() ?? '';
          final artist = (song['artistKo'] as String?)?.trim() ?? '';
          if (title.isEmpty) violations.add('$id: titleKo empty');
          if (artist.isEmpty) violations.add('$id: artistKo empty');
        }
      });
      expect(violations, isEmpty);
    });

    test('모든 key 가 celebrities.json id 에 존재 (orphan 0)', () {
      final orphans = songs.keys.where((k) => !celebIds.contains(k)).toList();
      expect(orphans, isEmpty,
          reason: 'celeb_songs.json orphan keys: $orphans');
    });
  });

  group('R103 Sprint 4 — element distribution + fallback 안전', () {
    test('5행 element 별 ≥ 12명 (R102 sprint 0 baseline §4 fallback 안전 요건)',
        () {
      final dist = <String, int>{
        'wood': 0,
        'fire': 0,
        'earth': 0,
        'metal': 0,
        'water': 0,
      };
      songs.forEach((id, raw) {
        final list = (raw as List).cast<Map<String, dynamic>>();
        for (final song in list) {
          final e = (song['element'] as String?)?.trim() ?? '';
          if (dist.containsKey(e)) {
            dist[e] = dist[e]! + 1;
          }
        }
      });
      for (final entry in dist.entries) {
        expect(entry.value, greaterThanOrEqualTo(12),
            reason: 'element ${entry.key} = ${entry.value} < 12 — '
                'fallback deficit element 매칭 위험');
      }
      // R103 sprint 0 baseline 정확 일치 — drop 0, replace only.
      expect(dist['wood'], equals(56));
      expect(dist['fire'], equals(35));
      expect(dist['earth'], equals(37));
      expect(dist['metal'], equals(41));
      expect(dist['water'], equals(38));
    });
  });

  group('R103 Sprint 4 — artist 오기 fix 확인', () {
    test('wendy_rv 의 artistKo == "웬디" (솔로곡 정정, R102 sprint 0 §5-3 #7)', () {
      expect(songs.containsKey('wendy_rv'), isTrue);
      final song = (songs['wendy_rv'] as List).cast<Map<String, dynamic>>().first;
      expect((song['titleKo'] as String).trim(), equals('라이크 워터'),
          reason: 'wendy_rv title 은 Wendy 1st solo "Like Water" retain');
      expect((song['artistKo'] as String).trim(), equals('웬디'),
          reason: 'R103 sprint 4 — wendy_rv artistKo 는 "레드벨벳" 이 아닌 "웬디"');
    });

    test('hoshi_svt 의 artistKo == "호시" (스파이더 unit 곡 정정)', () {
      // SEVENTEEN Spider 는 Hoshi unit 곡.
      expect(songs.containsKey('hoshi_svt'), isTrue);
      final song = (songs['hoshi_svt'] as List).cast<Map<String, dynamic>>().first;
      expect((song['titleKo'] as String).trim(), equals('스파이더'));
      expect((song['artistKo'] as String).trim(), equals('호시'));
    });
  });

  group('R103 Sprint 4 — 콤마 디스플레이 자연화', () {
    test('"러브, 머니, 페임" 콤마 제거 → "러브 머니 페임"', () {
      // dk_svt / wonwoo_svt 의 R102 contains-comma title 자연화
      final dkSong = (songs['dk_svt'] as List).cast<Map<String, dynamic>>().first;
      final dkTitle = (dkSong['titleKo'] as String).trim();
      expect(dkTitle, isNot(contains(', ')),
          reason: 'dk_svt title 콤마 자연화 필요');
      // wonwoo_svt 는 replace 됨 (롤러코스터)
      final wwSong =
          (songs['wonwoo_svt'] as List).cast<Map<String, dynamic>>().first;
      final wwTitle = (wwSong['titleKo'] as String).trim();
      expect(wwTitle, isNot(contains(', ')),
          reason: 'wonwoo_svt title 콤마 자연화 필요');
    });
  });

  group('R103 Sprint 4 — R102 placeholder / drama stopword 회귀', () {
    test('placeholder artist 라벨 (헌정 / 응원곡 / tribute / ...) 0건', () {
      const forbidden = <String>{
        '헌정',
        '응원곡',
        'tribute',
        'Tribute',
        'unknown',
        'Unknown',
        'placeholder',
        'Placeholder',
        '김연아 헌정',
      };
      final violations = <String>[];
      songs.forEach((id, raw) {
        final list = (raw as List).cast<Map<String, dynamic>>();
        for (final song in list) {
          final artist = (song['artistKo'] as String?)?.trim() ?? '';
          if (forbidden.contains(artist)) {
            violations.add('$id: artist="$artist"');
          }
          for (final f in forbidden) {
            if (artist.contains(f) && artist != f) {
              violations.add('$id: artist="$artist" contains "$f"');
            }
          }
        }
      });
      expect(violations, isEmpty,
          reason: 'placeholder artist leaked:\n  ${violations.join("\n  ")}');
    });

    test('drama / 영화 / 게임 작품명 titleKo 0건 (R102 stopword pool 회귀)', () {
      const dramaStopwords = <String>{
        '나의 아저씨',
        '선재 업고 튀어',
        '더 글로리',
        '오징어 게임',
        '이상한 변호사 우영우',
        '미스터 션샤인',
        '킹덤',
        '동백꽃 필 무렵',
        '도깨비',
        '태양의 후예',
        '응답하라 1988',
        '시그널',
      };
      final violations = <String>[];
      songs.forEach((id, raw) {
        final list = (raw as List).cast<Map<String, dynamic>>();
        for (final song in list) {
          final title = (song['titleKo'] as String?)?.trim() ?? '';
          if (dramaStopwords.contains(title) ||
              r103DramaStopwordsExtra.contains(title)) {
            violations.add('$id: title="$title"');
          }
        }
      });
      expect(violations, isEmpty,
          reason: 'drama stopword title leak:\n  ${violations.join("\n  ")}');
    });
  });

  group('R103 Sprint 4 — R102 retain 4명 보존 (musicEligible 가드 의존)', () {
    test('bae-suzy / gdragon / cha-eunwoo / lee-junho 4명 모두 songs 에 보존', () {
      const retain = <String>[
        'bae-suzy',
        'gdragon',
        'cha-eunwoo',
        'lee-junho',
      ];
      for (final id in retain) {
        expect(songs.containsKey(id), isTrue,
            reason: '$id must be retained in celeb_songs.json — R102 musicEligible'
                ' 가드 의존');
        final list = (songs[id] as List).cast<Map<String, dynamic>>();
        expect(list, isNotEmpty);
        final artist = (list.first['artistKo'] as String).trim();
        // artist 가 본인 이름 (R102 sprint 0 §5-3) — drop placeholder 검증
        expect(
            ['수지', '지드래곤', '차은우', '이준호'].contains(artist), isTrue,
            reason: '$id artistKo="$artist" not in expected retain set');
      }
    });
  });

  group('R103 Sprint 4 — element fallback edge case (deficit 0 매칭)', () {
    test('각 element 별 idol-eligible (kind=idol + songs 매칭) 셀럽 ≥ 12', () {
      // R102 sprint 3 musicEligible 가드 동안 — idol 만 후보. 단 4 exception
      // (bae-suzy/gdragon/cha-eunwoo/lee-junho).
      final chunToEn = <String, String>{
        '갑': 'wood', '乙': 'wood', '을': 'wood', '甲': 'wood',
        '병': 'fire', '丙': 'fire', '정': 'fire', '丁': 'fire',
        '무': 'earth', '戊': 'earth', '기': 'earth', '己': 'earth',
        '경': 'metal', '庚': 'metal', '신': 'metal', '辛': 'metal',
        '임': 'water', '壬': 'water', '계': 'water', '癸': 'water',
      };
      final celebById = <String, Map<String, dynamic>>{
        for (final c in celebs) c['id'] as String: c,
      };
      final dist = <String, int>{
        'wood': 0,
        'fire': 0,
        'earth': 0,
        'metal': 0,
        'water': 0,
      };
      for (final id in songs.keys) {
        final c = celebById[id];
        if (c == null) continue;
        final kind = (c['kind'] as String?) ?? '';
        const exception = <String>{
          'bae-suzy',
          'gdragon',
          'cha-eunwoo',
          'lee-junho',
        };
        if (kind != 'idol' && !exception.contains(id)) continue;
        final dp = (c['dayPillar'] as String?) ?? '';
        if (dp.isEmpty) continue;
        final ch = dp[0];
        final el = chunToEn[ch];
        if (el != null && dist.containsKey(el)) {
          dist[el] = dist[el]! + 1;
        }
      }
      for (final entry in dist.entries) {
        expect(entry.value, greaterThanOrEqualTo(12),
            reason: 'idol-eligible ${entry.key} fallback pool '
                '= ${entry.value} < 12 — 처방 분포 불안 위험');
      }
    });
  });
}
