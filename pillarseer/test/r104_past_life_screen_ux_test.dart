// R104 Sprint 2 — 전생 화면 UX 변경 회귀 가드.
//
// 사용자 mandate verbatim (R104 baseline):
//   "전생의 악연/인연 시나리오에서 다시뽑기가 있으면 안되고, 선택하면 밑에 목록은
//    사라지고 결과가 나와야지"
//
// R104 sprint 2 변경:
//   1) "다시 뽑기" 버튼 / past_life_reroll_button key / _compose(reroll:) 진입점 완전 제거.
//   2) 셀럽 선택 + 결과 생성 후 _NameField / _SearchBar / _StarPickerList 를 mount 하지 않음.
//   3) 결과 카드 상단에 "선택한 최애: X" 표시 (past_life_selected_star_bar).
//   4) "다른 최애 고르기" 버튼 (past_life_choose_other_star_button) 으로 picker 복귀.
//
// test env rootBundle 가 celebrities.json 을 로딩하지 못해 셀럽 선택 흐름을 widget
// 으로 끝까지 구동할 수 없으므로, R101/R103 smoke 와 동일하게 source string grep
// 으로 picker hide 로직 / 라벨 / key 부재·존재를 가드한다.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final src = File(
    'lib/screens/reports/past_life_screen.dart',
  ).readAsStringSync();

  group('past_life_screen.dart — R104 다시 뽑기 완전 제거', () {
    test('"다시 뽑기" 라벨 부재', () {
      expect(
        src.contains('다시 뽑기'),
        isFalse,
        reason: 'R104: "다시 뽑기" 라벨이 화면 소스에 잔존',
      );
    });

    test('past_life_reroll_button key 부재', () {
      expect(
        src.contains('past_life_reroll_button'),
        isFalse,
        reason: 'R104: reroll 버튼 key 가 잔존',
      );
    });

    test('reroll seed 회전 진입점 부재', () {
      // _compose(reroll: ...) 파라미터 + seed 회전 진입점 제거.
      expect(
        src.contains('reroll: true'),
        isFalse,
        reason: 'R104: _compose(reroll: true) 진입점 잔존',
      );
      expect(
        src.contains('bool reroll'),
        isFalse,
        reason: 'R104: _compose 의 reroll 파라미터 잔존',
      );
      expect(
        src.contains('onReroll'),
        isFalse,
        reason: 'R104: _ResultCard 의 onReroll 콜백 잔존',
      );
    });
  });

  group('past_life_screen.dart — R104 선택 후 picker/search hide', () {
    test('hasResult 분기 — 결과가 있으면 name/search/picker 미마운트', () {
      // _buildBody 가 결과 유무에 따라 picker 묶음을 조건부 mount.
      expect(
        src.contains('hasResult'),
        isTrue,
        reason: 'R104: picker hide 분기 변수 누락',
      );
      expect(
        src.contains('_selected != null && _scenario != null'),
        isTrue,
        reason: 'R104: 셀럽 선택 + 결과 생성 조건 누락',
      );
      expect(
        src.contains('if (!hasResult) ...['),
        isTrue,
        reason: 'R104: picker 묶음이 hasResult 가 false 일 때만 mount 되지 않음',
      );
    });

    test('name/search/picker 위젯이 조건부 블록 안에 있다', () {
      // _NameField / _SearchBar / _StarPickerList 가 if (!hasResult) 블록 뒤에 위치.
      final idxGuard = src.indexOf('if (!hasResult) ...[');
      final idxName = src.indexOf('_NameField(controller: _nameCtl)');
      final idxSearch = src.indexOf('_SearchBar(');
      final idxPicker = src.indexOf('_StarPickerList(');
      expect(idxGuard, greaterThan(0), reason: 'hasResult guard 누락');
      expect(
        idxName > idxGuard,
        isTrue,
        reason: 'R104: _NameField 가 hasResult guard 밖에 있음',
      );
      expect(
        idxSearch > idxGuard,
        isTrue,
        reason: 'R104: _SearchBar 가 hasResult guard 밖에 있음',
      );
      expect(
        idxPicker > idxGuard,
        isTrue,
        reason: 'R104: _StarPickerList 가 hasResult guard 밖에 있음',
      );
    });
  });

  group('past_life_screen.dart — R104 선택한 최애 표시 + 복귀 버튼', () {
    test('"선택한 최애:" 텍스트 존재', () {
      expect(
        src.contains('선택한 최애: '),
        isTrue,
        reason: 'R104: "선택한 최애: {name}" 표시 누락',
      );
    });

    test('past_life_selected_star_bar key 존재', () {
      expect(
        src.contains('past_life_selected_star_bar'),
        isTrue,
        reason: 'R104: 선택한 최애 바 key 누락',
      );
    });

    test('"다른 최애 고르기" 버튼 + key 존재', () {
      expect(
        src.contains('다른 최애 고르기'),
        isTrue,
        reason: 'R104: 다른 최애 고르기 라벨 누락',
      );
      expect(
        src.contains('past_life_choose_other_star_button'),
        isTrue,
        reason: 'R104: 다른 최애 고르기 버튼 key 누락',
      );
    });

    test('다른 최애 고르기 tap 시 선택/시나리오 초기화', () {
      // _chooseOtherStar 가 _selected / _scenario 를 null 로 되돌려 picker 복귀.
      expect(
        src.contains('_chooseOtherStar'),
        isTrue,
        reason: 'R104: picker 복귀 핸들러 누락',
      );
      expect(
        src.contains('_selected = null'),
        isTrue,
        reason: 'R104: 다른 최애 고르기 시 _selected 초기화 누락',
      );
      expect(
        src.contains('_scenario = null'),
        isTrue,
        reason: 'R104: 다른 최애 고르기 시 _scenario 초기화 누락',
      );
    });
  });

  group('past_life_screen.dart — R104 기존 회귀 가드 보존', () {
    test('scroll fix — primary scroll / shrinkWrap / NeverScrollable 보존', () {
      expect(
        src.contains("Key('past_life_primary_scroll')"),
        isTrue,
        reason: 'R103 primary scroll key 회귀',
      );
      expect(
        src.contains('shrinkWrap: true'),
        isTrue,
        reason: 'R103 shrinkWrap 회귀',
      );
      expect(
        src.contains('NeverScrollableScrollPhysics'),
        isTrue,
        reason: 'R103 NeverScrollableScrollPhysics 회귀',
      );
      expect(
        src.contains('ListView.separated'),
        isTrue,
        reason: 'R103 lazy build (ListView.separated) 회귀',
      );
    });

    test('hero / RepaintBoundary / result body key 보존', () {
      expect(
        src.contains('RepaintBoundary'),
        isTrue,
        reason: 'RepaintBoundary 회귀',
      );
      expect(
        src.contains('past_life_repaint_boundary'),
        isTrue,
        reason: 'RepaintBoundary key 회귀',
      );
      expect(
        src.contains('past_life_result_card'),
        isTrue,
        reason: 'result card key 회귀',
      );
      expect(
        src.contains('past_life_result_body'),
        isTrue,
        reason: 'result body key 회귀',
      );
    });
  });

  group('past_life_screen.dart — R104 seed 고정 제거 + kind 분기 wire', () {
    test('_seed 고정 상수 부재', () {
      // 다시뽑기 제거 후 seed 를 const 1 로 고정하면 같은 keyword 사용자가 모두
      // 같은 arc 를 받는다. 화면은 seed 를 넘기지 않고 service 의
      // _deriveSeed(user, celeb) 가 (user,celeb) 별 deterministic seed 를 만든다.
      expect(
        src.contains('static const int _seed'),
        isFalse,
        reason: 'R104: _seed 고정 상수 잔존 — arc 변별 막힘',
      );
    });

    test('generate 호출에 seed: _seed 부재', () {
      expect(
        src.contains('seed: _seed'),
        isFalse,
        reason: 'R104: 화면이 seed 를 강제 전달 — service deriveSeed fallback 차단',
      );
    });

    test('generate 호출에 kind: star.kind 존재', () {
      // modernPunchlineByKind 가 idol/actor/athlete/icon 분기를 타려면
      // 화면이 셀럽 kind 를 service 에 전달해야 한다.
      expect(
        src.contains('kind: star.kind'),
        isTrue,
        reason: 'R104: 셀럽 kind 미전달 — punchline 분기 무효',
      );
    });
  });
}
