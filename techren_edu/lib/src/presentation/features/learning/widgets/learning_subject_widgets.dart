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
    'keyboard' || 'typing' => Icons.keyboard_outlined,
    'folder_special' || 'projects' => Icons.folder_special_outlined,
    'bolt' || 'challenges' => Icons.bolt_outlined,
    'calculate' || 'practice' || 'functions' => Icons.calculate_outlined,
    'lightbulb' || 'examples' => Icons.lightbulb_outline,
    'science' => Icons.science_outlined,
    'eco' => Icons.eco_outlined,
    'school' || 'ielts' => Icons.school_outlined,
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
    final compact = MediaQuery.sizeOf(context).height < 820 || MediaQuery.sizeOf(context).width < 1100;
    final iconSize = compact ? 36.0 : 48.0;
    final pad = compact ? AppSpacing.sm : AppSpacing.md;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
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
              border: Border.all(
                color: _hovered ? accent.withValues(alpha: 0.55) : semantic.border,
                width: _hovered ? 1.5 : 1,
              ),
              boxShadow: _hovered ? AppShadows.cardHover : AppShadows.card,
            ),
            clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    height: compact ? 4 : 6,
                    color: accent,
                  ),
                  Padding(
                    padding: EdgeInsets.all(pad),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: iconSize,
                              height: iconSize,
                              decoration: BoxDecoration(
                                color: accent.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(compact ? 10 : 14),
                              ),
                              child: Icon(
                                iconForLearningKey(widget.subject.icon),
                                color: accent,
                                size: compact ? 20 : 24,
                              ),
                            ),
                            SizedBox(width: compact ? AppSpacing.sm : AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.subject.name,
                                    style: (compact
                                            ? Theme.of(context).textTheme.titleSmall
                                            : Theme.of(context).textTheme.titleMedium)
                                        ?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: scheme.onSurface,
                                        ),
                                  ),
                                  if (widget.subject.description.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      widget.subject.description,
                                      maxLines: compact ? 1 : 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: semantic.textMuted,
                                          ),
                                    ),
                                  ],
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
                        SizedBox(height: compact ? AppSpacing.sm : AppSpacing.md),
                        Row(
                          children: [
                            Text(
                              'Progress $progress%',
                              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                    color: scheme.onSurface,
                                    fontWeight: FontWeight.w600,
                                    fontSize: compact ? 12 : null,
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
                        SizedBox(height: compact ? AppSpacing.xs : AppSpacing.sm),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            value: progress / 100,
                            minHeight: compact ? 5 : 8,
                            backgroundColor: semantic.surfaceContainer,
                            color: accent,
                          ),
                        ),
                        SizedBox(height: compact ? AppSpacing.sm : AppSpacing.md),
                        Align(
                          alignment: Alignment.centerRight,
                          child: FilledButton.tonalIcon(
                            onPressed: widget.onContinue,
                            icon: Icon(Icons.arrow_forward, size: compact ? 16 : 18),
                            label: Text(compact ? 'Continue' : 'Continue Learning'),
                            style: FilledButton.styleFrom(
                              foregroundColor: accent,
                              backgroundColor: accent.withValues(alpha: 0.12),
                              visualDensity: compact ? VisualDensity.compact : VisualDensity.standard,
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
    this.locked = false,
  });

  final LearningModuleDef module;
  final Color accent;
  final VoidCallback onTap;
  final bool locked;

  @override
  State<LearningModuleTile> createState() => _LearningModuleTileState();
}

class _LearningModuleTileState extends State<LearningModuleTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final semantic = context.semantic;

    // No scale transform — it overflows the fixed tile and gets clipped under
    // the section title / adjacent cards (hover border looks cut off).
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: AppRadius.card,
          child: AnimatedContainer(
            duration: AppDurations.fast,
            padding: EdgeInsets.all(
              MediaQuery.sizeOf(context).height < 820 ? AppSpacing.sm : AppSpacing.md,
            ),
            decoration: BoxDecoration(
              color: _hovered ? widget.accent.withValues(alpha: 0.1) : scheme.surface,
              borderRadius: AppRadius.card,
              border: Border.all(
                color: _hovered ? widget.accent : semantic.border,
                width: _hovered ? 1.5 : 1,
              ),
              boxShadow: _hovered ? AppShadows.cardHover : AppShadows.card,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      iconForLearningKey(widget.module.icon),
                      color: widget.accent,
                      size: MediaQuery.sizeOf(context).height < 820 ? 22 : 28,
                    ),
                    const Spacer(),
                    if (widget.locked) Icon(Icons.lock_outline, size: 18, color: semantic.textMuted),
                  ],
                ),
                const Spacer(),
                Text(
                  widget.module.label,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface,
                        fontSize: MediaQuery.sizeOf(context).height < 820 ? 13 : null,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.locked ? 'Locked' : widget.module.category,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: semantic.textMuted),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
