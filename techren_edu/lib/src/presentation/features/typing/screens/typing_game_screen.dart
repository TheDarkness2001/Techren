import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_semantic_colors.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../domain/entities/typing.dart';
import '../../../providers/typing_provider.dart';
import '../typing_text_buffer.dart';
import '../widgets/typing_widgets.dart';

class TypingGameScreen extends ConsumerStatefulWidget {
  const TypingGameScreen({
    super.key,
    required this.subjectId,
    this.mode = 'programming',
    this.difficulty = 'medium',
    this.durationSec = 60,
    this.isDaily = false,
    this.onOpenLeaderboard,
  });

  final String subjectId;
  final String mode;
  final String difficulty;
  final int durationSec;
  final bool isDaily;
  final VoidCallback? onOpenLeaderboard;

  @override
  ConsumerState<TypingGameScreen> createState() => _TypingGameScreenState();
}

class _TypingGameScreenState extends ConsumerState<TypingGameScreen>
    with SingleTickerProviderStateMixin {
  TypingStartPayload? _payload;
  TypingTextBuffer? _buffer;
  String? _error;
  bool _loading = true;
  bool _finished = false;
  bool _submitting = false;

  final _focus = FocusNode();
  final _inputCtrl = TextEditingController();

  int _caret = 0;
  int _correctChars = 0;
  int _incorrectChars = 0;
  int _mistakes = 0;
  int _elapsedSec = 0;
  Timer? _ticker;
  DateTime? _startedAt;
  late final AnimationController _caretBlink;

  String get _target => _buffer?.text ?? '';

  @override
  void initState() {
    super.initState();
    _caretBlink = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 530),
    )..repeat(reverse: true);
    _bootstrap();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _caretBlink.dispose();
    _focus.dispose();
    _inputCtrl.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    setState(() {
      _loading = true;
      _error = null;
      _finished = false;
      _submitting = false;
      _caret = 0;
      _correctChars = 0;
      _incorrectChars = 0;
      _mistakes = 0;
      _elapsedSec = 0;
      _startedAt = null;
      _ticker?.cancel();
      _ticker = null;
      _inputCtrl.clear();
    });
    try {
      final payload = await ref.read(typingApiProvider).start(
            subjectId: widget.subjectId,
            mode: widget.mode,
            difficulty: widget.difficulty,
            durationSec: widget.durationSec,
            unlimited: widget.durationSec == 0,
            isDaily: widget.isDaily,
          );
      if (!mounted) return;
      final buffer = TypingTextBuffer(
        initialText: payload.prompt.text,
        wordPool: payload.prompt.words,
      );
      // Ensure a healthy starting buffer even if API returns a short prompt.
      if (buffer.remainingWordsAfter(0) < 80) {
        buffer.appendFromPool(wordCount: 120);
      }
      setState(() {
        _payload = payload;
        _buffer = buffer;
        _loading = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _focus.requestFocus();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  void _ensureTicker() {
    if (_ticker != null || _finished) return;
    _startedAt = DateTime.now();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _finished) return;
      setState(() => _elapsedSec = DateTime.now().difference(_startedAt!).inSeconds);
      final session = _payload?.session;
      if (session != null && !session.unlimited && session.durationSec > 0) {
        if (_elapsedSec >= session.durationSec) {
          _complete();
        }
      }
    });
  }

  Future<void> _ensureBufferHasText() async {
    final buffer = _buffer;
    final payload = _payload;
    if (buffer == null || payload == null || _finished) return;
    if (!buffer.needsAppend(_caret, threshold: 40)) return;
    if (buffer.isFetching) {
      buffer.appendFromPool(wordCount: 60);
      return;
    }

    // Instant local append so typing never stalls.
    buffer.appendFromPool(wordCount: 80);
    if (mounted) setState(() {});

    buffer.isFetching = true;
    try {
      final more = await ref.read(typingApiProvider).moreText(
            subjectId: widget.subjectId,
            mode: payload.session.mode,
            difficulty: payload.session.difficulty,
            durationSec: payload.session.durationSec,
            isDaily: payload.session.isDaily,
          );
      if (!mounted || _finished) return;
      buffer.appendRemoteText(more.text, words: more.words);
      if (mounted) setState(() {});
    } catch (_) {
      // Local pool already extended — keep going.
    } finally {
      buffer.isFetching = false;
    }
  }

  void _onText(String value) {
    if (_finished || _target.isEmpty) return;
    _ensureTicker();

    // Never block typing at end of buffer — grow first.
    if (value.length >= _target.length - 20) {
      unawaited(_ensureBufferHasText());
    }

    final target = _target;
    var correct = 0;
    var incorrect = 0;
    final len = value.length.clamp(0, target.length);
    for (var i = 0; i < len; i++) {
      if (value[i] == target[i]) {
        correct++;
      } else {
        incorrect++;
      }
    }
    final mistakesDelta = incorrect > _incorrectChars ? incorrect - _incorrectChars : 0;
    final clipped = value.length > target.length ? value.substring(0, target.length) : value;

    setState(() {
      _inputCtrl.value = TextEditingValue(
        text: clipped,
        selection: TextSelection.collapsed(offset: clipped.length),
      );
      _caret = clipped.length;
      _correctChars = correct;
      _incorrectChars = incorrect;
      _mistakes += mistakesDelta;
    });

    if (_buffer?.needsAppend(_caret) == true) {
      unawaited(_ensureBufferHasText());
    }

    // Unlimited: do not auto-finish when buffer ends — keep appending.
    // Timed tests finish only via timer (or Esc / finish).
  }

  double get _elapsedMinutes {
    if (_startedAt == null) return 1 / 60;
    final ms = DateTime.now().difference(_startedAt!).inMilliseconds;
    final sec = ms <= 0 ? 1 / 60 : ms / 1000.0;
    return sec / 60.0;
  }

  double get _wpm => (_correctChars / 5.0) / _elapsedMinutes;

  double get _rawWpm => ((_correctChars + _incorrectChars) / 5.0) / _elapsedMinutes;

  double get _accuracy {
    final total = _correctChars + _incorrectChars;
    if (total == 0) return 100;
    return (_correctChars / total) * 100;
  }

  int get _timeLeft {
    final session = _payload?.session;
    if (session == null || session.unlimited || session.durationSec <= 0) return -1;
    return (session.durationSec - _elapsedSec).clamp(0, session.durationSec);
  }

  String get _modeLabel {
    switch (widget.mode) {
      case 'english':
        return 'english';
      case 'uzbek':
        return 'uzbek';
      case 'code':
        return 'code';
      case 'programming':
      default:
        return 'programming';
    }
  }

  IconData get _modeIcon {
    switch (widget.mode) {
      case 'english':
      case 'uzbek':
        return Icons.public;
      case 'code':
        return Icons.code;
      default:
        return Icons.terminal;
    }
  }

  ({int wordsTyped, int correctWords, int wrongWords}) _wordStats() {
    final typed = _inputCtrl.text;
    final targetWords = _target.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    final typedWords = typed.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    var correct = 0;
    var wrong = 0;
    final n = typedWords.length.clamp(0, targetWords.length);
    for (var i = 0; i < n; i++) {
      if (typedWords[i] == targetWords[i]) {
        correct++;
      } else {
        wrong++;
      }
    }
    return (wordsTyped: typedWords.length, correctWords: correct, wrongWords: wrong);
  }

  Future<void> _complete() async {
    if (_finished || _submitting || _payload == null) return;
    _ticker?.cancel();
    setState(() {
      _finished = true;
      _submitting = true;
    });

    final words = _wordStats();
    final session = _payload!.session;
    try {
      final result = await ref.read(typingApiProvider).finish(
            subjectId: widget.subjectId,
            mode: session.mode,
            difficulty: session.difficulty,
            durationSec: session.durationSec,
            unlimited: session.unlimited,
            isDaily: session.isDaily,
            wpm: double.parse(_wpm.toStringAsFixed(1)),
            rawWpm: double.parse(_rawWpm.toStringAsFixed(1)),
            accuracy: double.parse(_accuracy.toStringAsFixed(1)),
            correctChars: _correctChars,
            incorrectChars: _incorrectChars,
            totalChars: _correctChars + _incorrectChars,
            mistakes: _mistakes,
            wordsTyped: words.wordsTyped,
            correctWords: words.correctWords,
            wrongWords: words.wrongWords,
            elapsedSec: _elapsedSec,
            contentId: _payload!.prompt.contentId,
          );
      if (!mounted) return;
      setState(() => _submitting = false);
      await showTypingResultSheet(
        context: context,
        result: result,
        correctChars: _correctChars,
        incorrectChars: _incorrectChars,
        durationSec: _elapsedSec,
        onRetry: () {
          Navigator.of(context).pop();
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => TypingGameScreen(
                subjectId: widget.subjectId,
                mode: widget.mode,
                difficulty: widget.difficulty,
                durationSec: widget.durationSec,
                isDaily: widget.isDaily,
                onOpenLeaderboard: widget.onOpenLeaderboard,
              ),
            ),
          );
        },
        onLeaderboard: () {
          Navigator.of(context).pop();
          Navigator.of(context).pop();
          widget.onOpenLeaderboard?.call();
        },
        onContinue: () {
          Navigator.of(context).pop();
          Navigator.of(context).pop();
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _finished = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final semantic = context.semantic;
    final started = _startedAt != null || _caret > 0;
    final bg = Color.lerp(const Color(0xFF0B0E14), scheme.surface, 0.35)!;
    final compact = MediaQuery.sizeOf(context).width < 600;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          widget.isDaily ? 'daily' : 'practice',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                letterSpacing: 0.4,
                color: semantic.textMuted,
              ),
        ),
        centerTitle: true,
        actions: [
          if (!_finished && _payload != null)
            TextButton(
              onPressed: _complete,
              child: Text(
                'finish',
                style: TextStyle(color: semantic.textMuted, fontWeight: FontWeight.w600),
              ),
            ),
        ],
      ),
      body: _loading
          ? const LoadingState(kind: LoadingSkeletonKind.list)
          : _error != null
              ? EmptyState(
                  title: 'Could not start',
                  message: _error!,
                  icon: Icons.error_outline,
                  action: FilledButton(onPressed: _bootstrap, child: const Text('Retry')),
                )
              : Focus(
                  autofocus: false,
                  onKeyEvent: (node, event) {
                    if (event is KeyDownEvent &&
                        event.logicalKey == LogicalKeyboardKey.escape &&
                        !_finished &&
                        _payload != null) {
                      _complete();
                      return KeyEventResult.handled;
                    }
                    return KeyEventResult.ignored;
                  },
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _focus.requestFocus(),
                    child: Stack(
                      children: [
                        Center(
                          child: FractionallySizedBox(
                            widthFactor: compact ? 0.96 : 0.78,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: 960,
                                minWidth: compact ? 0 : 280,
                              ),
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 16),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Wrap(
                                      alignment: WrapAlignment.center,
                                      crossAxisAlignment: WrapCrossAlignment.center,
                                      spacing: 6,
                                      children: [
                                        Icon(_modeIcon, size: 14, color: scheme.primary),
                                        Text(
                                          _modeLabel,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            letterSpacing: 0.3,
                                            color: scheme.primary,
                                          ),
                                        ),
                                        Text('·', style: TextStyle(color: semantic.textMuted)),
                                        Text(
                                          widget.durationSec > 0 ? '${widget.durationSec}s' : '∞',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: semantic.textMuted,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 22),
                                    AnimatedOpacity(
                                      opacity: started ? 1 : 0.35,
                                      duration: const Duration(milliseconds: 200),
                                      child: Padding(
                                        padding: const EdgeInsets.only(bottom: 20),
                                        child: Wrap(
                                          alignment: WrapAlignment.center,
                                          spacing: compact ? 16 : 32,
                                          runSpacing: 8,
                                          children: [
                                            _MonoStat(
                                              value: (_wpm.isFinite ? _wpm : 0).toStringAsFixed(0),
                                              label: 'wpm',
                                              color: scheme.primary,
                                              compact: compact,
                                            ),
                                            _MonoStat(
                                              value: _accuracy.toStringAsFixed(0),
                                              label: 'acc',
                                              color: scheme.primary,
                                              compact: compact,
                                            ),
                                            _MonoStat(
                                              value: _timeLeft < 0 ? '∞' : '$_timeLeft',
                                              label: 'time',
                                              color: scheme.primary,
                                              large: true,
                                              compact: compact,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    MonkeytypePrompt(
                                      target: _target,
                                      typed: _inputCtrl.text,
                                      caret: _caret,
                                      caretBlink: _caretBlink,
                                      fontSize: compact ? 22 : 32,
                                    ),
                                    const SizedBox(height: 32),
                                    Text(
                                      started ? 'esc — finish early' : 'start typing',
                                      style: TextStyle(
                                        fontSize: 12,
                                        letterSpacing: 0.6,
                                        color: semantic.textMuted.withValues(alpha: 0.7),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        Offstage(
                          offstage: true,
                          child: TextField(
                            focusNode: _focus,
                            controller: _inputCtrl,
                            onChanged: _finished ? null : _onText,
                            enabled: !_finished,
                            autofocus: true,
                            enableSuggestions: false,
                            autocorrect: false,
                            keyboardType: TextInputType.multiline,
                            textInputAction: TextInputAction.newline,
                            maxLines: null,
                            inputFormatters: [
                              FilteringTextInputFormatter.deny(RegExp(r'[\u200B-\u200D\uFEFF]')),
                              TextInputFormatter.withFunction((oldValue, newValue) {
                                final text = newValue.text
                                    .replaceAll('\r\n', ' ')
                                    .replaceAll('\n', ' ')
                                    .replaceAll('\r', ' ');
                                if (text == newValue.text) return newValue;
                                final delta = newValue.text.length - text.length;
                                final offset =
                                    (newValue.selection.baseOffset - delta).clamp(0, text.length);
                                return TextEditingValue(
                                  text: text,
                                  selection: TextSelection.collapsed(offset: offset),
                                );
                              }),
                            ],
                          ),
                        ),
                        if (_submitting)
                          const Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            child: LinearProgressIndicator(minHeight: 2),
                          ),
                      ],
                    ),
                  ),
                ),
    );
  }
}

class _MonoStat extends StatelessWidget {
  const _MonoStat({
    required this.value,
    required this.label,
    required this.color,
    this.large = false,
    this.compact = false,
  });

  final String value;
  final String label;
  final Color color;
  final bool large;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final valueSize = compact ? (large ? 28.0 : 22.0) : (large ? 34.0 : 28.0);
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '$value ',
            style: TextStyle(
              fontFamily: 'Consolas',
              fontFamilyFallback: const ['Courier New', 'monospace'],
              fontSize: valueSize,
              fontWeight: FontWeight.w700,
              color: color,
              height: 1,
            ),
          ),
          TextSpan(
            text: label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: context.semantic.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

/// Monkeytype-inspired prompt: soft-wrap, auto-scroll, per-character colors, blinking caret.
class MonkeytypePrompt extends StatelessWidget {
  const MonkeytypePrompt({
    super.key,
    required this.target,
    required this.typed,
    required this.caret,
    required this.caretBlink,
    this.fontSize = 32,
  });

  final String target;
  final String typed;
  final int caret;
  final Animation<double> caretBlink;
  final double fontSize;

  static const _lineHeight = 1.55;

  double get _rowHeight => fontSize * _lineHeight;

  TextStyle get _baseStyle => TextStyle(
        fontFamily: 'Consolas',
        fontFamilyFallback: const ['Courier New', 'Menlo', 'monospace'],
        fontSize: fontSize,
        height: _lineHeight,
        letterSpacing: 0.35,
        fontWeight: FontWeight.w400,
      );

  int _visibleLinesForWidth(double width) {
    if (width < 420) return 3;
    if (width < 720) return 4;
    return 5;
  }

  /// Window around the caret so we do not paint thousands of TextSpans.
  ({String text, String typedSlice, int localCaret, int globalStart}) _window() {
    final c = caret.clamp(0, target.length);
    var start = (c - 180).clamp(0, target.length);
    while (start > 0 && target[start - 1] != ' ') {
      start--;
    }
    var end = (c + 520).clamp(0, target.length);
    while (end < target.length && target[end] != ' ') {
      end++;
    }
    final slice = target.substring(start, end);
    final typedSlice = typed.length > start
        ? typed.substring(start, typed.length.clamp(start, end))
        : '';
    return (
      text: slice,
      typedSlice: typedSlice,
      localCaret: c - start,
      globalStart: start,
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final semantic = context.semantic;

    final upcoming = scheme.onSurface.withValues(alpha: 0.30);
    final current = scheme.onSurface.withValues(alpha: 0.72);
    final typedOk = scheme.onSurface.withValues(alpha: 0.95);
    final wrong = semantic.danger;
    final caretColor = scheme.primary;

    final window = _window();
    final display = window.text;
    final localCaret = window.localCaret;
    final typedSlice = window.typedSlice;

    final spans = <InlineSpan>[];
    for (var i = 0; i < display.length; i++) {
      final ch = display[i];
      Color color;
      TextDecoration decoration = TextDecoration.none;
      if (i < localCaret) {
        final ok = typedSlice.length > i && typedSlice[i] == ch;
        color = ok ? typedOk : wrong;
        if (!ok) decoration = TextDecoration.underline;
      } else if (i == localCaret) {
        color = current;
      } else {
        color = upcoming;
      }

      spans.add(
        TextSpan(
          text: ch,
          style: TextStyle(
            color: color,
            decoration: decoration,
            decorationColor: wrong,
            decorationThickness: 2,
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth.isFinite ? constraints.maxWidth : 880.0;
        final visibleLines = _visibleLinesForWidth(maxWidth);
        final rich = TextSpan(style: _baseStyle.copyWith(color: upcoming), children: spans);

        final fullPainter = TextPainter(
          text: rich,
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: maxWidth);

        final caretOffset = _caretPixelOffset(
          text: display,
          localCaret: localCaret,
          maxWidth: maxWidth,
        );
        final caretLineTop = (caretOffset.dy / _rowHeight).floor() * _rowHeight;
        // Keep previous line visible (Monkeytype-style advance).
        final preferred = caretLineTop - _rowHeight;
        final maxScroll =
            (fullPainter.height - _rowHeight * visibleLines).clamp(0.0, double.infinity);
        final scrollY = preferred.clamp(0.0, maxScroll);
        final viewportHeight = _rowHeight * visibleLines;

        return SizedBox(
          height: viewportHeight,
          width: maxWidth,
          child: ClipRect(
            child: Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                Transform.translate(
                  offset: Offset(0, -scrollY),
                  child: SizedBox(
                    width: maxWidth,
                    child: Text.rich(
                      rich,
                      textAlign: TextAlign.left,
                      softWrap: true,
                    ),
                  ),
                ),
                FadeTransition(
                  opacity: caretBlink,
                  child: Transform.translate(
                    offset: Offset(caretOffset.dx, caretOffset.dy - scrollY + 2),
                    child: Container(
                      width: 2.5,
                      height: fontSize * 1.05,
                      decoration: BoxDecoration(
                        color: caretColor,
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Offset _caretPixelOffset({
    required String text,
    required int localCaret,
    required double maxWidth,
  }) {
    final before = text.substring(0, localCaret.clamp(0, text.length));
    if (before.isEmpty) return Offset.zero;

    final measure = TextPainter(
      text: TextSpan(text: before, style: _baseStyle),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: maxWidth);

    return measure.getOffsetForCaret(
      TextPosition(offset: before.length),
      Rect.fromLTWH(0, 0, measure.width, _rowHeight),
    );
  }
}
