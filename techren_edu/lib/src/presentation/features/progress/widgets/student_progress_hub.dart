import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_semantic_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_hub_card.dart';
import '../../../../core/widgets/person_avatar.dart';
import '../../../../domain/entities/student_progress.dart';
import '../../gamification/widgets/practice_recommendation_banner.dart';

class ProgressHubBody extends StatelessWidget {
  const ProgressHubBody({
    super.key,
    required this.overview,
    this.showStudentHeader = false,
    this.profileImage,
    this.onModuleTap,
    this.showRecommendation = false,
  });

  final ProgressOverview overview;
  final bool showStudentHeader;
  final String? profileImage;
  final void Function(String module)? onModuleTap;
  final bool showRecommendation;

  @override
  Widget build(BuildContext context) {
    final charts = _activeModuleCharts(overview.modules);

    return ListView(
      padding: AppSpacing.pagePaddingWide,
      children: [
        if (showStudentHeader) ...[
          _StudentHeader(
            name: overview.student.name,
            studentCode: overview.student.studentCode,
            status: overview.student.status,
            profileImage: profileImage,
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
        _ProgressSummaryRow(overview: overview),
        const SizedBox(height: AppSpacing.xl),
        if (showRecommendation) ...[
          const PracticeRecommendationBanner(compact: true),
          const SizedBox(height: AppSpacing.lg),
        ],
        if (overview.gamification != null) ...[
          ProgressXpCard(gamification: overview.gamification!),
          const SizedBox(height: AppSpacing.xl),
        ],
        if (charts.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
            child: Center(
              child: Text('No module progress yet — start practicing to see charts here.'),
            ),
          )
        else ...[
          Text(
            'Module progress',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.md),
          _ModuleProgressCharts(
            charts: charts,
            onModuleTap: onModuleTap,
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }
}

class _ModuleChartData {
  const _ModuleChartData({
    required this.id,
    required this.title,
    required this.percent,
    required this.detail,
    required this.color,
    required this.icon,
  });

  final String id;
  final String title;
  final int percent;
  final String detail;
  final Color color;
  final IconData icon;
}

List<_ModuleChartData> _activeModuleCharts(ModuleProgressSummary modules) {
  final charts = <_ModuleChartData>[];

  final wordsActive = modules.words.totalAttempts > 0 ||
      modules.words.accuracy > 0 ||
      modules.vocabLessons.lessonsPassed > 0;
  if (wordsActive) {
    charts.add(
      _ModuleChartData(
        id: 'words',
        title: 'Words',
        percent: modules.words.accuracy.clamp(0, 100),
        detail: '${modules.words.totalAttempts} attempts · ${modules.vocabLessons.lessonsPassed} lessons',
        color: AppColors.primary,
        icon: Icons.abc,
      ),
    );
  }

  final sentencesActive =
      modules.sentences.exercisesPracticed > 0 || modules.sentences.accuracy > 0 || modules.sentences.totalAttempts > 0;
  if (sentencesActive) {
    charts.add(
      _ModuleChartData(
        id: 'sentences',
        title: 'Sentences',
        percent: modules.sentences.accuracy.clamp(0, 100),
        detail: '${modules.sentences.exercisesPracticed} exercises',
        color: AppColors.secondary,
        icon: Icons.translate,
      ),
    );
  }

  final listeningActive = modules.listening.exercisesPracticed > 0 ||
      modules.listening.avgBestAccuracy > 0 ||
      modules.listening.totalAttempts > 0;
  if (listeningActive) {
    charts.add(
      _ModuleChartData(
        id: 'listening',
        title: 'Listening',
        percent: modules.listening.avgBestAccuracy.clamp(0, 100),
        detail: '${modules.listening.exercisesPracticed} exercises',
        color: AppColors.info,
        icon: Icons.headphones_outlined,
      ),
    );
  }

  final videoActive = modules.video.videosCompleted > 0 ||
      modules.video.videosStarted > 0 ||
      modules.video.avgWatchPercent > 0;
  if (videoActive) {
    charts.add(
      _ModuleChartData(
        id: 'video',
        title: 'Video',
        percent: modules.video.avgWatchPercent.clamp(0, 100),
        detail: '${modules.video.videosCompleted} completed',
        color: AppColors.tertiary,
        icon: Icons.play_circle_outline,
      ),
    );
  }

  return charts;
}

class _ModuleProgressCharts extends StatelessWidget {
  const _ModuleProgressCharts({required this.charts, this.onModuleTap});

  final List<_ModuleChartData> charts;
  final void Function(String module)? onModuleTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width >= 720 ? math.min(4, charts.length) : math.min(2, charts.length);
        final gap = AppSpacing.md;
        final cardWidth = columns == 1 ? width : (width - gap * (columns - 1)) / columns;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final chart in charts)
              SizedBox(
                width: cardWidth,
                child: _ModuleChartCard(
                  data: chart,
                  onTap: onModuleTap == null ? null : () => onModuleTap!(chart.id),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _ModuleChartCard extends StatelessWidget {
  const _ModuleChartCard({required this.data, this.onTap});

  final _ModuleChartData data;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final muted = context.semantic.textMuted;
    final border = context.semantic.border;

    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: AppRadius.card,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.card,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            borderRadius: AppRadius.card,
            border: Border.all(color: border),
            boxShadow: AppShadows.card,
          ),
          child: Column(
            children: [
              SizedBox(
                width: 120,
                height: 120,
                child: CustomPaint(
                  painter: _RingProgressPainter(
                    progress: data.percent / 100,
                    color: data.color,
                    trackColor: border.withValues(alpha: 0.35),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(data.icon, color: data.color, size: 22),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          '${data.percent}%',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                data.title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                data.detail,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RingProgressPainter extends CustomPainter {
  _RingProgressPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
  });

  final double progress;
  final Color color;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final stroke = 10.0;
    final radius = (math.min(size.width, size.height) - stroke) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final track = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, 0, math.pi * 2, false, track);

    final value = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    final sweep = (progress.clamp(0.0, 1.0)) * math.pi * 2;
    canvas.drawArc(rect, -math.pi / 2, sweep, false, value);
  }

  @override
  bool shouldRepaint(covariant _RingProgressPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color || oldDelegate.trackColor != trackColor;
  }
}

class _StudentHeader extends StatelessWidget {
  const _StudentHeader({
    required this.name,
    this.studentCode,
    this.status,
    this.profileImage,
  });

  final String name;
  final String? studentCode;
  final String? status;
  final String? profileImage;

  @override
  Widget build(BuildContext context) {
    final subtitle = [studentCode, status].whereType<String>().where((v) => v.isNotEmpty).join(' · ');

    return Semantics(
      header: true,
      label: 'Student profile. $name${subtitle.isNotEmpty ? '. $subtitle' : ''}',
      child: Card(
        child: ListTile(
          leading: PersonAvatar(
            name: name,
            profileImage: profileImage,
            isStudent: true,
            isActive: status != 'inactive',
            radius: 28,
          ),
          title: Text(name, style: Theme.of(context).textTheme.titleLarge),
          subtitle: Text(subtitle),
        ),
      ),
    );
  }
}

class _ProgressSummaryRow extends StatelessWidget {
  const _ProgressSummaryRow({required this.overview});

  final ProgressOverview overview;

  @override
  Widget build(BuildContext context) {
    final modules = overview.modules;
    final xp = overview.gamification?['totalXp'] as int? ?? 0;
    final level = overview.gamification?['level'] as int? ?? 1;
    final chips = <Widget>[];

    if (modules.words.accuracy > 0 || modules.words.totalAttempts > 0) {
      chips.add(_SummaryChip(label: 'Words', value: '${modules.words.accuracy}%'));
    }
    if (modules.sentences.accuracy > 0 || modules.sentences.exercisesPracticed > 0) {
      chips.add(_SummaryChip(label: 'Sentences', value: '${modules.sentences.accuracy}%'));
    }
    if (modules.vocabLessons.lessonsPassed > 0) {
      chips.add(_SummaryChip(label: 'Lessons', value: '${modules.vocabLessons.lessonsPassed}'));
    }
    chips.add(_SummaryChip(label: 'Level', value: '$level'));
    if (xp > 0) {
      chips.add(_SummaryChip(label: 'XP', value: '$xp'));
    }

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: chips,
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label: $value',
      child: Chip(
        label: Text('$label: $value'),
        visualDensity: VisualDensity.compact,
        padding: AppSpacing.chipPadding,
      ),
    );
  }
}

class ProgressXpCard extends StatelessWidget {
  const ProgressXpCard({super.key, required this.gamification});

  final Map<String, dynamic> gamification;

  @override
  Widget build(BuildContext context) {
    final level = gamification['level'] as int? ?? 1;
    final totalXp = gamification['totalXp'] as int? ?? 0;
    final streak = gamification['currentStreak'] as int? ?? 0;
    final xpInLevel = gamification['xpInLevel'] as int? ?? 0;
    final levelCap = gamification['levelCap'] as int? ?? 300;
    final progress = levelCap > 0 ? xpInLevel / levelCap : 0.0;

    return Semantics(
      label: 'Level $level. $totalXp XP total. $streak day streak. $xpInLevel of $levelCap XP to next level',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: AppRadius.card,
          boxShadow: AppShadows.card,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Level $level', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: AppSpacing.xs),
            Text('$totalXp XP total · $streak day streak'),
            const SizedBox(height: AppSpacing.md),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: LinearProgressIndicator(
                value: progress.clamp(0, 1),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text('$xpInLevel / $levelCap XP to next level', style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class ProgressModuleCard extends StatelessWidget {
  const ProgressModuleCard({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.stats,
    this.onTap,
  });

  final String title;
  final IconData icon;
  final Color color;
  final List<String> stats;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AppHubCard(
      title: title,
      subtitle: stats.join(' · '),
      accentColor: color,
      icon: icon,
      onTap: onTap,
    );
  }
}

class StudentVocabLessonsList extends StatelessWidget {
  const StudentVocabLessonsList({super.key, required this.lessons});

  final List<StudentVocabLessonProgress> lessons;

  @override
  Widget build(BuildContext context) {
    if (lessons.isEmpty) {
      return const Center(
        child: Padding(
          padding: AppSpacing.pagePaddingWide,
          child: Text('No vocabulary lesson progress yet.'),
        ),
      );
    }

    return ListView.builder(
      padding: AppSpacing.listGutter,
      itemCount: lessons.length,
      itemBuilder: (_, i) {
        final lesson = lessons[i];
        final locked = lesson.status == 'locked';
        final semantic = context.semantic;

        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: AppAdminRowCard(
            title: lesson.lessonName,
            subtitle:
                'Practice ${lesson.practiceAttempts} · Exam best ${lesson.bestExamScore}% · ${_statusLabel(lesson.status)}',
            icon: Icons.menu_book_outlined,
            accentColor: _statusColor(lesson.status, semantic),
            locked: locked,
            trailing: lesson.wordsTotal > 0
                ? Text(
                    '${lesson.wordsMemorized}/${lesson.wordsTotal}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  )
                : null,
          ),
        );
      },
    );
  }

  Color _statusColor(String status, AppSemanticColors semantic) {
    switch (status) {
      case 'passed':
        return semantic.success;
      case 'available':
        return AppColors.info;
      default:
        return semantic.textMuted;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'passed':
        return 'Passed';
      case 'available':
        return 'In progress';
      case 'locked':
        return 'Locked';
      default:
        return status;
    }
  }
}

void openStudentLearningModule(BuildContext context, String module) {
  switch (module) {
    case 'words':
      context.go('/student/words');
    case 'sentences':
      context.go('/student/sentences');
    case 'listening':
      context.go('/student/listening');
    case 'video':
      context.go('/student/video');
  }
}
