// Pillar Seer — Round 77 종합 회귀 가드 (Sprint 8 cleanup).
// 8 sprint 누적 110+ fix 가 다시 망가지지 않도록 lib + assets/data 정적 grep 검증.
//
// 검사 항목 (9 assertion):
//  A1. 한자 jargon 잔존 0 (Sprint 4 한국어 톤 mandate)
//  A2. 영문 ChatGPT 슬롭 잔존 0 (Sprint 5 영문 톤 mandate)
//  A3. 한국어 grammar / 단어 중복 잔존 0 (Sprint 4/5)
//  A4. 텍스트 별점 "★ ☆" 잔존 0 (Sprint 7 색 게이지 전환)
//  A5. SajuResult.dummy() 호출처 = factory 정의 1건만 (Sprint 8 mandate)
//  A6. 의료 단정 잔존 0 (Sprint 3 Apple 1.4.1)
//  A7. 금융 단정 잔존 0 (Sprint 3 Apple 5.2.1)
//  A8. 사망 단정 잔존 0 (Sprint 3 Apple 1.4.1)
//  A9. 1995-10-27 男 골든 5행 16/21/17/41/4 보존 (Round 75 mandate)
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pillarseer/services/manseryeok_service.dart';

/// 검사 대상 파일 enumerate.
/// - [extensions] 확장자 화이트리스트 (예: `.dart`, `.json`).
/// - [excludeDirs] 절대/상대 디렉토리 prefix 화이트리스트 외 (test/, build/, .dart_tool/ 제외).
List<File> _walk(
  String root, {
  required Set<String> extensions,
  Set<String> excludeDirs = const {'.dart_tool', 'build', 'test'},
}) {
  final dir = Directory(root);
  if (!dir.existsSync()) return const <File>[];
  return dir
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) {
        final p = f.path;
        if (excludeDirs.any((d) => p.contains('/$d/'))) return false;
        return extensions.any(p.endsWith);
      })
      .toList();
}

/// 패턴 매칭 파일을 모아 fail 메시지 1줄로 묶음.
String? _firstHit(List<File> files, RegExp pattern) {
  for (final f in files) {
    final content = f.readAsStringSync();
    final m = pattern.firstMatch(content);
    if (m != null) {
      // line number 찾기
      final upto = content.substring(0, m.start);
      final line = '\n'.allMatches(upto).length + 1;
      return '${f.path}:$line matched "${m.group(0)}"';
    }
  }
  return null;
}

/// 패턴 매칭 모든 위치를 list 로 반환 (최대 [limit] 개).
List<String> _allHits(List<File> files, RegExp pattern, {int limit = 10}) {
  final hits = <String>[];
  for (final f in files) {
    final content = f.readAsStringSync();
    for (final m in pattern.allMatches(content)) {
      final upto = content.substring(0, m.start);
      final line = '\n'.allMatches(upto).length + 1;
      hits.add('${f.path}:$line "${m.group(0)}"');
      if (hits.length >= limit) return hits;
    }
  }
  return hits;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final libDartFiles = _walk('lib', extensions: {'.dart'},
      excludeDirs: {'.dart_tool', 'build', 'test'});
  // l10n autogen 파일은 ARB 와 중복되므로 제외 — 한자 jargon 검사 시 명시적 제거.
  final libDartFilesNoL10n = libDartFiles
      .where((f) => !f.path.contains('/l10n/app_localizations'))
      .toList();
  final assetDataFiles = _walk('assets/data',
      extensions: {'.json'},
      excludeDirs: {'.dart_tool', 'build', 'test'});
  final arbFiles = _walk('lib/l10n',
      extensions: {'.arb'},
      excludeDirs: {'.dart_tool', 'build', 'test'});

  group('Round 77 — Final cleanup regression', () {
    test('A1. 한자 jargon 잔존 0 (Sprint 4)', () {
      // 금지 어휘 (Sprint 4 mandate 회귀): "마음의 결 / 본인의 결 / 본질이에요
      // / 본성이에요 / 운기가/운기는 (서술형)". '기운' 단어 자체는 한국어 일반
      // 명사이며 yongsin label ("필요한 기운") 등 정당한 사용이 있어 제외.
      final pattern = RegExp(r'(마음의\s?결|본인의\s?결|본질이에요'
          r'|본성이에요|운기가\s|운기는\s)');
      final hit = _firstHit([...libDartFilesNoL10n, ...assetDataFiles], pattern);
      expect(
        hit,
        isNull,
        reason: '한자 jargon 잔존 발견 — Sprint 4 회귀: $hit',
      );
    });

    test('A2. 영문 ChatGPT 슬롭 잔존 0 (Sprint 5)', () {
      // Sprint 5 fix 슬롭 패턴: "your essence carries / your destiny carries
      // / your grains align / Stay in your color / marriage-grain / a stage
      // person / Cut cleanly\."
      final pattern = RegExp(
        r'(your\s+essence\s+carries|your\s+destiny\s+carries'
        r'|your\s+grains\s+align|Stay\s+in\s+your\s+color'
        r'|marriage-grain|a\s+stage\s+person|Cut\s+cleanly\.)',
      );
      final hit = _firstHit([...libDartFilesNoL10n, ...assetDataFiles, ...arbFiles], pattern);
      expect(
        hit,
        isNull,
        reason: '영문 ChatGPT 슬롭 잔존 — Sprint 5 회귀: $hit',
      );
    });

    test('A3. 영문 grammar 깨짐 잔존 0 (Sprint 5)', () {
      // Sprint 5 fix grammar: "for works / for is / Career for works
      // / In love, is magnetic / Family karma for / Fame.*for come".
      final pattern = RegExp(
        r'(Career\s+for\s+works'
        r'|Wealth\s+for\s+is'
        r'|In\s+love,\s+is\s+magnetic'
        r'|Family\s+karma\s+for'
        r'|Fame\s+for\s+come)',
      );
      final hit = _firstHit([...libDartFilesNoL10n, ...assetDataFiles, ...arbFiles], pattern);
      expect(
        hit,
        isNull,
        reason: '영문 grammar 깨짐 잔존 — Sprint 5 회귀: $hit',
      );
    });

    test('A4. 텍스트 별점 "★ ☆" 잔존 0 (Sprint 7)', () {
      // Sprint 7 — 별점 텍스트 → 색 게이지 전환. 본문/카드/공유에 ★/☆ 0개.
      // 단, 주석 (`//`) 안 등장은 회귀가 아니라 변경 history 보존이므로 제외.
      final pattern = RegExp(r'[★☆]');
      final hits = <String>[];
      for (final f in [...libDartFilesNoL10n, ...assetDataFiles]) {
        final content = f.readAsStringSync();
        for (final m in pattern.allMatches(content)) {
          // 해당 라인이 주석 (`//` 또는 `*`) 인지 확인.
          final upto = content.substring(0, m.start);
          final lineStart = upto.lastIndexOf('\n') + 1;
          final lineEnd = content.indexOf('\n', m.start);
          final line = content.substring(
              lineStart, lineEnd == -1 ? content.length : lineEnd);
          final trimmed = line.trim();
          if (trimmed.startsWith('//') || trimmed.startsWith('*')) continue;
          final lineNo = '\n'.allMatches(upto).length + 1;
          hits.add('${f.path}:$lineNo "${m.group(0)}"');
        }
      }
      expect(
        hits,
        isEmpty,
        reason: '텍스트 별점 잔존 — Sprint 7 회귀: $hits',
      );
    });

    test('A5. SajuResult.dummy() 호출처 = factory 정의 1건만 (Sprint 8 mandate)', () {
      // factory 정의 (lib/models/saju_result.dart) + 주석 외 호출 0.
      final pattern = RegExp(r'SajuResult\.dummy\(\)');
      final hits = _allHits(libDartFiles, pattern, limit: 20);
      // production code 에서 호출은 X. 단, factory 정의 자체는 패턴 매치 안 됨
      // (`factory SajuResult.dummy()` 형식은 위 정규식과 `.dummy()` 자체는 매치하지만
      // 정의 라인은 외부 호출이 아님). saju_required_empty.dart 의 주석은
      // 호출 없이 식별자만 등장. 화이트리스트:
      //  - lib/models/saju_result.dart (factory 정의)
      //  - lib/widgets/saju_required_empty.dart (주석)
      //  - lib/screens/* (Sprint 8 fix 주석)
      // 즉 production 호출은 0 이어야 함.
      // 호출 vs 정의 구분: 호출은 보통 `?? SajuResult.dummy()` 또는 `SajuResult.dummy();`
      // 형식. 정의는 `factory SajuResult.dummy() {`. 정규식만으로는 구분 어려우니,
      // 호출 패턴 (= 또는 `??` 또는 stmt 끝 `;`) 만 검사.
      final callPattern = RegExp(r'(\?\?\s*SajuResult\.dummy\(\)|=\s*SajuResult\.dummy\(\)|SajuResult\.dummy\(\)\s*;)');
      final callHits = _allHits(libDartFiles, callPattern, limit: 20);
      expect(
        callHits,
        isEmpty,
        reason: 'SajuResult.dummy() production 호출 잔존: $callHits (전체 매치: $hits)',
      );
    });

    test('A6. 의료 단정 잔존 0 (Sprint 3 Apple 1.4.1)', () {
      final pattern = RegExp(
        r'(예약을\s?잡으세요'
        r'|Schedule\s+the\s+appointment'
        r'|예약\s?잡으세요'
        r'|진료를\s?받으세요'
        r'|blood\s+pressure\s+check\s+window\s+opens)',
      );
      final hit = _firstHit([...libDartFilesNoL10n, ...assetDataFiles, ...arbFiles], pattern);
      expect(
        hit,
        isNull,
        reason: '의료 단정 잔존 — Sprint 3 회귀: $hit',
      );
    });

    test('A7. 금융 단정 잔존 0 (Sprint 3 Apple 5.2.1)', () {
      final pattern = RegExp(
        r'(수령\s?확정'
        r'|확정된\s?예상치\s?못한'
        r'|최상위\s?수입의\s?확정'
        r'|Never\s+co-sign'
        r'|보장된\s?수익'
        r'|평생\s?자산이\s?단단해져요)',
      );
      final hit = _firstHit([...libDartFilesNoL10n, ...assetDataFiles, ...arbFiles], pattern);
      expect(
        hit,
        isNull,
        reason: '금융 단정 잔존 — Sprint 3 회귀: $hit',
      );
    });

    test('A8. 사망 단정 잔존 0 (Sprint 3 Apple 1.4.1)', () {
      final pattern = RegExp(
        r'(you\s+lose\s+a\s+family\s+member'
        r'|grief\s+lands\s+hard'
        r'|가족이\s?사망)',
      );
      final hit = _firstHit([...libDartFilesNoL10n, ...assetDataFiles, ...arbFiles], pattern);
      expect(
        hit,
        isNull,
        reason: '사망 단정 잔존 — Sprint 3 회귀: $hit',
      );
    });

    test('A9. 1995-10-27 男 골든 5행 16/21/17/41/4 보존 (Round 75 mandate)', () {
      final r = ManseryeokService.calculate(
        year: 1995,
        month: 10,
        day: 27,
        hour: 15,
        minute: 43,
        isLunar: false,
        isMale: true,
      );
      expect(r.elements.wood, 16, reason: 'wood 골든');
      expect(r.elements.fire, 21, reason: 'fire 골든');
      expect(r.elements.earth, 17, reason: 'earth 골든');
      expect(r.elements.metal, 41, reason: 'metal 골든');
      expect(r.elements.water, 4, reason: 'water 골든');
    });

    test('ARB 미사용 키 (dreamCategoryHealth / navDiscover) 정리 검증 (Sprint 8)', () {
      // ARB 양 locale 에서 키 0.
      for (final f in arbFiles) {
        final raw = f.readAsStringSync();
        final json = jsonDecode(raw) as Map<String, dynamic>;
        expect(json.containsKey('dreamCategoryHealth'), isFalse,
            reason: '${f.path} 에 dreamCategoryHealth 잔존');
        expect(json.containsKey('navDiscover'), isFalse,
            reason: '${f.path} 에 navDiscover 잔존');
      }
    });
  });
}
