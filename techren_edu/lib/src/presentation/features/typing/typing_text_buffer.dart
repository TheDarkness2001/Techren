/// Continuous Monkeytype-style text buffer for Typing Speed Challenge.
/// Appends more words without resetting caret, timer, or metrics.
class TypingTextBuffer {
  TypingTextBuffer({
    required String initialText,
    List<String> wordPool = const [],
  })  : _text = _normalize(initialText),
        _pool = [
          ...wordPool.where((w) => w.trim().isNotEmpty),
          ..._normalize(initialText).split(RegExp(r'\s+')).where((w) => w.isNotEmpty),
        ];

  String _text;
  final List<String> _pool;
  int _appendCursor = 0;
  bool isFetching = false;

  String get text => _text;

  int get length => _text.length;

  static String _normalize(String raw) => raw
      .replaceAll('\r\n', '\n')
      .replaceAll('\r', '\n')
      .replaceAll('\t', '  ')
      .replaceAll(RegExp(r'[\n]+'), ' ')
      .replaceAll(RegExp(r'[ ]{2,}'), ' ')
      .trim();

  /// Remaining whole words after [caret].
  int remainingWordsAfter(int caret) {
    if (caret >= _text.length) return 0;
    final rest = _text.substring(caret.clamp(0, _text.length));
    return rest.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
  }

  bool needsAppend(int caret, {int threshold = 40}) =>
      remainingWordsAfter(caret) < threshold;

  static const _emergencyPool = [
    'function', 'variable', 'object', 'array', 'async', 'await', 'promise', 'component',
    'state', 'props', 'API', 'server', 'service', 'compile', 'deploy', 'Docker', 'Git',
    'repository', 'interface', 'class', 'method', 'module', 'package', 'framework', 'runtime',
  ];

  /// Append text from the local word pool (instant, no network).
  void appendFromPool({int wordCount = 80}) {
    final pool = _pool.isNotEmpty ? _pool : _emergencyPool;
    final batch = <String>[];
    for (var i = 0; i < wordCount; i++) {
      batch.add(pool[_appendCursor % pool.length]);
      _appendCursor++;
    }
    final chunk = batch.join(' ');
    if (_text.isEmpty) {
      _text = chunk;
    } else {
      _text = '$_text $chunk';
    }
  }

  /// Append a remote prompt batch without resetting progress.
  void appendRemoteText(String remoteText, {List<String> words = const []}) {
    for (final w in words) {
      final t = w.trim();
      if (t.isNotEmpty) _pool.add(t);
    }
    final chunk = _normalize(remoteText);
    if (chunk.isEmpty) {
      appendFromPool();
      return;
    }
    if (_text.isEmpty) {
      _text = chunk;
    } else {
      _text = '$_text $chunk';
    }
  }
}
