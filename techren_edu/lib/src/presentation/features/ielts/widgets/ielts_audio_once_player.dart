import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_semantic_colors.dart';
import '../../../providers/ielts_provider.dart';

/// IELTS Listening: play once; seeking back disabled after playback starts.
class IeltsAudioOncePlayer extends ConsumerStatefulWidget {
  const IeltsAudioOncePlayer({
    super.key,
    required this.sectionId,
    required this.alreadyPlayed,
    required this.onPlayed,
  });

  final String sectionId;
  final bool alreadyPlayed;
  final VoidCallback onPlayed;

  @override
  ConsumerState<IeltsAudioOncePlayer> createState() => _IeltsAudioOncePlayerState();
}

class _IeltsAudioOncePlayerState extends ConsumerState<IeltsAudioOncePlayer> {
  final _player = AudioPlayer();
  bool _loading = false;
  bool _started = false;
  bool _finished = false;
  String? _error;

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
      }
    });
    _player.positionStream.listen((pos) {
      if (!_started || !mounted) return;
      // Prevent seeking back: if user somehow seeks earlier, jump forward only.
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
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
        _started = true;
        widget.onPlayed();
      }
      await _player.play();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pause() async {
    await _player.pause();
  }

  @override
  Widget build(BuildContext context) {
    final muted = context.semantic.textMuted;
    final locked = widget.alreadyPlayed || _finished;

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
                child: Text(
                  locked
                      ? 'Audio finished (single play). You cannot replay.'
                      : 'Audio plays once. Do not leave this page while it is playing.',
                  style: TextStyle(color: muted),
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
          if (_started && !locked)
            StreamBuilder<Duration>(
              stream: _player.positionStream,
              builder: (context, snap) {
                final pos = snap.data ?? Duration.zero;
                final total = _player.duration ?? Duration.zero;
                final maxMs = total.inMilliseconds <= 0 ? 1.0 : total.inMilliseconds.toDouble();
                return Slider(
                  value: pos.inMilliseconds.clamp(0, maxMs.toInt()).toDouble(),
                  max: maxMs,
                  onChanged: (v) {
                    // Only allow seek forward (no rewind).
                    if (v >= pos.inMilliseconds) {
                      _player.seek(Duration(milliseconds: v.round()));
                    }
                  },
                );
              },
            ),
        ],
      ),
    );
  }
}
