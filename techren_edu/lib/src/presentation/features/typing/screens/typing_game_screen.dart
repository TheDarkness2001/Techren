import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_semantic_colors.dart';
import '../../../../core/theme/app_spacing.dart';
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

class _TypingGameScreenState extends ConsumerState<TypingGameScreen> {
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

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _ticker?.cancel();
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
        _target = payload.prompt.text;
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

    // Rebuild from full typed string vs target (handles paste / backspace).
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

    if (_caret >= _target.length && (_payload?.session.unlimited == true || (_payload?.session.durationSec ?? 0) == 0)) {
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

  double get _progress {
    final session = _payload?.session;
    if (session == null) return 0;
    if (session.unlimited || session.durationSec <= 0) {
      return _target.isEmpty ? 0 : (_caret / _target.length).clamp(0.0, 1.0);
    }
    return (_elapsedSec / session.durationSec).clamp(0.0, 1.0);
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
          Navigator.of(context).pop(); // close result sheet
          Navigator.of(context).pop(); // leave game screen
          widget.onOpenLeaderboard?.call();
        },
        onContinue: () {
          Navigator.of(context).pop(); // close result sheet
          Navigator.of(context).pop(); // leave game screen
        },
      );
      // Sheet handlers already dismiss the game when needed — don't pop the hub.
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
    final semantic = context.semantic;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isDaily ? 'Daily challenge' : 'Typing practice'),
        actions: [
          if (!_finished && _payload != null)
            TextButton(
              onPressed: _complete,
              child: const Text('Finish'),
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
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth >= 720;
                    final fontSize = wide ? 36.0 : 28.0;
                    final maxPromptWidth = wide ? 920.0 : constraints.maxWidth;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.md,
                            AppSpacing.sm,
                            AppSpacing.md,
                            0,
                          ),
                          child: TypingLiveStatsBar(
                            wpm: _wpm.isFinite ? _wpm : 0,
                            accuracy: _accuracy,
                            correctChars: _correctChars,
                            incorrectChars: _incorrectChars,
                            mistakes: _mistakes,
                            timeLeftLabel: _timeLeft < 0 ? '∞' : '${_timeLeft}s',
                            progress: _progress,
                            compact: true,
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => _focus.requestFocus(),
                            child: Center(
                              child: ConstrainedBox(
                                constraints: BoxConstraints(maxWidth: maxPromptWidth),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.lg,
                                    vertical: AppSpacing.md,
                                  ),
                                  child: SingleChildScrollView(
                                    child: _TypingPrompt(
                                      target: _target,
                                      typed: _inputCtrl.text,
                                      caret: _caret,
                                      fontSize: fontSize,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.md),
                          child: Text(
                            _elapsedSec == 0 && _caret == 0
                                ? 'Tap here and start typing'
                                : 'Keep typing — finish when ready',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: semantic.textMuted,
                                ),
                          ),
                        ),
                        Offstage(
                          offstage: true,
                          child: TextField(
                            focusNode: _focus,
                            controller: _inputCtrl,
                            onChanged: _onText,
                            autofocus: true,
                            enableSuggestions: false,
                            autocorrect: false,
                            keyboardType: TextInputType.visiblePassword,
                            inputFormatters: [
                              FilteringTextInputFormatter.deny(RegExp(r'[\u200B-\u200D\uFEFF]')),
                            ],
                          ),
                        ),
                        if (_submitting) const LinearProgressIndicator(),
                      ],
                    );
                  },
                ),
    );
  }
}

/// Monkeytype-style large monospaced prompt with a clear caret.
class _TypingPrompt extends StatelessWidget {
  const _TypingPrompt({
    required this.target,
    required this.typed,
    required this.caret,
    required this.fontSize,
  });

  final String target;
  final String typed;
  final int caret;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final semantic = context.semantic;
    final upcoming = scheme.onSurface.withValues(alpha: 0.38);
    final typedOk = scheme.onSurface;
    final baseStyle = TextStyle(
      fontFamily: 'Consolas',
      fontFamilyFallback: const ['Courier New', 'monospace'],
      fontSize: fontSize,
      height: 1.6,
      letterSpacing: 0.6,
      fontWeight: FontWeight.w500,
    );

    return Text.rich(
      TextSpan(
        style: baseStyle,
        children: [
          for (var i = 0; i < target.length; i++)
            TextSpan(
              text: target[i] == ' ' && i == caret ? '·' : target[i],
              style: TextStyle(
                color: i > caret
                    ? upcoming
                    : i == caret
                        ? scheme.primary
                        : (typed.length > i && typed[i] == target[i] ? typedOk : semantic.danger),
                backgroundColor: i == caret ? scheme.primary.withValues(alpha: 0.18) : null,
                decoration: i < caret && typed.length > i && typed[i] != target[i]
                    ? TextDecoration.underline
                    : TextDecoration.none,
                decorationColor: semantic.danger,
                decorationThickness: 2.5,
              ),
            ),
        ],
      ),
      textAlign: TextAlign.start,
    );
  }
}
