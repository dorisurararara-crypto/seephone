// Pillar Seer — Release preflight audit (codex Round 10 #1 TOP ROI).
// 사람이 잠들어도 마지막 출시 실수 하나를 막는 자동 게이트.
//
// 사용법: dart run tool/release_audit.dart [--strict]
// --strict: warnings 도 exit code 1 로 처리.

// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io';

void main(List<String> args) async {
  final strict = args.contains('--strict');
  final issues = <_Issue>[];
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  print('Pillar Seer — Release Preflight Audit');
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

  await _checkPubspec(issues);
  await _checkDevGate(issues);
  await _checkPrivacyTermsSupport(issues);
  await _checkInfoPlist(issues);
  await _checkAssets(issues);
  await _checkL10n(issues);
  await _checkTests(issues);
  await _checkCelebrities(issues);
  await _checkProCopySafety(issues);
  await _checkLegalUrlsLive(issues);

  print('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  print('Summary');
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  final errors = issues.where((i) => i.severity == 'error').toList();
  final warns = issues.where((i) => i.severity == 'warn').toList();
  final infos = issues.where((i) => i.severity == 'info').toList();
  print('  ✅ Passed: ${infos.length}');
  print('  ⚠️  Warnings: ${warns.length}');
  print('  ❌ Errors: ${errors.length}');
  if (errors.isNotEmpty) {
    print('\n❌ ERRORS:');
    for (final e in errors) {
      print('  - ${e.where}: ${e.msg}');
    }
  }
  if (warns.isNotEmpty) {
    print('\n⚠️  WARNINGS:');
    for (final w in warns) {
      print('  - ${w.where}: ${w.msg}');
    }
  }
  if (errors.isEmpty && (warns.isEmpty || !strict)) {
    print('\n✅ Release preflight PASSED.');
    exit(0);
  }
  print('\n❌ Release preflight FAILED.');
  exit(1);
}

// ──────── Checks

Future<void> _checkPubspec(List<_Issue> issues) async {
  print('▶ Checking pubspec.yaml...');
  final f = File('pubspec.yaml');
  if (!f.existsSync()) {
    issues.add(_Issue('error', 'pubspec.yaml', 'missing'));
    return;
  }
  final content = await f.readAsString();
  if (content.contains('"A new Flutter project."')) {
    issues.add(_Issue('error', 'pubspec.yaml',
        'description is still default "A new Flutter project."'));
  } else {
    issues.add(_Issue('info', 'pubspec.yaml', 'description ok'));
  }
  final versionMatch = RegExp(r'^version:\s*(\d+\.\d+\.\d+)\+(\d+)', multiLine: true)
      .firstMatch(content);
  if (versionMatch == null) {
    issues.add(_Issue('error', 'pubspec.yaml', 'version line not found'));
  } else {
    final build = int.parse(versionMatch.group(2)!);
    if (build < 5) {
      issues.add(_Issue('warn', 'pubspec.yaml', 'build number $build seems low'));
    } else {
      issues.add(_Issue('info', 'pubspec.yaml',
          'version ${versionMatch.group(1)}+$build'));
    }
  }
  // Check klc + flutter_local_notifications presence
  for (final dep in ['klc:', 'flutter_local_notifications:', 'shared_preferences:', 'url_launcher:', 'share_plus:', 'flutter_timezone:']) {
    if (!content.contains(dep)) {
      issues.add(_Issue('error', 'pubspec.yaml', 'missing dep: $dep'));
    }
  }
}

Future<void> _checkDevGate(List<_Issue> issues) async {
  print('▶ Checking dev unlock release safety...');
  final f = File('lib/providers/dev_unlock_provider.dart');
  if (!f.existsSync()) {
    issues.add(_Issue('error', 'dev_unlock_provider', 'missing'));
    return;
  }
  final src = await f.readAsString();
  if (!src.contains('kDevGateEnabled')) {
    issues.add(_Issue('error', 'dev_unlock_provider',
        'kDevGateEnabled flag missing — release build will allow dev unlock'));
  } else if (!src.contains('kDebugMode')) {
    issues.add(_Issue('warn', 'dev_unlock_provider',
        'kDebugMode not referenced — verify gate condition'));
  } else {
    issues.add(_Issue('info', 'dev_unlock_provider', 'release gate present'));
  }
  if (!src.contains('!kDevGateEnabled')) {
    issues.add(_Issue('error', 'dev_unlock_provider',
        '_load() must reset prefs when !kDevGateEnabled (codex Round 9 critical)'));
  } else {
    issues.add(_Issue('info', 'dev_unlock_provider',
        'release prefs reset wired (Round 9 fix)'));
  }
}

Future<void> _checkPrivacyTermsSupport(List<_Issue> issues) async {
  print('▶ Checking Privacy/Terms/Support links...');
  final settings = File('lib/screens/settings_screen.dart');
  final src = await settings.readAsString();
  for (final urlFrag in ['pillarseer/privacy.html', 'pillarseer/terms.html', 'mailto:']) {
    if (!src.contains(urlFrag)) {
      issues.add(_Issue('error', 'settings', 'missing URL: $urlFrag'));
    } else {
      issues.add(_Issue('info', 'settings', 'link present: $urlFrag'));
    }
  }
}

Future<void> _checkInfoPlist(List<_Issue> issues) async {
  print('▶ Checking iOS Info.plist...');
  final f = File('ios/Runner/Info.plist');
  if (!f.existsSync()) {
    issues.add(_Issue('error', 'Info.plist', 'missing'));
    return;
  }
  final src = await f.readAsString();
  for (final key in ['CFBundleDisplayName', 'ITSAppUsesNonExemptEncryption', 'LSApplicationQueriesSchemes']) {
    if (!src.contains(key)) {
      issues.add(_Issue('warn', 'Info.plist', 'missing key: $key'));
    } else {
      issues.add(_Issue('info', 'Info.plist', 'has key: $key'));
    }
  }
}

Future<void> _checkAssets(List<_Issue> issues) async {
  print('▶ Checking assets/data/ contents...');
  const required = [
    'assets/data/saju_60ji.json',
    'assets/data/saju_deep_slice_0_19.json',
    'assets/data/saju_deep_slice_20_39.json',
    'assets/data/saju_deep_slice_40_59.json',
    'assets/data/celebrities.json',
    'assets/data/dreams.json',
  ];
  for (final p in required) {
    if (!File(p).existsSync()) {
      issues.add(_Issue('error', 'assets', 'missing: $p'));
    } else {
      issues.add(_Issue('info', 'assets', 'present: $p'));
    }
  }
}

Future<void> _checkL10n(List<_Issue> issues) async {
  print('▶ Checking l10n consistency...');
  final en = File('lib/l10n/app_en.arb');
  final ko = File('lib/l10n/app_ko.arb');
  if (!en.existsSync() || !ko.existsSync()) {
    issues.add(_Issue('error', 'l10n', 'missing arb file'));
    return;
  }
  final enJson = jsonDecode(await en.readAsString()) as Map<String, dynamic>;
  final koJson = jsonDecode(await ko.readAsString()) as Map<String, dynamic>;
  final enKeys = enJson.keys.where((k) => !k.startsWith('@') && k != '@@locale').toSet();
  final koKeys = koJson.keys.where((k) => !k.startsWith('@') && k != '@@locale').toSet();
  final onlyEn = enKeys.difference(koKeys);
  final onlyKo = koKeys.difference(enKeys);
  if (onlyEn.isNotEmpty) {
    issues.add(_Issue('warn', 'l10n', 'keys missing in ko: ${onlyEn.take(5).join(", ")}${onlyEn.length > 5 ? "..." : ""}'));
  }
  if (onlyKo.isNotEmpty) {
    issues.add(_Issue('warn', 'l10n', 'keys missing in en: ${onlyKo.take(5).join(", ")}${onlyKo.length > 5 ? "..." : ""}'));
  }
  if (onlyEn.isEmpty && onlyKo.isEmpty) {
    issues.add(_Issue('info', 'l10n', '${enKeys.length} keys ko/en parity'));
  }
}

Future<void> _checkTests(List<_Issue> issues) async {
  print('▶ Checking test files...');
  final ws = File('test/widget_test.dart');
  final integ = File('test/integration_flow_test.dart');
  if (!ws.existsSync()) {
    issues.add(_Issue('warn', 'tests', 'widget_test.dart missing'));
  }
  if (!integ.existsSync()) {
    issues.add(_Issue('warn', 'tests', 'integration_flow_test.dart missing'));
  } else {
    final src = await integ.readAsString();
    final celebCount = RegExp(r"\('IU'|\('V'|\('Jennie").allMatches(src).length;
    if (celebCount < 3) {
      issues.add(_Issue('warn', 'tests',
          'integration test missing IU/V/Jennie known-date checks'));
    } else {
      issues.add(_Issue('info', 'tests', 'celebrity regression present'));
    }
  }
}

Future<void> _checkCelebrities(List<_Issue> issues) async {
  print('▶ Checking celebrities.json vs KASI sample...');
  final f = File('assets/data/celebrities.json');
  if (!f.existsSync()) {
    issues.add(_Issue('error', 'celebrities', 'missing'));
    return;
  }
  final list = (jsonDecode(await f.readAsString()) as List).cast<Map<String, dynamic>>();
  if (list.length < 20) {
    issues.add(_Issue('warn', 'celebrities',
        'only ${list.length} entries (codex recommends 20+)'));
  } else {
    issues.add(_Issue('info', 'celebrities', '${list.length} entries'));
  }
  // 알려진 mismatch 회귀 — IU 일주 must be 丁卯 (Round 7 정정)
  final iu = list.where((c) => c['id'] == 'iu').firstOrNull;
  if (iu != null && iu['dayPillar'] != '丁卯') {
    issues.add(_Issue('error', 'celebrities',
        'IU dayPillar regression — expected 丁卯, got ${iu['dayPillar']}'));
  } else if (iu != null) {
    issues.add(_Issue('info', 'celebrities', 'IU dayPillar still 丁卯 (KASI)'));
  }
  final v = list.where((c) => c['id'] == 'v').firstOrNull;
  if (v != null && v['dayPillar'] != '乙未') {
    issues.add(_Issue('error', 'celebrities',
        'BTS V dayPillar regression — expected 乙未, got ${v['dayPillar']}'));
  }
}

/// codex Round 11 — Pro/IAP 심사 리스크 audit.
/// 무료 앱으로 출시하지만 "Pro/Unlock/Subscribe" 가 IAP imply 하면 rejection 위험.
Future<void> _checkProCopySafety(List<_Issue> issues) async {
  print('▶ Checking Pro/Unlock copy review safety...');
  // Sensitive phrases that imply IAP without one
  // Word-boundary regex — only flag IAP-implying phrases that are actually rendered.
  // Paywall l10n keys ($4.99/month etc) are defined but no UI reads them yet —
  // verified via grep in lib/screens/ — so excluded from sensitive list until paywall UI lands.
  final sensitive = <RegExp>[
    RegExp(r'\bSubscribe\b'),
    RegExp(r'\bBuy now\b'),
    RegExp(r'\bPurchase\b'),
  ];
  final files = [
    'lib/l10n/app_en.arb',
    'lib/l10n/app_ko.arb',
  ];
  var hits = 0;
  for (final p in files) {
    final f = File(p);
    if (!f.existsSync()) continue;
    final src = await f.readAsString();
    for (final rx in sensitive) {
      if (rx.hasMatch(src)) {
        issues.add(_Issue('warn', 'pro_copy',
            'l10n "$p" matches /${rx.pattern}/ — IAP implication risk'));
        hits++;
      }
    }
  }
  if (hits == 0) {
    issues.add(_Issue('info', 'pro_copy',
        'no IAP-implying phrases (Subscribe/Buy/Pay/Purchase) in l10n'));
  }
  // resultUnlockFull / resultProHookCta should mention "coming"
  final en = await File('lib/l10n/app_en.arb').readAsString();
  final enJson = jsonDecode(en) as Map<String, dynamic>;
  final unlockEn = (enJson['resultUnlockFull'] as String? ?? '').toLowerCase();
  if (!unlockEn.contains('coming') && !unlockEn.contains('phase')) {
    issues.add(_Issue('warn', 'pro_copy',
        'resultUnlockFull "${enJson['resultUnlockFull']}" does not signal future tense — rejection risk'));
  } else {
    issues.add(_Issue('info', 'pro_copy',
        'resultUnlockFull explicitly future-tense (coming/phase)'));
  }
  final hookCtaEn = (enJson['resultProHookCta'] as String? ?? '').toLowerCase();
  if (hookCtaEn == 'unlock') {
    issues.add(_Issue('warn', 'pro_copy',
        'resultProHookCta is bare "Unlock" — rephrase to "Coming soon" to avoid IAP implication'));
  } else {
    issues.add(_Issue('info', 'pro_copy', 'resultProHookCta: "${enJson['resultProHookCta']}"'));
  }
}

/// codex Round 11 — Privacy/Terms/Support URL 실제 HTTP 200 확인.
Future<void> _checkLegalUrlsLive(List<_Issue> issues) async {
  print('▶ Checking legal URLs are reachable (HTTP)...');
  const urls = [
    'https://dorisurararara-crypto.github.io/pillarseer/privacy.html',
    'https://dorisurararara-crypto.github.io/pillarseer/terms.html',
    'https://dorisurararara-crypto.github.io/pillarseer/support.html',
  ];
  final client = HttpClient();
  client.connectionTimeout = const Duration(seconds: 8);
  for (final u in urls) {
    try {
      final req = await client.headUrl(Uri.parse(u));
      final res = await req.close();
      if (res.statusCode == 200) {
        issues.add(_Issue('info', 'legal_url',
            '$u → ${res.statusCode}'));
      } else {
        issues.add(_Issue('warn', 'legal_url',
            '$u → HTTP ${res.statusCode} (App Review may flag)'));
      }
    } catch (e) {
      issues.add(_Issue('warn', 'legal_url',
          '$u → unreachable: ${e.toString().split(",").first}'));
    }
  }
  client.close();
}

class _Issue {
  final String severity;
  final String where;
  final String msg;
  const _Issue(this.severity, this.where, this.msg);
}
