// Round 78 sprint 3 — _OracleHero 30 ment + ctx entries invariant 가드.
//
// invariant (R71 spec / home_screen.dart docstring 명시):
//   - restDay: "공식 자리·발표·승진·도전·승부" 단어 0
//   - actionDay: "쉬어가·아끼" 단어 0
// Sprint 3 에서 _ctxEntries 신규 추가됨 — 동일 invariant 가드.

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('home_screen _pool + _ctxEntries 본문 invariant', () {
    final src = File('lib/screens/home_screen.dart').readAsStringSync();

    // 본 검증은 source 텍스트 grep — _pool 과 _ctxEntries 두 영역 모두 cover.
    // restDay 본문 영역 추출 — `DayEnergyKind.restDay:` 부터 `DayEnergyKind.mixedDay:` 전까지
    final restStart = src.indexOf('DayEnergyKind.restDay:');
    final restEnd = src.indexOf('DayEnergyKind.mixedDay:');
    expect(restStart >= 0 && restEnd > restStart, isTrue);
    final restPart = src.substring(restStart, restEnd);

    // restDay 본문에 금지 단어 0.
    const restForbidden = ['공식 자리', '발표', '승진', '도전', '승부'];
    for (final w in restForbidden) {
      expect(restPart.contains(w), isFalse,
          reason: 'restDay _pool 본문에 금칙 단어 "$w" 발견');
    }

    final actionStart = src.indexOf('DayEnergyKind.actionDay:');
    final actionEnd = src.indexOf('};', actionStart);
    final actionPart = src.substring(actionStart, actionEnd);
    const actionForbidden = ['쉬어가', '아끼'];
    for (final w in actionForbidden) {
      expect(actionPart.contains(w), isFalse,
          reason: 'actionDay _pool 본문에 금칙 단어 "$w" 발견');
    }

    // _ctxEntries 영역 — Sprint 3 신규. 같은 invariant 적용.
    final ctxStart = src.indexOf('_ctxEntries');
    final ctxEnd = src.indexOf('];', ctxStart);
    expect(ctxStart >= 0 && ctxEnd > ctxStart, isTrue);
    final ctxPart = src.substring(ctxStart, ctxEnd);

    // ctx entries 중 restDay key 만 추출.
    // 'oracle_hero.restDay.辛' 포함된 entry block.
    final restCtxRegex =
        RegExp(r"key:\s*'oracle_hero\.restDay\.[^']*'", multiLine: true);
    final restMatches = restCtxRegex.allMatches(ctxPart).toList();
    expect(restMatches.isNotEmpty, isTrue,
        reason: '_ctxEntries 에 restDay key entry 보유');

    for (final w in restForbidden) {
      // 본 검증은 source 전체 ctx 영역 — actionDay/mixedDay 본문에 도전 등이 들어가도 OK.
      // 따라서 restDay key 가 있는 entry block 부근 (~ 6 줄 안) 만 검사.
      for (final m in restMatches) {
        final entryStart = m.start;
        // bodies 본문 영역 — restDay entry 가 끝나기 전까지 (다음 entry 또는 ];).
        var entryEnd = ctxPart.indexOf('),', entryStart);
        if (entryEnd < 0) entryEnd = ctxPart.length;
        final entryText = ctxPart.substring(entryStart, entryEnd);
        expect(entryText.contains(w), isFalse,
            reason: '_ctxEntries restDay entry 본문에 금칙 "$w"');
      }
    }
  });
}
