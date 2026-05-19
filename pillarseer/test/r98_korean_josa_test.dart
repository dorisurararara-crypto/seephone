// R98 sprint 1 — Korean josa helper unit tests.
//
// 사용자 OCR (壬戌·Water Dog 솔라 케이스):
//   "... 너의 봄빛 들어오는 창가의 대화와 솔라의 문 닫고 같이 지키는 공간가 어느새 한 시간대로 흘러요."
//   → '공간가' 가 어색. '공간' 끝 '간' 은 받침(ㄴ) 있음 → '이' 가 와야 함.
//
// 본 test 는 helper 의 4 함수 (withSubj/withTop/withObj/withWith) 가
// (1) 한글 받침 있음/없음, (2) 한자 천간/지지/오행, (3) 영문 모음/자음 끝
// 케이스에서 모두 자연스러운 조사를 고른다는 것을 보장.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pillarseer/services/korean_josa.dart';

void main() {
  group('R98 sprint 1 — withSubj (이/가)', () {
    test('한글 받침 있음 → 이', () {
      // 사용자 OCR 정확 재현 — '공간' 끝 '간' 은 ㄴ 받침.
      expect(withSubj('공간'), equals('이'));
      // 다른 받침 있음 케이스.
      expect(withSubj('책상'), equals('이')); // ㅇ
      expect(withSubj('첫 발걸음'), equals('이')); // ㅁ
      expect(withSubj('정원'), equals('이')); // ㄴ wait — 원 끝 ㄴ
      expect(withSubj('결정'), equals('이')); // ㅇ
      expect(withSubj('하늘'), equals('이')); // ㄹ
    });

    test('한글 받침 없음 → 가', () {
      // 사용자 OCR 정상 케이스 — '대화' 끝 '화' 받침 없음.
      expect(withSubj('대화'), equals('가'));
      expect(withSubj('자리'), equals('가'));
      expect(withSubj('미나'), equals('가')); // 받침 없는 사람 이름.
      expect(withSubj('소나기'), equals('가'));
      expect(withSubj('나무'), equals('가'));
    });

    test('한자 천간 — 받침 여부 정확', () {
      expect(withSubj('甲'), equals('이')); // 갑 ㅂ
      expect(withSubj('辛'), equals('이')); // 신 ㄴ
      expect(withSubj('壬'), equals('이')); // 임 ㅁ
      expect(withSubj('戊'), equals('가')); // 무
      expect(withSubj('癸'), equals('가')); // 계
    });

    test('한자 지지 — 받침 여부 정확', () {
      expect(withSubj('戌'), equals('이')); // 술 ㄹ
      expect(withSubj('子'), equals('가')); // 자
      expect(withSubj('卯'), equals('가')); // 묘
      expect(withSubj('丑'), equals('이')); // 축 ㄱ
      expect(withSubj('未'), equals('가')); // 미
    });

    test('영문 모음 끝 → 가, 자음 끝 → 이', () {
      expect(withSubj('Sola'), equals('가')); // 사용자 OCR 의 솔라 영문 표기 가정.
      expect(withSubj('Jia'), equals('가'));
      expect(withSubj('Yong'), equals('이'));
      expect(withSubj('Park'), equals('이'));
    });
  });

  group('R98 sprint 1 — withTop (은/는)', () {
    test('한글 받침 있음 → 은', () {
      expect(withTop('공간'), equals('은'));
      expect(withTop('책상'), equals('은'));
    });

    test('한글 받침 없음 → 는', () {
      expect(withTop('대화'), equals('는'));
      expect(withTop('자리'), equals('는'));
    });

    test('한자/영문', () {
      expect(withTop('戌'), equals('은'));
      expect(withTop('子'), equals('는'));
      expect(withTop('Sola'), equals('는'));
      expect(withTop('Park'), equals('은'));
    });
  });

  group('R98 sprint 1 — withObj (을/를)', () {
    test('한글 받침 있음 → 을', () {
      expect(withObj('공간'), equals('을'));
      expect(withObj('책상'), equals('을'));
    });

    test('한글 받침 없음 → 를', () {
      expect(withObj('대화'), equals('를'));
      expect(withObj('자리'), equals('를'));
    });

    test('한자/영문', () {
      expect(withObj('戌'), equals('을'));
      expect(withObj('子'), equals('를'));
      expect(withObj('Sola'), equals('를'));
      expect(withObj('Park'), equals('을'));
    });
  });

  group('R98 sprint 1 — withWith (과/와)', () {
    test('한글 받침 있음 → 과', () {
      expect(withWith('공간'), equals('과'));
      expect(withWith('책상'), equals('과'));
    });

    test('한글 받침 없음 → 와', () {
      expect(withWith('대화'), equals('와'));
      expect(withWith('자리'), equals('와'));
    });

    test('한자/영문', () {
      expect(withWith('戌'), equals('과'));
      expect(withWith('子'), equals('와'));
      expect(withWith('Sola'), equals('와'));
      expect(withWith('Park'), equals('과'));
    });
  });

  group('R98 sprint 1 — hasFinalConsonant 직접 검사', () {
    test('빈 문자열 / 알 수 없는 문자 → false', () {
      expect(hasFinalConsonant(''), isFalse);
      expect(hasFinalConsonant('·'), isFalse);
    });

    test('숫자 끝 받침 여부 정확', () {
      expect(hasFinalConsonant('1'), isTrue); // 일 ㄹ
      expect(hasFinalConsonant('2'), isFalse); // 이
      expect(hasFinalConsonant('3'), isTrue); // 삼 ㅁ
      expect(hasFinalConsonant('4'), isFalse); // 사
      expect(hasFinalConsonant('7'), isTrue); // 칠 ㄹ
      expect(hasFinalConsonant('9'), isFalse); // 구
    });
  });

  group('R98 sprint 1 — 사용자 OCR 정확 재현 — 공간가 0', () {
    // jiSceneKo 12 entries 의 끝 글자 받침 여부 sample (kpop_compat_screen 의 entries).
    const jiSceneKo = <String, String>{
      '子': '늦은 밤 같이 깨어 있는 자리',
      '丑': '느린 아침과 정리된 책상',
      '寅': '새로 시작하는 첫 발걸음',
      '卯': '봄빛 들어오는 창가의 대화',
      '辰': '큰 그림을 같이 그리는 자리',
      '巳': '뜨거운 한낮의 결정',
      '午': '환한 정오의 약속',
      '未': '오후의 차 한 잔과 정원',
      '申': '동선이 짧은 도시 산책',
      '酉': '저녁 빛 아래 정돈된 자리',
      '戌': '문 닫고 같이 지키는 공간',
      '亥': '밤바다 같은 깊은 대화',
    };

    test(r'12 entries × 4 조사 = 48 조합 모두 사용자 OCR 어색 표현 0', () {
      // 사용자 OCR 의 핵심 어색 패턴: '공간가', '공간와', '책상가', '책상와',
      // '결정가', '결정와', '첫 발걸음가', '첫 발걸음와', '정원가', '정원와',
      // '약속가', '약속와', '발걸음가', '산책가', '산책와'.
      final forbidden = <String>[];
      for (final scene in jiSceneKo.values) {
        final subj = '$scene${withSubj(scene)}'; // 받침 있으면 '이' → '공간이'.
        final with_ = '$scene${withWith(scene)}'; // 받침 있으면 '과' → '공간과'.
        final obj = '$scene${withObj(scene)}'; // 받침 있으면 '을'.
        final top = '$scene${withTop(scene)}'; // 받침 있으면 '은'.

        // 어색 표현 사전 — 받침 있는 끝 글자 + 받침 없는 글자 조사 결합 시.
        const badForms = [
          '공간가', '공간와', '공간를', '공간는',
          '책상가', '책상와', '책상를', '책상는',
          '걸음가', '걸음와', '걸음를', '걸음는',
          '결정가', '결정와', '결정를', '결정는',
          '정원가', '정원와', '정원를', '정원는',
          '산책가', '산책와', '산책를', '산책는',
          '약속가', '약속와', '약속를', '약속는',
        ];
        for (final bad in badForms) {
          if (subj.contains(bad)) forbidden.add('subj: $subj');
          if (with_.contains(bad)) forbidden.add('with_: $with_');
          if (obj.contains(bad)) forbidden.add('obj: $obj');
          if (top.contains(bad)) forbidden.add('top: $top');
        }
      }
      expect(
        forbidden,
        isEmpty,
        reason: '사용자 OCR 의 어색 조사 결합이 helper 적용 후에도 발생: $forbidden',
      );
    });

    test('壬戌 Water Dog 솔라 / 卯 사용자 케이스 — `공간이` PASS / `공간가` 0', () {
      const stSceneKo = '문 닫고 같이 지키는 공간'; // 戌
      const mySceneKo = '봄빛 들어오는 창가의 대화'; // 卯

      // 사용자 OCR 의 라이브 합성 문장 재구성.
      final line = '너의 $mySceneKo${withWith(mySceneKo)} '
          '솔라의 $stSceneKo${withSubj(stSceneKo)} 어느새 한 시간대로 흘러요.';

      expect(line.contains('공간가'), isFalse, reason: '사용자 OCR 어색 표현 재발: $line');
      expect(line.contains('공간이'), isTrue, reason: '예상 자연 표현 없음: $line');
      expect(
        line.contains('대화와'),
        isTrue,
        reason: '대화 끝 받침 없음 → 와 가 정상: $line',
      );
    });
  });

  group('R98 sprint 1 — kpop_compat 라이브 합성 source-level 가드', () {
    test('kpop_compat_screen.dart 의 jiSceneKo 4 template line 이 helper 호출 사용', () {
      // _composeAnchorDetail 본문이 withSubj / withWith 를 사용해야 라이브 합성에서
      // 공간가 등 어색 표현이 0 가 된다.
      final src = File('lib/screens/reports/kpop_compat_screen.dart')
          .readAsStringSync();
      expect(
        src.contains('withSubj(mySceneKo)') ||
            src.contains('withSubj(stSceneKo)'),
        isTrue,
        reason:
            'kpop_compat_screen.dart 의 _composeAnchorDetail 이 withSubj helper '
            '를 sceneKo 변수에 호출하지 않음 — 공간가 회귀 위험.',
      );
      expect(
        src.contains('withWith(mySceneKo)'),
        isTrue,
        reason:
            'kpop_compat_screen.dart 의 _composeAnchorDetail 이 withWith helper '
            '를 mySceneKo 에 호출하지 않음 — 공간와 회귀 위험.',
      );
    });

    test('kpop_compat_screen.dart 의 _injectShortName helper 가 조사 결합 placeholder 처리', () {
      final src = File('lib/screens/reports/kpop_compat_screen.dart')
          .readAsStringSync();
      // _injectShortName helper 가 존재하고 4 조사 placeholder 모두 보정.
      expect(
        src.contains('_injectShortName'),
        isTrue,
        reason: '_injectShortName helper 누락 — 받침 없는 셀럽 이름 + 조사 결합 깨짐.',
      );
      // 4 조사 placeholder 매핑이 모두 wire.
      for (final placeholder in [
        r'shortName과',
        r'shortName이',
        r'shortName은',
        r'shortName을',
      ]) {
        expect(
          src.contains(placeholder),
          isTrue,
          reason: '_injectShortName 매핑에 $placeholder placeholder 가 누락.',
        );
      }
    });

    test('kpop_compat_screen.dart 의 source raw string 에 hardcoded 공간가/책상가 0', () {
      final src = File('lib/screens/reports/kpop_compat_screen.dart')
          .readAsStringSync();
      for (final bad in const [
        '공간가',
        '공간와',
        '책상가',
        '책상와',
        '결정가',
        '결정와',
      ]) {
        expect(
          src.contains(bad),
          isFalse,
          reason: 'kpop_compat_screen.dart source 안에 어색 조사 결합 "$bad" hardcoded.',
        );
      }
    });
  });
}
