import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../../../../core/utils/media_url.dart';

class VoiceNotePlayer extends StatefulWidget {
  const VoiceNotePlayer({
    super.key,
    required this.url,
    this.durationSec = 0,
  });

  final String url;
  final int durationSec;

  @override
  State<VoiceNotePlayer> createState() => _VoiceNotePlayerState();
}

class _VoiceNotePlayerState extends State<VoiceNotePlayer> {
  final _player = AudioPlayer();
  bool _ready = false;
  bool _playing = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      await _player.setUrl(resolveMediaUrl(widget.url));
      if (mounted) setState(() => _ready = true);
      _player.playerStateStream.listen((s) {
        if (!mounted) return;
        setState(() => _playing = s.playing);
      });
    } catch (_) {
      if (mounted) setState(() => _ready = false);
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  String _fmt(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final fallback = Duration(seconds: widget.durationSec);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          visualDensity: VisualDensity.compact,
          onPressed: !_ready
              ? null
              : () async {
                  if (_playing) {
                    await _player.pause();
                  } else {
                    await _player.play();
                  }
                },
          icon: Icon(_playing ? Icons.pause_circle_filled : Icons.play_circle_filled),
        ),
        Text(
          _fmt(_player.duration ?? fallback),
          style: Theme.of(context).textTheme.labelMedium,
        ),
        const SizedBox(width: 4),
        const Icon(Icons.mic, size: 16),
      ],
    );
  }
}
