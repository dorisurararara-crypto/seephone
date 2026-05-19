// R102 Sprint 4 — celeb_songs.json 데이터 audit 회귀 테스트.
//
// 사용자 verbatim (R102 Sprint 1 baseline):
//   "한소희는 가수도 아니고 나의아저씨는 없는노랜데 ??"
//
// 데이터 정합성 정책:
//   1. placeholder artist label 0 — artistKo 가 '헌정' / '응원곡' / 'tribute' /
//      'unknown' / 'placeholder' / '김연아 헌정' 등으로 표기된 entry 0건.
//   2. drama / 작품명 사칭 title 0 — '나의 아저씨' / '선재 업고 튀어' / '더 글로리'
//      / '롤리팝' (드라마 / 영화 / 게임 작품명) 0건.
//   3. drop 목록 (16건) 모두 entry 삭제 — han-sohee / kim-yuna / son-heungmin /
//      park-seojoon / song-hyekyo / squidgame-lee / kim-soohyun / lee-minho /
//      song-kang / byeon-wooseok / hwang-inyoup / kim-seonho / ji-changwook /
//      kim-jiwon / kim-hyeyoon / jin-seyeon.
//   4. retain 목록 (4건) 모두 entry 보존 + artist 검증 — bae-suzy ('수지') /
//      gdragon ('지드래곤') / cha-eunwoo ('차은우') / lee-junho ('이준호').
//   5. JSON parse + entry count 일관성 — celeb_songs.json 의 모든 key 가
//      celebrities.json 의 id 에 존재.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

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

  group('R102 Sprint 4 — placeholder artist 가드', () {
    test('artistKo 가 placeholder 라벨 (헌정 / 응원곡 / tribute / ...) 0건', () {
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
            violations.add(
                '$id: title="${song['titleKo']}" artist="$artist"');
          }
          // 부분 일치도 차단 (예: "XXX 헌정", "XXX tribute").
          for (final f in forbidden) {
            if (artist.contains(f) && artist != f) {
              violations.add(
                  '$id: title="${song['titleKo']}" artist="$artist" '
                  '(contains "$f")');
            }
          }
        }
      });
      expect(violations, isEmpty,
          reason: 'placeholder artist leaked:\n  ${violations.join("\n  ")}');
    });
  });

  group('R102 Sprint 4 — drama / 작품명 사칭 title 가드', () {
    test('titleKo 가 known drama / 영화 / 게임 작품명과 일치 0건', () {
      // 사용자 verbatim 매핑 + 추가 stopword pool — sprint 1 baseline §9.
      const dramaStopwords = <String>{
        '나의 아저씨', // 2018 tvN 드라마
        '선재 업고 튀어', // 2024 tvN 드라마
        '더 글로리', // 2022 Netflix 드라마
        '오징어 게임', // 2021 Netflix 시리즈
        '이상한 변호사 우영우', // 2022 ENA 드라마
        '미스터 션샤인', // 2018 tvN 드라마
        '킹덤', // Netflix 시리즈
        '동백꽃 필 무렵', // 2019 KBS 드라마
        '도깨비', // 2016 tvN 드라마
        '태양의 후예', // 2016 KBS 드라마
        '응답하라 1988', // 2015 tvN 드라마
        '시그널', // 2016 tvN 드라마
      };
      final violations = <String>[];
      songs.forEach((id, raw) {
        final list = (raw as List).cast<Map<String, dynamic>>();
        for (final song in list) {
          final title = (song['titleKo'] as String?)?.trim() ?? '';
          if (dramaStopwords.contains(title)) {
            violations
                .add('$id: title="$title" artist="${song['artistKo']}"');
          }
        }
      });
      expect(violations, isEmpty,
          reason: 'drama stopword title leaked:\n  ${violations.join("\n  ")}');
    });
  });

  group('R102 Sprint 4 — drop 목록 entry 삭제 확인', () {
    const dropIds = <String>[
      // 13 actor with 헌정 artist
      'song-hyekyo',
      'park-seojoon',
      'jin-seyeon',
      'squidgame-lee',
      'kim-soohyun',
      'lee-minho',
      'song-kang',
      'byeon-wooseok',
      'hwang-inyoup',
      'kim-seonho',
      'kim-jiwon',
      'kim-hyeyoon',
      'han-sohee',
      // 1 athlete with 김연아 헌정
      'kim-yuna',
      // 1 athlete with 응원곡
      'son-heungmin',
      // actor, music pharmacy 제외 정책
      'ji-changwook',
    ];

    test('16건 모두 celeb_songs.json 에서 삭제됨', () {
      final stillPresent = dropIds.where(songs.containsKey).toList();
      expect(stillPresent, isEmpty,
          reason:
              'drop targets still present in celeb_songs.json: $stillPresent');
    });

    test('drop 대상 celeb 들은 celebrities.json 에는 보존 (kind 만 actor/athlete)',
        () {
      // celebrities.json 은 손대지 않음 — 사주 / 케미 / 패스라이프 등 다른 화면에서 활용.
      // 단 music pharmacy 처방 후보에서만 차단된다.
      for (final id in dropIds) {
        final exists = celebIds.contains(id);
        expect(exists, isTrue,
            reason: '$id should still exist in celebrities.json');
      }
    });
  });

  group('R102 Sprint 4 — retain 목록 entry 보존 확인', () {
    test('4건 (bae-suzy / gdragon / cha-eunwoo / lee-junho) 모두 보존', () {
      const retainSpec = <String, (String, String)>{
        'bae-suzy': ('행복한 척', '수지'),
        'gdragon': ('무제', '지드래곤'),
        'cha-eunwoo': ('기적 같은 이야기', '차은우'),
        'lee-junho': ('아 진짜요', '이준호'),
      };
      for (final entry in retainSpec.entries) {
        final id = entry.key;
        final (expectedTitle, expectedArtist) = entry.value;
        expect(songs.containsKey(id), isTrue,
            reason: 'retain target $id missing from celeb_songs.json');
        final list = (songs[id] as List).cast<Map<String, dynamic>>();
        expect(list, isNotEmpty,
            reason: '$id song list is empty');
        final song = list.first;
        expect(song['titleKo'], equals(expectedTitle),
            reason: '$id title changed from $expectedTitle');
        expect(song['artistKo'], equals(expectedArtist),
            reason: '$id artist changed from $expectedArtist');
      }
    });

    test('지창욱은 drop 됨 (kind=actor + Sprint 3 musicEligible exception X)', () {
      // sprint 4 spec — 지창욱은 actor 분류이며 Sprint 3 의
      // _musicEligibleException 4명 (cha-eunwoo / lee-junho / bae-suzy / gdragon)
      // 에 포함되지 않음 → 데이터 정합성을 위해 celeb_songs.json 에서 entry 제거.
      expect(songs.containsKey('ji-changwook'), isFalse,
          reason: 'ji-changwook entry should be dropped from celeb_songs.json');
    });
  });

  group('R102 Sprint 4 — JSON validity + entry count', () {
    test('parse 성공 + entry count == 207 (223 - 16)', () {
      expect(songs.length, equals(207),
          reason:
              'expected 207 keys (223 original - 16 drop) but got ${songs.length}');
    });

    test('모든 key 가 celebrities.json id 에 존재', () {
      final orphans = songs.keys.where((k) => !celebIds.contains(k)).toList();
      expect(orphans, isEmpty,
          reason: 'celeb_songs.json 에 celebrities.json 에 없는 key 존재: $orphans');
    });

    test('모든 entry list 비어있지 않음 + 필수 키 보존', () {
      songs.forEach((id, raw) {
        final list = (raw as List).cast<Map<String, dynamic>>();
        expect(list, isNotEmpty, reason: '$id has empty song list');
        for (final song in list) {
          expect(song['titleKo'], isA<String>(),
              reason: '$id missing titleKo');
          expect(song['artistKo'], isA<String>(),
              reason: '$id missing artistKo');
          expect(song['element'], isA<String>(),
              reason: '$id missing element');
          expect((song['titleKo'] as String).trim(), isNotEmpty,
              reason: '$id titleKo empty');
          expect((song['artistKo'] as String).trim(), isNotEmpty,
              reason: '$id artistKo empty');
        }
      });
    });
  });

  group('R102 Sprint 4 — celebrities.json kind 안정성 보존', () {
    test('retain 4명 모두 actor 또는 icon kind 보존 (Sprint 3 정책 의존)', () {
      // Sprint 3 의 _musicEligibleException 정책은 retain 4명 kind 가 actor/icon
      // 일 때만 의미가 있음. 만약 Sprint 4 가 kind=idol 로 재분류하면 정책이 의미를
      // 잃음 + Sprint 3 test 가 FAIL. Sprint 4 는 celebrities.json 을 손대지 않는다.
      const retain = <String, List<String>>{
        'bae-suzy': ['actor'],
        'gdragon': ['icon'],
        'cha-eunwoo': ['actor'],
        'lee-junho': ['actor'],
      };
      for (final entry in retain.entries) {
        final c = celebs.firstWhere((x) => x['id'] == entry.key,
            orElse: () => <String, dynamic>{});
        expect(c.isNotEmpty, isTrue,
            reason: 'retain ${entry.key} not in celebrities.json');
        final kind = (c['kind'] as String?)?.trim() ?? '';
        expect(entry.value.contains(kind), isTrue,
            reason:
                '${entry.key} kind=$kind not in allowed ${entry.value} '
                '— Sprint 3 가드 의존, kind 재분류 금지');
      }
    });
  });
}
