// R103 sprint 1 — 8 keyword × resolution motif diversity 가드.
//
// 각 keyword 의 tails / resolution 풀이 다양한 motif 를 포함하는지 확인:
//   wonjin   — 앨범 / 굿즈 / 카드값 (애증 결제)
//   dohwa    — 직캠 / 무대 / 알고리즘 / 표정 (시선/매력)
//   yeokma   — 콘서트 / 도시 / 비행기 / 마일리지 / 투어 (이동)
//   cheoneul — 위로 / 슬럼프 / 다정함 / 응원 (구원)
//   gongmang — 발라드 / 라이브 / 빈자리 / 새벽 / 외로움 (여백)
//   hap      — 취향 / 플레이리스트 / 일상 / 단골 (조화)
//   chung    — 컴백 / 일정 / 흔들림 / 티켓팅 (충돌)
//   hyeong   — 약속 / 진심 / 책임 / 다짐 / 결심 (책임)

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

  group('R103 — keyword 별 motif diversity', () {
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

    test('각 keyword 의 tail+resolution 합쳐 motif 5개 이상 매칭', () {
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
        expect(hits, greaterThanOrEqualTo(5),
            reason: '$k motif hit $hits/${motifs.length} (need ≥ 5)');
      });
    });

    test('8 keyword 모두 event_sub variant ≥ 8 + dramatic detail markers 포함', () {
      const dramaticMarkers = <String>[
        '한 번은', '어느 새벽', '어느 밤', '그날', '한 번',
        '쪽지', '편지', '옥패', '손수건', '담요', '약속', '도망',
        '잡혔', '비밀', '발길', '대결', '소문',
        '벤치', '처마', '카페', '식탁', '책', '돌', '꽃',
        '회합', '추격', '신호', '암호', '면회',
        '외투', '만두', '노래', '시',
        '눈빛', '미소', '인사', '판단',
        '찻잔', '매듭', '마지막', '의상', '자수',
        '익명', '꽃 한 송이', '의자', '메모', '책상',
        '부적', '베개', '종이 한 장', '비단옷', '항구',
        '돌아봄', '여관', '키잡이', '큰소리', '도성',
        '신부', '신랑', '봇짐', '비밀 회합', '쫓기',
        '가짜', '망명', '독약', '광대', '검객',
        '도둑', '소문', '큰 마음', '거리에서',
        '우연히', '같은 카페', '같은 음식', '같은 자리',
        '두 번', '세 번', '평생', '한참',
      ];
      final bodyLines = pool['body_lines'] as Map<String, dynamic>;
      bodyLines.forEach((k, v) {
        final m = v as Map<String, dynamic>;
        final subs = (m['event_sub'] as List).cast<String>();
        expect(subs.length, greaterThanOrEqualTo(8),
            reason: '$k event_sub < 8');
        // 각 event_sub 가 dramatic marker 1+ 포함.
        for (var i = 0; i < subs.length; i++) {
          final sub = subs[i];
          final hit = dramaticMarkers.any((m) => sub.contains(m));
          expect(hit, isTrue,
              reason: '$k event_sub[$i] dramatic marker 없음: $sub');
        }
      });
    });

    test('headers / intros / tails 풀 크기 R103 spec 충족', () {
      final templates = pool['templates'] as Map<String, dynamic>;
      templates.forEach((k, v) {
        final tpl = v as Map<String, dynamic>;
        expect((tpl['headers'] as List).length, greaterThanOrEqualTo(8),
            reason: '$k headers < 8');
        expect((tpl['intros'] as List).length, greaterThanOrEqualTo(16),
            reason: '$k intros < 16');
        expect((tpl['tails'] as List).length, greaterThanOrEqualTo(16),
            reason: '$k tails < 16');
      });
    });

    test('relations pool ≥ 48', () {
      final relations = (pool['relations'] as List).cast<Map<String, dynamic>>();
      expect(relations.length, greaterThanOrEqualTo(48),
          reason: 'relations < 48 (got ${relations.length})');
      // 사용자 verbatim 예시 "몰락한 귀족 + 스파이" pair 가 reproducible (fixture).
      final hasMollak = relations.any((r) =>
          (r['user'] as String).contains('몰락한 귀족') &&
          (r['celeb'] as String).contains('스파이'));
      expect(hasMollak, isTrue,
          reason: '사용자 verbatim 예시 "몰락한 귀족 + 스파이" pair 미포함');
    });
  });
}
