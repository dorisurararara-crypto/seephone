// R103 → R104 — keyword 별 motif / 풀 구조 가드.
//
// R104 sprint 3 전환:
//   - 본문 엔진이 slot 랜덤 조립 → story arc 단일 선택으로 바뀐다.
//   - 기존 slot 키(templates.headers/intros/tails, body_lines.event_sub/
//     resolution 등)는 fallback 용도로 잔존하므로 slot 풀 크기 가드는 하위호환
//     회귀 가드로 유지한다 (삭제 금지 mandate + fallback 안전망).
//   - story_arcs content 의 실제 count / 내용 강제는 Sprint 4 가 story_arcs 를
//     채운 뒤 활성화되어야 한다. 본 파일은 story_arcs 가 "있을 때만" content 를
//     검증하고, 없으면(=Sprint 4 전) skip 하여 service fallback 때문에 전체
//     테스트가 깨지지 않게 설계했다.
//   - story_arcs schema shape 검증의 메인 소유는 test/r104_past_life_arc_test.dart.
//     본 파일은 motif 다양성 / Sprint 4 후 count 게이트만 담당.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Map<String, dynamic> pool;

  setUpAll(() async {
    final f = File('assets/data/past_life_pool.json');
    pool = json.decode(await f.readAsString()) as Map<String, dynamic>;
  });

  const keywordIds = <String>[
    'wonjin',
    'dohwa',
    'yeokma',
    'cheoneul',
    'gongmang',
    'hap',
    'chung',
    'hyeong',
  ];

  /// keyword 에 유효한 story_arcs 리스트가 있으면 true.
  bool hasStoryArcs(String keywordId) {
    final sa = pool['story_arcs'];
    if (sa is! Map) return false;
    final arcs = sa[keywordId];
    return arcs is List && arcs.isNotEmpty;
  }

  bool allHaveStoryArcs() => keywordIds.every(hasStoryArcs);

  group('R104 — slot fallback motif diversity (하위호환 가드)', () {
    // story arc 으로 전환했어도 slot 키는 fallback 용도로 보존. 그 풀의 motif
    // 다양성을 회귀 가드로 유지 — Sprint 4 가 slot 키를 건드리지 않게 보호.
    const motifMap = <String, List<String>>{
      'wonjin': ['앨범', '굿즈', '카드값', '음원', '안티'],
      'dohwa': ['직캠', '무대', '알고리즘', '표정', '응원봉', '인스타', '화보', '포카'],
      'yeokma': ['콘서트', '도시', '비행기', '마일리지', '투어', '공항', '여권', 'KTX'],
      'cheoneul': ['위로', '응원', '다정', '담요', '굿즈', '편지', '슬럼프', '살려'],
      'gongmang': ['발라드', '라이브', '빈자리', '새벽', '외로움', '자장가', '플레이리스트', '비어'],
      'hap': ['취향', '플레이리스트', '일상', '단골', '굿즈 디자인', '브이로그', '결의 사람', '카페'],
      'chung': ['컴백', '일정', '흔들림', '티켓팅', '한 주', '한 달', '패션', '결정'],
      'hyeong': ['약속', '진심', '책임', '다짐', '결심', '마음 자세', '5년치', '평생'],
    };

    test('각 keyword 의 tail+resolution 합쳐 motif 5개 이상 매칭 (slot fallback)', () {
      final templates = pool['templates'] as Map<String, dynamic>;
      final bodyLines = pool['body_lines'] as Map<String, dynamic>;

      motifMap.forEach((k, motifs) {
        final tpl = templates[k] as Map<String, dynamic>;
        final body = bodyLines[k] as Map<String, dynamic>;
        final all = <String>[
          ...(tpl['tails'] as List).cast<String>(),
          ...(body['resolution'] as List).cast<String>(),
        ].join(' | ');
        final hits = motifs.where((m) => all.contains(m)).length;
        expect(
          hits,
          greaterThanOrEqualTo(5),
          reason: '$k motif hit $hits/${motifs.length} (need ≥ 5)',
        );
      });
    });

    test(
      '8 keyword 모두 event_sub variant ≥ 8 + dramatic detail markers (slot fallback)',
      () {
        const dramaticMarkers = <String>[
          '한 번은',
          '어느 새벽',
          '어느 밤',
          '그날',
          '한 번',
          '쪽지',
          '편지',
          '옥패',
          '손수건',
          '담요',
          '약속',
          '도망',
          '잡혔',
          '비밀',
          '발길',
          '대결',
          '소문',
          '벤치',
          '처마',
          '카페',
          '식탁',
          '책',
          '돌',
          '꽃',
          '회합',
          '추격',
          '신호',
          '암호',
          '면회',
          '외투',
          '만두',
          '노래',
          '시',
          '눈빛',
          '미소',
          '인사',
          '판단',
          '찻잔',
          '매듭',
          '마지막',
          '의상',
          '자수',
          '익명',
          '꽃 한 송이',
          '의자',
          '메모',
          '책상',
          '부적',
          '베개',
          '종이 한 장',
          '비단옷',
          '항구',
          '돌아봄',
          '여관',
          '키잡이',
          '큰소리',
          '도성',
          '신부',
          '신랑',
          '봇짐',
          '비밀 회합',
          '쫓기',
          '가짜',
          '망명',
          '독약',
          '광대',
          '검객',
          '도둑',
          '소문',
          '큰 마음',
          '거리에서',
          '우연히',
          '같은 카페',
          '같은 음식',
          '같은 자리',
          '두 번',
          '세 번',
          '평생',
          '한참',
        ];
        final bodyLines = pool['body_lines'] as Map<String, dynamic>;
        bodyLines.forEach((k, v) {
          final m = v as Map<String, dynamic>;
          final subs = (m['event_sub'] as List).cast<String>();
          expect(
            subs.length,
            greaterThanOrEqualTo(8),
            reason: '$k event_sub < 8',
          );
          for (var i = 0; i < subs.length; i++) {
            final sub = subs[i];
            final hit = dramaticMarkers.any((m) => sub.contains(m));
            expect(
              hit,
              isTrue,
              reason: '$k event_sub[$i] dramatic marker 없음: $sub',
            );
          }
        });
      },
    );

    test('headers / intros / tails 풀 크기 유지 (slot fallback)', () {
      final templates = pool['templates'] as Map<String, dynamic>;
      templates.forEach((k, v) {
        final tpl = v as Map<String, dynamic>;
        expect(
          (tpl['headers'] as List).length,
          greaterThanOrEqualTo(8),
          reason: '$k headers < 8',
        );
        expect(
          (tpl['intros'] as List).length,
          greaterThanOrEqualTo(16),
          reason: '$k intros < 16',
        );
        expect(
          (tpl['tails'] as List).length,
          greaterThanOrEqualTo(16),
          reason: '$k tails < 16',
        );
      });
    });

    test('relations pool ≥ 48 (slot fallback)', () {
      final relations = (pool['relations'] as List)
          .cast<Map<String, dynamic>>();
      expect(
        relations.length,
        greaterThanOrEqualTo(48),
        reason: 'relations < 48 (got ${relations.length})',
      );
      final hasMollak = relations.any(
        (r) =>
            (r['user'] as String).contains('몰락한 귀족') &&
            (r['celeb'] as String).contains('스파이'),
      );
      expect(
        hasMollak,
        isTrue,
        reason: '사용자 verbatim 예시 "몰락한 귀족 + 스파이" pair 미포함',
      );
    });
  });

  group('R104 — story_arcs content count (Sprint 4 content 후 활성)', () {
    // 아래 테스트는 story_arcs 가 채워졌을 때만 의미가 있다. Sprint 4 가
    // story_arcs 를 추가하기 전에는 early-return 으로 통과(=no-op)하고,
    // content 가 들어온 뒤 자동으로 강제된다. content count 강제 게이트는
    // 의도적으로 본 그룹에 모았다 (test 이름에 "Sprint 4 content 후 활성" 명시).

    test(
      'story_arcs — 8 keyword 모두 arc ≥ 6 (목표 8) [Sprint 4 content 후 활성]',
      () {
        if (!allHaveStoryArcs()) {
          // Sprint 4 전 — story_arcs content 미존재. 게이트 미활성.
          return;
        }
        final storyArcs = pool['story_arcs'] as Map<String, dynamic>;
        for (final k in keywordIds) {
          final arcs = storyArcs[k] as List;
          expect(
            arcs.length,
            greaterThanOrEqualTo(6),
            reason: '$k story_arcs ${arcs.length}개 < 6 (R104 keyword당 최소 6)',
          );
        }
      },
    );

    test(
      'story_arcs — 각 arc paragraphs 기/승/전/결 + kind punchline 4종 [Sprint 4 후 활성]',
      () {
        if (!allHaveStoryArcs()) {
          return;
        }
        final storyArcs = pool['story_arcs'] as Map<String, dynamic>;
        for (final k in keywordIds) {
          final arcs = (storyArcs[k] as List).cast<Map<String, dynamic>>();
          for (var i = 0; i < arcs.length; i++) {
            final arc = arcs[i];
            final p = arc['paragraphs'];
            expect(p, isA<Map>(), reason: '$k arc[$i] paragraphs Map 아님');
            final pm = p as Map;
            for (final phase in ['gi', 'seung', 'jeon', 'gyeol']) {
              expect(
                pm[phase],
                isA<String>(),
                reason: '$k arc[$i].$phase 누락 또는 string 아님',
              );
              expect(
                (pm[phase] as String).trim(),
                isNotEmpty,
                reason: '$k arc[$i].$phase 빈 문자열',
              );
            }
            final punch = arc['modernPunchlineByKind'];
            expect(
              punch,
              isA<Map>(),
              reason: '$k arc[$i] modernPunchlineByKind Map 아님',
            );
            for (final kind in ['idol', 'actor', 'athlete', 'icon']) {
              expect(
                (punch as Map)[kind],
                isA<String>(),
                reason: '$k arc[$i] punchline.$kind 누락',
              );
            }
          }
        }
      },
    );
  });
}
