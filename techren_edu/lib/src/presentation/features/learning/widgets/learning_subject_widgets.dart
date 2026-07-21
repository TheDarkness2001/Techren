import 'package:flutter/material.dart';

import '../../../../core/theme/app_durations.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_semantic_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../domain/entities/learning_subject.dart';

Color parseSubjectColor(String hex, {Color fallback = const Color(0xFF2563EB)}) {
  final cleaned = hex.replaceAll('#', '').trim();
  if (cleaned.length == 6) {
    return Color(int.parse('FF$cleaned', radix: 16));
  }
  if (cleaned.length == 8) {
    return Color(int.parse(cleaned, radix: 16));
  }
  return fallback;
}

IconData iconForLearningKey(String key) {
  return switch (key) {
    'spellcheck' || 'words' => Icons.spellcheck_outlined,
    'format_quote' || 'sentences' => Icons.format_quote_outlined,
    'headphones' || 'listening' => Icons.headphones_outlined,
    'play_circle' || 'video' => Icons.play_circle_outline,
    'menu_book' || 'grammar' || 'lessons' => Icons.menu_book_outlined,
    'style' || 'flashcards' => Icons.style_outlined,
    'quiz' => Icons.quiz_outlined,
    'emoji_events' || 'exam' => Icons.emoji_events_outlined,
    'edit_note' || 'cms' || 'writing' => Icons.edit_note_outlined,
    'upload_file' || 'import' => Icons.upload_file_outlined,
    'insights' || 'progress' => Icons.insights_outlined,
    'code' || 'exercises' || 'computer' => Icons.code_outlined,
    'folder_special' || 'projects' => Icons.folder_special_outlined,
    'bolt' || 'challenges' => Icons.bolt_outlined,
    'calculate' || 'practice' || 'functions' => Icons.calculate_outlined,
    'lightbulb' || 'examples' => Icons.lightbulb_outline,
    'science' => Icons.science_outlined,
    'eco' => Icons.eco_outlined,
    'school' => Icons.school_outlined,
    'translate' => Icons.translate_outlined,
    'record_voice_over' || 'speaking' => Icons.record_voice_over_outlined,
    'forum' || 'dialogues' => Icons.forum_outlined,
    _ => Icons.auto_stories_outlined,
  };
}

class LearningSubjectCardWidget extends StatefulWidget {
  const LearningSubjectCardWidget({
    super.key,
    required this.subject,
    required this.onContinue,
    this.onEdit,
    this.onDelete,
  });

  final LearningSubjectCard subject;
  final VoidCallback onContinue;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  State<LearningSubjectCardWidget> createState() => _LearningSubjectCardWidgetState();
}

class _LearningSubjectCardWidgetState extends State<LearningSubjectCardWidget> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final semantic = context.semantic;
    final accent = parseSubjectColor(widget.subject.color, fallback: scheme.primary);
    final progress = widget.subject.progressPercent.clamp(0, 100);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedScale(
        scale: _hovered ? 1.015 : 1,
        duration: AppDurations.fast,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onContinue,
            borderRadius: AppRadius.card,
            child: AnimatedContainer(
              duration: AppDurations.fast,
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: AppRadius.card,
                border: Border.all(color: _hovered ? accent.withValues(alpha: 0.55) : semantic.border),
                boxShadow: _hovered ? AppShadows.cardHover : AppShadows.card,
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    height: 6,
                    color: accent,
                  ),
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: accent.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(iconForLearningKey(widget.subject.icon), color: accent),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.subject.name,
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: scheme.onSurface,
                                        ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    widget.subject.levelLabel,
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: semantic.textMuted,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            if (widget.onEdit != null || widget.onDelete != null)
                              PopupMenuButton<String>(
                                tooltip: 'Manage subject',
                                onSelected: (value) {
                                  if (value == 'edit') widget.onEdit?.call();
                                  if (value == 'delete') widget.onDelete?.call();
                                },
                                itemBuilder: (context) => [
                                  if (widget.onEdit != null)
                                    const PopupMenuItem(value: 'edit', child: Text('Edit')),
                                  if (widget.onDelete != null)
                                    const PopupMenuItem(value: 'delete', child: Text('Remove')),
                                ],
                              ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Row(
                          children: [
                            Text(
                              'Progress $progress%',
                              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                    color: scheme.onSurface,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            const Spacer(),
                            if (widget.subject.lastActivity != null)
                              Text(
                                _formatActivity(widget.subject.lastActivity!),
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: semantic.textMuted,
                                    ),
                              ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            value: progress / 100,
                            minHeight: 8,
                            backgroundColor: semantic.surfaceContainer,
                            color: accent,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Align(
                          alignment: Alignment.centerRight,
                          child: FilledButton.tonalIcon(
                            onPressed: widget.onContinue,
                            icon: const Icon(Icons.arrow_forward, size: 18),
                            label: const Text('Continue Learning'),
                            style: FilledButton.styleFrom(
                              foregroundColor: accent,
                              backgroundColor: accent.withValues(alpha: 0.12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatActivity(DateTime date) {
    final local = date.toLocal();
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    return 'Last $m/$d/${local.year}';
  }
}

class LearningModuleTile extends StatefulWidget {
  const LearningModuleTile({
    super.key,
    required this.module,
    required this.accent,
    required this.onTap,
  });

  final LearningModuleDef module;
  final Color accent;
  final VoidCallback onTap;

  @override
  State<LearningModuleTile> createState() => _LearningModuleTileState();
}

class _LearningModuleTileState extends State<LearningModuleTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final semantic = context.semantic;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedScale(
        scale: _hovered ? 1.03 : 1,
        duration: AppDurations.fast,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: AppRadius.card,
            child: AnimatedContainer(
              duration: AppDurations.fast,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: _hovered ? widget.accent.withValues(alpha: 0.1) : scheme.surface,
                borderRadius: AppRadius.card,
                border: Border.all(color: _hovered ? widget.accent : semantic.border),
                boxShadow: AppShadows.card,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(iconForLearningKey(widget.module.icon), color: widget.accent, size: 28),
                  const Spacer(),
                  Text(
                    widget.module.label,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: scheme.onSurface,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.module.category,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: semantic.textMuted),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
