/// Korean prose post-processor for deterministic generated paragraphs.
///
/// The app has many small, correct sentence atoms. Joining those atoms with a
/// plain space makes the result read like a checklist. This helper keeps the
/// original meaning, but adds light connective tissue between atoms.
class NaturalProseJoiner {
  static const List<String> _connectors = [
    '그래서',
    '그 흐름 위에',
    '덕분에',
    '한편',
    '다만',
    '동시에',
    '거기에',
    '그 분위기 그대로',
    '한 발 더 가면',
    '그러니까',
  ];

  static const List<String> _softConnectors = ['그리고', '또', '이어서'];

  const NaturalProseJoiner._();

  static String append(String base, Iterable<String> extras) {
    return join([base, ...extras]);
  }

  static String polish(String text) {
    final sentences = _splitSentences(text);
    if (sentences.length <= 1) return text.trim();
    return join(sentences);
  }

  static String join(Iterable<String> fragments) {
    final sentences = <String>[];
    for (final fragment in fragments) {
      sentences.addAll(_splitSentences(fragment));
    }
    if (sentences.isEmpty) return '';
    if (sentences.length == 1) return _ensureSentenceEnd(sentences.first);

    final out = <String>[];
    for (var i = 0; i < sentences.length; i += 1) {
      var sentence = _ensureSentenceEnd(sentences[i]);
      if (i > 0 && !_startsWithConnector(sentence)) {
        final connector = _connectorFor(i, sentences.length);
        sentence = '$connector ${_lowerTodayStart(sentence)}';
      }
      sentence = _varyEnding(sentence, i);
      out.add(sentence);
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

  static bool _startsWithConnector(String sentence) {
    final s = sentence.trimLeft();
    return [
      ..._connectors,
      ..._softConnectors,
      '특히',
      '반대로',
      '대신',
      '오히려',
    ].any((c) => s.startsWith(c));
  }

  static String _connectorFor(int index, int total) {
    if (total < 4) return _softConnectors[(index - 1) % _softConnectors.length];
    return _connectors[(index - 1) % _connectors.length];
  }

  static String _lowerTodayStart(String sentence) {
    return sentence
        .replaceFirst(RegExp(r'^오늘은\s+'), '')
        .replaceFirst(RegExp(r'^본인은\s+'), '본인은 ');
  }

  static String _varyEnding(String sentence, int index) {
    if (index == 0) return sentence;
    if (index % 5 == 1 && sentence.endsWith('흐름이에요.')) {
      return '${sentence.substring(0, sentence.length - '흐름이에요.'.length)}흐름이죠.';
    }
    if (index % 5 == 2 && sentence.endsWith('날이에요.')) {
      return '${sentence.substring(0, sentence.length - '날이에요.'.length)}날이네요.';
    }
    if (index % 5 == 3 && sentence.endsWith('좋아요.')) {
      return '${sentence.substring(0, sentence.length - '좋아요.'.length)}좋죠.';
    }
    if (index % 5 == 4 && sentence.endsWith('돼요.')) {
      return '${sentence.substring(0, sentence.length - '돼요.'.length)}될 거예요.';
    }
    if (index % 4 == 2 &&
        sentence.endsWith('에요.') &&
        !sentence.endsWith('이에요.')) {
      // `이에요.` 는 표준 한국어 — `예요.` 축약은 받침 없을 때만 자연.
      // substring 단순 변환 시 `흐름이에요.` → `흐름이예요.` 비표준 회귀가 나므로
      // `이에요.` 결합 형태는 그대로 둔다.
      return '${sentence.substring(0, sentence.length - '에요.'.length)}예요.';
    }
    return sentence;
  }
}
