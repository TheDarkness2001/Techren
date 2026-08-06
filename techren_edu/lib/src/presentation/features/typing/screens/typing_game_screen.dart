import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_semantic_colors.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../domain/entities/typing.dart';
import '../../../providers/typing_provider.dart';
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
  String? _error;
  bool _loading = true;
  bool _finished = false;
  bool _submitting = false;

  final _focus = FocusNode();
  final _inputCtrl = TextEditingController();

  String _target = '';
  int _caret = 0;
  int _correctChars = 0;
  int _incorrectChars = 0;
  int _mistakes = 0;
  int _elapsedSec = 0;
  Timer? _ticker;
  DateTime? _startedAt;
  late final AnimationController _caretBlink;

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
      setState(() {
        _payload = payload;
        // Soft-wrap only — hard newlines block caret advance in the capture field.
        _target = payload.prompt.text.replaceAll(RegExp(r'[\r\n]+'), ' ');
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

  void _onText(String value) {
    if (_finished || _target.isEmpty) return;
    _ensureTicker();

    var correct = 0;
    var incorrect = 0;
    final len = value.length.clamp(0, _target.length);
    for (var i = 0; i < len; i++) {
      if (value[i] == _target[i]) {
        correct++;
      } else {
        incorrect++;
      }
    }
    final mistakesDelta = incorrect > _incorrectChars ? incorrect - _incorrectChars : 0;

    setState(() {
      _inputCtrl.value = TextEditingValue(
        text: value.length > _target.length ? value.substring(0, _target.length) : value,
        selection: TextSelection.collapsed(
          offset: (value.length > _target.length ? _target.length : value.length),
        ),
      );
      _caret = _inputCtrl.text.length;
      _correctChars = correct;
      _incorrectChars = incorrect;
      _mistakes += mistakesDelta;
    });

    if (_caret >= _target.length &&
        (_payload?.session.unlimited == true || (_payload?.session.durationSec ?? 0) == 0)) {
      _complete();
    }
  }

  double get _elapsedMinutes {
    final sec = _elapsedSec <= 0 ? 1 / 60 : _elapsedSec / 60.0;
    return sec;
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
    final started = _elapsedSec > 0 || _caret > 0;

    return Scaffold(
      backgroundColor: scheme.surface,
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
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 920),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 28),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Monkeytype-style mode chip
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(_modeIcon, size: 14, color: scheme.primary),
                                    const SizedBox(width: 6),
                                    Text(
                                      _modeLabel,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        letterSpacing: 0.3,
                                        color: scheme.primary,
                                      ),
                                    ),
                                    if (widget.durationSec > 0) ...[
                                      Text(
                                        '  ·  ',
                                        style: TextStyle(color: semantic.textMuted),
                                      ),
                                      Text(
                                        '${widget.durationSec}s',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: semantic.textMuted,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 28),

                                // Live stats — only after typing starts (Monkeytype style)
                                AnimatedOpacity(
                                  opacity: started ? 1 : 0,
                                  duration: const Duration(milliseconds: 220),
                                  child: Padding(
                                    padding: const EdgeInsets.only(bottom: 22),
                                    child: Wrap(
                                      alignment: WrapAlignment.center,
                                      spacing: 28,
                                      runSpacing: 8,
                                      children: [
                                        _MonoStat(
                                          value: (_wpm.isFinite ? _wpm : 0).toStringAsFixed(0),
                                          label: 'wpm',
                                          color: scheme.primary,
                                        ),
                                        _MonoStat(
                                          value: _accuracy.toStringAsFixed(0),
                                          label: 'acc',
                                          color: scheme.primary,
                                        ),
                                        _MonoStat(
                                          value: _timeLeft < 0 ? '∞' : '$_timeLeft',
                                          label: 'time',
                                          color: scheme.primary,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                // Prompt — 3 visible rows, auto-follows caret
                                _MonkeytypePrompt(
                                  target: _target,
                                  typed: _inputCtrl.text,
                                  caret: _caret,
                                  caretBlink: _caretBlink,
                                ),

                                const SizedBox(height: 36),
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
                      // Hidden capture field
                      Offstage(
                        offstage: true,
                        child: TextField(
                          focusNode: _focus,
                          controller: _inputCtrl,
                          onChanged: _onText,
                          autofocus: true,
                          enableSuggestions: false,
                          autocorrect: false,
                          keyboardType: TextInputType.multiline,
                          textInputAction: TextInputAction.newline,
                          maxLines: null,
                          inputFormatters: [
                            FilteringTextInputFormatter.deny(RegExp(r'[\u200B-\u200D\uFEFF]')),
                            // Map Enter → space so soft-wrapped lines keep flowing
                            TextInputFormatter.withFunction((oldValue, newValue) {
                              final text = newValue.text.replaceAll('\r\n', ' ').replaceAll('\n', ' ').replaceAll('\r', ' ');
                              if (text == newValue.text) return newValue;
                              final delta = newValue.text.length - text.length;
                              final offset = (newValue.selection.baseOffset - delta).clamp(0, text.length);
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
  const _MonoStat({required this.value, required this.label, required this.color});

  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '$value ',
            style: TextStyle(
              fontFamily: 'Consolas',
              fontFamilyFallback: const ['Courier New', 'monospace'],
              fontSize: 28,
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

/// Monkeytype-inspired prompt: 3 rows, larger type, soft-wraps freely, caret follows.
class _MonkeytypePrompt extends StatelessWidget {
  const _MonkeytypePrompt({
    required this.target,
    required this.typed,
    required this.caret,
    required this.caretBlink,
  });

  final String target;
  final String typed;
  final int caret;
  final Animation<double> caretBlink;

  static const _fontSize = 34.0;
  static const _lineHeight = 1.55;
  static const _visibleLines = 3;

  double get _rowHeight => _fontSize * _lineHeight;

  TextStyle get _baseStyle => const TextStyle(
        fontFamily: 'Consolas',
        fontFamilyFallback: ['Courier New', 'Menlo', 'monospace'],
        fontSize: _fontSize,
        height: _lineHeight,
        letterSpacing: 0.35,
        fontWeight: FontWeight.w400,
      );

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final semantic = context.semantic;

    final upcoming = scheme.onSurface.withValues(alpha: 0.32);
    final typedOk = scheme.onSurface.withValues(alpha: 0.92);
    final wrong = semantic.danger;
    final caretColor = scheme.primary;

    final spans = <InlineSpan>[];
    for (var i = 0; i < target.length; i++) {
      final ch = target[i];
      Color color;
      TextDecoration decoration = TextDecoration.none;
      if (i < caret) {
        final ok = typed.length > i && typed[i] == ch;
        color = ok ? typedOk : wrong;
        if (!ok) decoration = TextDecoration.underline;
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
        final rich = TextSpan(style: _baseStyle.copyWith(color: upcoming), children: spans);

        final fullPainter = TextPainter(
          text: rich,
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: maxWidth);

        final caretOffset = _caretPixelOffset(maxWidth: maxWidth);
        final caretLineTop = (caretOffset.dy / _rowHeight).floor() * _rowHeight;
        final maxScroll = (fullPainter.height - _rowHeight * _visibleLines).clamp(0.0, double.infinity);
        final scrollY = caretLineTop.clamp(0.0, maxScroll);
        final viewportHeight = _rowHeight * _visibleLines;

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
                      width: 3,
                      height: _fontSize * 1.05,
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

  Offset _caretPixelOffset({required double maxWidth}) {
    final before = target.substring(0, caret.clamp(0, target.length));
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
