import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../domain/entities/listening.dart';
import '../../../providers/listening_provider.dart';

class ListeningPracticeScreen extends ConsumerStatefulWidget {
  const ListeningPracticeScreen({
    super.key,
    required this.levelId,
    required this.levelName,
    required this.exercise,
  });

  final String levelId;
  final String levelName;
  final ListeningExerciseSummary exercise;

  @override
  ConsumerState<ListeningPracticeScreen> createState() => _ListeningPracticeScreenState();
}

class _ListeningPracticeScreenState extends ConsumerState<ListeningPracticeScreen> {
  final _answerCtrl = TextEditingController();
  final _player = AudioPlayer();
  ListeningExerciseSummary? _exercise;
  ListeningCheckResult? _result;
  bool _loading = false;
  bool _audioLoading = false;
  bool _isPlaying = false;
  int _attempts = 0;

  @override
  void initState() {
    super.initState();
    _exercise = widget.exercise;
    _loadAudio();
    _player.playerStateStream.listen((state) {
      if (mounted) setState(() => _isPlaying = state.playing);
    });
  }

  @override
  void dispose() {
    _answerCtrl.dispose();
    _player.dispose();
    super.dispose();
  }

  Future<void> _loadAudio() async {
    if (_exercise == null) return;
    setState(() => _audioLoading = true);
    try {
      final url = await ref.read(listeningApiProvider).getSignedAudioUrl(_exercise!.id);
      await _player.setUrl(url);
    } finally {
      if (mounted) setState(() => _audioLoading = false);
    }
  }

  Future<void> _togglePlayback() async {
    if (_audioLoading) return;
    if (_isPlaying) {
      await _player.pause();
    } else {
      await _player.seek(Duration.zero);
      await _player.play();
    }
  }

  Future<void> _loadNext() async {
    setState(() {
      _loading = true;
      _result = null;
      _answerCtrl.clear();
    });
    try {
      final exercise = await ref.read(listeningApiProvider).getRandomExercise(widget.levelId);
      if (mounted) setState(() => _exercise = exercise);
      await _loadAudio();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _check() async {
    if (_exercise == null || _answerCtrl.text.trim().isEmpty) return;
    final result = await ref.read(listeningApiProvider).checkAnswer(
          listeningId: _exercise!.id,
          answer: _answerCtrl.text.trim(),
        );
    if (mounted) {
      setState(() {
        _result = result;
        _attempts += 1;
      });
    }
  }

  Color _tierColor(String tier) {
    switch (tier) {
      case 'passed':
        return AppColors.success;
      case 'partial':
        return Colors.orange;
      default:
        return AppColors.error;
    }
  }

  String _tierLabel(String tier) {
    switch (tier) {
      case 'passed':
        return 'Passed';
      case 'partial':
        return 'Partial';
      default:
        return 'Failed';
    }
  }

  @override
  Widget build(BuildContext context) {
    final exercise = _exercise;

    return Scaffold(
      appBar: AppBar(title: Text('${widget.levelName} · ${exercise?.title ?? ''}')),
      body: Padding(
        padding: AppSpacing.pagePaddingWide,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : exercise == null
                ? const Center(child: Text('No exercise available'))
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Attempts: $_attempts', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: AppSpacing.lg),
                      Card(
                        child: Padding(
                          padding: AppSpacing.cardPadding,
                          child: Column(
                            children: [
                              Text('Listen and type what you hear', style: Theme.of(context).textTheme.titleSmall),
                              const SizedBox(height: AppSpacing.md),
                              FilledButton.icon(
                                onPressed: _audioLoading ? null : _togglePlayback,
                                icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                                label: Text(_audioLoading ? 'Loading audio...' : _isPlaying ? 'Pause' : 'Play audio'),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      TextField(
                        controller: _answerCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Your transcript',
                          border: OutlineInputBorder(),
                          alignLabelWithHint: true,
                        ),
                        maxLines: 4,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _check(),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      FilledButton(onPressed: _check, child: const Text('Check')),
                      if (_result != null) ...[
                        const SizedBox(height: AppSpacing.md),
                        Card(
                          color: _tierColor(_result!.tier).withValues(alpha: 0.1),
                          child: Padding(
                            padding: AppSpacing.cardPadding,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${_result!.accuracyPercent}% — ${_tierLabel(_result!.tier)}',
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Text('${_result!.correctWords} / ${_result!.totalWords} words correct'),
                                if (_result!.missingWords.isNotEmpty) ...[
                                  const SizedBox(height: AppSpacing.xs),
                                  Text('Missing: ${_result!.missingWords.join(', ')}'),
                                ],
                                if (_result!.tryAgain) ...[
                                  const SizedBox(height: AppSpacing.xs),
                                  const Text('Try again to improve your score.'),
                                ],
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        OutlinedButton(onPressed: _loadNext, child: const Text('Next exercise')),
                      ],
                    ],
                  ),
      ),
    );
  }
}
