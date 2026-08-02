import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_semantic_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../domain/entities/ielts.dart';

/// One-shot speaking recorder for IELTS cue-card MVP.
class IeltsSpeakingRecorder extends StatefulWidget {
  const IeltsSpeakingRecorder({
    super.key,
    required this.section,
    required this.alreadyRecorded,
    required this.onUpload,
  });

  final IeltsSection section;
  final bool alreadyRecorded;
  final Future<void> Function(String filePath, int durationSec) onUpload;

  @override
  State<IeltsSpeakingRecorder> createState() => _IeltsSpeakingRecorderState();
}

class _IeltsSpeakingRecorderState extends State<IeltsSpeakingRecorder> {
  final _recorder = AudioRecorder();
  bool _recording = false;
  bool _uploading = false;
  int _elapsed = 0;
  Timer? _tick;
  String? _error;

  @override
  void dispose() {
    _tick?.cancel();
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    setState(() => _error = null);
    final ok = await _recorder.hasPermission();
    if (!ok) {
      setState(() => _error = 'Microphone permission is required.');
      return;
    }
    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/ielts_speak_${widget.section.id}_${DateTime.now().millisecondsSinceEpoch}.wav';
    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.wav, sampleRate: 44100, numChannels: 1),
      path: path,
    );
    _elapsed = 0;
    _tick?.cancel();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _elapsed += 1);
    });
    setState(() => _recording = true);
  }

  Future<void> _stopAndUpload() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Finish recording?'),
        content: const Text(
          'You can only record once for this topic. After you stop, the recording is uploaded and cannot be replaced.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep recording')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Stop & upload')),
        ],
      ),
    );
    if (confirm != true) return;

    _tick?.cancel();
    final path = await _recorder.stop();
    setState(() {
      _recording = false;
      _uploading = true;
    });
    if (path == null || !File(path).existsSync()) {
      setState(() {
        _uploading = false;
        _error = 'Recording failed — no audio file.';
      });
      return;
    }
    try {
      await widget.onUpload(path, _elapsed);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  String _fmt(int s) {
    final m = s ~/ 60;
    final r = s % 60;
    return '${m.toString().padLeft(2, '0')}:${r.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final muted = context.semantic.textMuted;
    final prompt = widget.section.speakingPrompt.isNotEmpty
        ? widget.section.speakingPrompt
        : widget.section.prompt;
    final done = widget.alreadyRecorded;

    return ListView(
      padding: AppSpacing.pagePaddingWide,
      children: [
        Text('Speaking · Part ${widget.section.speakingPart}', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: AppSpacing.sm),
        if (widget.section.instructions.isNotEmpty)
          Text(widget.section.instructions, style: TextStyle(color: muted)),
        const SizedBox(height: AppSpacing.md),
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            borderRadius: AppRadius.card,
            border: Border.all(color: context.semantic.border),
            color: AppColors.primary.withValues(alpha: 0.06),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Cue card', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppColors.primary)),
              const SizedBox(height: AppSpacing.sm),
              Text(prompt.isEmpty ? '(No topic set)' : prompt, style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.5)),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        if (done)
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              borderRadius: AppRadius.card,
              color: Colors.green.withValues(alpha: 0.12),
            ),
            child: const Row(
              children: [
                Icon(Icons.check_circle_outline, color: Colors.green),
                SizedBox(width: 8),
                Expanded(child: Text('Recording uploaded. Your teacher will listen and give a band score.')),
              ],
            ),
          )
        else ...[
          Text(
            'Record once about this topic. When you stop, the recording is final.',
            style: TextStyle(color: muted),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            _fmt(_elapsed),
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ),
          Center(
            child: _uploading
                ? const CircularProgressIndicator()
                : FilledButton.icon(
                    onPressed: _recording ? _stopAndUpload : _start,
                    icon: Icon(_recording ? Icons.stop : Icons.mic),
                    label: Text(_recording ? 'Stop & upload' : 'Start recording'),
                    style: _recording
                        ? FilledButton.styleFrom(backgroundColor: Colors.red)
                        : null,
                  ),
          ),
        ],
      ],
    );
  }
}
