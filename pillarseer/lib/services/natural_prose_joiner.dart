/// Korean prose post-processor for deterministic generated paragraphs.
///
/// Round 96 hotfix (1.0.0+55 실기기 어색 fix) —
///   Previously this helper auto-injected Korean connectors
///   ("그래서/그 흐름 위에/덕분에/한편/다만/동시에/거기에/그 분위기 그대로/
///    한 발 더 가면/그러니까") between *meaningfully unrelated* atomic
///   sentences. On real-device readout the result felt like fake causation
///   ("본인 스타일대로 가요. 그래서 사람들이 본인을 기억해요. 그 흐름 위에
///    그게 장점이에요. 덕분에 배움이 자리잡아요. 한편 수면을 챙기세요.")
///   — fluent on paper, dishonest as actual oracle prose.
///
///   The user verdict: "말 자체가 어색한데 본인스타일대로 가서 사람들이 나를
///   기억한다? 그 흐름위에 그게 장점이라고??"
///
///   So this helper is now narrowed to **mechanical hygiene only**:
///     - trim each fragment, collapse internal whitespace,
///     - drop empty fragments,
///     - ensure a sentence terminator on each fragment,
///     - join with a single space.
///   Public API (`join` / `append` / `polish`) is preserved so call sites
///   in `home_screen.dart`, `today_deep_service.dart`,
///   `today_event_service.dart`, `life_overview_service.dart`,
///   `life_paragraph_service.dart`, `self_conclusion_service.dart`,
///   `additional_life_service.dart`, `personalization_engine.dart`,
///   `reports/new_year_2026_screen.dart` keep working without edits.
///
///   No connector word is added. No 종결 mutation (...에요. → ...죠) is
///   performed. The result reads slightly flatter, but every clause is
///   the clause the upstream service actually intended.
class NaturalProseJoiner {
  const NaturalProseJoiner._();

  /// Append [extras] to [base] and re-stitch into a single paragraph.
  static String append(String base, Iterable<String> extras) {
    return join([base, ...extras]);
  }

  /// Polish a single multi-sentence paragraph: trim, normalize whitespace,
  /// ensure each sentence has a terminator. **No** connector injection.
  static String polish(String text) {
    final sentences = _splitSentences(text);
    if (sentences.isEmpty) return '';
    if (sentences.length == 1) return _ensureSentenceEnd(sentences.first);
    return join(sentences);
  }

  /// Join fragments. Each fragment is split into sentences on `.!?。`, then
  /// every sentence is trimmed, deduplicated against the immediate previous
  /// sentence, terminator-fixed, and concatenated with a single space.
  static String join(Iterable<String> fragments) {
    final sentences = <String>[];
    for (final fragment in fragments) {
      sentences.addAll(_splitSentences(fragment));
    }
    if (sentences.isEmpty) return '';
    if (sentences.length == 1) return _ensureSentenceEnd(sentences.first);

    final out = <String>[];
    String? prev;
    for (final raw in sentences) {
      final s = _ensureSentenceEnd(raw);
      if (s.isEmpty) continue;
      // 인접 sentence 동일 시 dedup (upstream service 가 같은 atom 두 번
      // 흘려보내는 경우 방어).
      if (prev != null && prev == s) continue;
      out.add(s);
      prev = s;
    }
    return out.join(' ');
  }

  static List<String> _splitSentences(String text) {
    final normalized = text
        .replaceAll('\r\n', '\n')
        .replaceAll('\n', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (normalized.isEmpty) return const [];

    final matches = RegExp(r'[^.!?。]+[.!?。]?').allMatches(normalized);
    return matches
        .map((m) => m.group(0)!.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  static String _ensureSentenceEnd(String sentence) {
    final t = sentence.trim();
    if (t.isEmpty) return t;
    if (t.endsWith('.') ||
        t.endsWith('!') ||
        t.endsWith('?') ||
        t.endsWith('。')) {
      return t;
    }
    return '$t.';
  }
}
