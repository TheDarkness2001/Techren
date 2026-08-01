import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_semantic_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../providers/ielts_provider.dart';

/// IELTS Listening: one play per section, locked rewind, progress + volume.
class IeltsAudioOncePlayer extends ConsumerStatefulWidget {
  const IeltsAudioOncePlayer({
    super.key,
    required this.sectionId,
    required this.alreadyPlayed,
    required this.onPlayed,
    this.partLabel,
    this.onAnalytics,
  });

  final String sectionId;
  final bool alreadyPlayed;
  final VoidCallback onPlayed;
  final String? partLabel;

  /// Reports lightweight listening stats (playCount, listenedSeconds, completed)
  /// so they can be attached to attempt autosave.
  final ValueChanged<Map<String, dynamic>>? onAnalytics;

  @override
  ConsumerState<IeltsAudioOncePlayer> createState() => _IeltsAudioOncePlayerState();
}

class _IeltsAudioOncePlayerState extends ConsumerState<IeltsAudioOncePlayer> {
  final _player = AudioPlayer();
  bool _loading = false;
  bool _started = false;
  bool _finished = false;
  double _volume = 1;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  String? _error;
  int _playCount = 0;
  double _maxListenedSeconds = 0;
  DateTime? _lastAnalyticsReport;

  /// Deterministic pseudo-waveform bars — visual polish only (no real audio
  /// amplitude data is available client-side).
  late final List<double> _waveform = List.generate(48, (i) {
    final seed = widget.sectionId.hashCode + i * 2654435761;
    final unit = (seed & 0xFFFF) / 0xFFFF;
    return 0.25 + unit * 0.75;
  });

  @override
  void initState() {
    super.initState();
    _started = widget.alreadyPlayed;
    _finished = widget.alreadyPlayed;
    _player.playerStateStream.listen((state) {
      if (!mounted) return;
      if (state.processingState == ProcessingState.completed) {
        setState(() => _finished = true);
        _player.pause();
        _reportAnalytics(force: true);
      }
    });
    _player.positionStream.listen((pos) {
      if (!mounted) return;
      setState(() => _position = pos);
      final seconds = pos.inMilliseconds / 1000;
      if (seconds > _maxListenedSeconds) _maxListenedSeconds = seconds;
      _reportAnalytics();
    });
    _player.durationStream.listen((d) {
      if (!mounted || d == null) return;
      setState(() => _duration = d);
    });
  }

  void _reportAnalytics({bool force = false}) {
    final onAnalytics = widget.onAnalytics;
    if (onAnalytics == null) return;
    final now = DateTime.now();
    if (!force && _lastAnalyticsReport != null && now.difference(_lastAnalyticsReport!).inSeconds < 5) {
      return;
    }
    _lastAnalyticsReport = now;
    onAnalytics({
      'playCount': _playCount,
      'listenedSeconds': _maxListenedSeconds.round(),
      'completed': _finished,
    });
  }

  @override
  void didUpdateWidget(covariant IeltsAudioOncePlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sectionId != widget.sectionId) {
      _player.stop();
      _started = widget.alreadyPlayed;
      _finished = widget.alreadyPlayed;
      _position = Duration.zero;
      _duration = Duration.zero;
      _error = null;
    } else if (widget.alreadyPlayed && !_finished) {
      _started = true;
      _finished = true;
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<void> _play() async {
    if (_finished || widget.alreadyPlayed) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (!_started) {
        final url = await ref.read(ieltsApiProvider).getSignedAudioUrl(widget.sectionId);
        await _player.setUrl(url);
        await _player.setVolume(_volume);
        _started = true;
        widget.onPlayed();
      }
      _playCount += 1;
      _reportAnalytics(force: true);
      await _player.play();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pause() async => _player.pause();

  @override
  Widget build(BuildContext context) {
    final muted = context.semantic.textMuted;
    final locked = widget.alreadyPlayed || _finished;
    final maxMs = _duration.inMilliseconds <= 0 ? 1.0 : _duration.inMilliseconds.toDouble();
    final progress = (_position.inMilliseconds.clamp(0, maxMs.toInt()) / maxMs).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: AppRadius.card,
        border: Border.all(color: context.semantic.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.headphones, color: AppColors.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.partLabel != null)
                      Text(widget.partLabel!, style: const TextStyle(fontWeight: FontWeight.w700)),
                    Text(
                      locked
                          ? 'Audio finished for this part (single play).'
                          : 'Plays once for this part. Seeking backward is locked.',
                      style: TextStyle(color: muted, fontSize: 13),
                    ),
                  ],
                ),
              ),
              if (_loading)
                const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
              else if (locked)
                const Icon(Icons.lock_outline)
              else
                FilledButton.tonal(
                  onPressed: () async {
                    if (_player.playing) {
                      await _pause();
                    } else {
                      await _play();
                    }
                    setState(() {});
                  },
                  child: Text(_player.playing ? 'Pause' : (_started ? 'Resume' : 'Play once')),
                ),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12)),
          ],
          if (_started) ...[
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              height: 40,
              width: double.infinity,
              child: CustomPaint(
                painter: _WaveformPainter(
                  bars: _waveform,
                  progress: locked && _finished ? 1 : progress,
                  activeColor: AppColors.primary,
                  inactiveColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(_fmt(_position), style: TextStyle(color: muted, fontSize: 12)),
                const Spacer(),
                Text(_fmt(_duration), style: TextStyle(color: muted, fontSize: 12)),
              ],
            ),
            if (!locked)
              Slider(
                value: _position.inMilliseconds.clamp(0, maxMs.toInt()).toDouble(),
                max: maxMs,
                onChanged: (v) {
                  if (v >= _position.inMilliseconds) {
                    _player.seek(Duration(milliseconds: v.round()));
                  }
                },
              ),
            Row(
              children: [
                Icon(Icons.volume_up, size: 18, color: muted),
                Expanded(
                  child: Slider(
                    value: _volume,
                    onChanged: locked
                        ? null
                        : (v) async {
                            setState(() => _volume = v);
                            await _player.setVolume(v);
                          },
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Bars-style waveform visualization; purely decorative since we don't have
/// real amplitude data, but colors bars up to [progress] to show playback.
class _WaveformPainter extends CustomPainter {
  const _WaveformPainter({
    required this.bars,
    required this.progress,
    required this.activeColor,
    required this.inactiveColor,
  });

  final List<double> bars;
  final double progress;
  final Color activeColor;
  final Color inactiveColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (bars.isEmpty) return;
    final gap = 3.0;
    final barWidth = (size.width - gap * (bars.length - 1)) / bars.length;
    final activeCount = (bars.length * progress).round();
    for (var i = 0; i < bars.length; i++) {
      final h = size.height * bars[i];
      final rect = Rect.fromLTWH(i * (barWidth + gap), (size.height - h) / 2, barWidth, h);
      final paint = Paint()
        ..color = i < activeCount ? activeColor : inactiveColor
        ..style = PaintingStyle.fill;
      canvas.drawRRect(RRect.fromRectAndRadius(rect, Radius.circular(barWidth / 2)), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.bars != bars || oldDelegate.activeColor != activeColor;
}
