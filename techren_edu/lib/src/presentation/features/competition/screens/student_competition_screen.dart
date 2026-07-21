import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/routing/student_navigation.dart';

import '../../../../core/theme/app_colors.dart';

import '../../../../core/theme/app_spacing.dart';

import '../../../../core/widgets/adaptive_scaffold.dart';

import '../../../../core/widgets/app_hub_card.dart';

import '../../../../core/widgets/common_widgets.dart';

import '../../../providers/auth_provider.dart';

import '../../../providers/competition_provider.dart';



class StudentCompetitionScreen extends ConsumerWidget {

  const StudentCompetitionScreen({

    super.key,

    this.navItems,

    required this.selectedRoute,

    this.selectedIndex = 4,

  });



  final List<NavItem>? navItems;

  final String selectedRoute;

  final int selectedIndex;



  @override

  Widget build(BuildContext context, WidgetRef ref) {

    final navItems = this.navItems ?? studentNavItemsOf(context);

    final user = ref.watch(authProvider).user;

    final studentId = user?.id ?? '';

    final penaltiesAsync = ref.watch(studentCompetitionPenaltiesProvider(studentId));

    final presentationsAsync = ref.watch(studentCompetitionPresentationsProvider(studentId));

    final index = navItems.indexWhere((i) => selectedRoute.startsWith(i.route));



    return AdaptiveScaffold(

      title: 'Competition',

      selectedIndex: index >= 0 ? index : selectedIndex,

      items: navItems,

      onDestinationSelected: (i) => onStudentNavSelected(context, navItems, i),

      body: RefreshIndicator(

        onRefresh: () async {

          ref.invalidate(studentCompetitionPenaltiesProvider(studentId));

          ref.invalidate(studentCompetitionPresentationsProvider(studentId));

        },

        child: ListView(

          padding: AppSpacing.listGutter,

          children: [

            const HubSectionHeader(title: 'This month'),

            const HubSectionHeader(title: 'Penalties', subtitle: 'Points deducted this month'),

            penaltiesAsync.when(

              loading: () => const LoadingState(kind: LoadingSkeletonKind.list),

              error: (e, _) => Text(e.toString()),

              data: (penalties) {

                final total = penalties.fold<int>(0, (sum, p) => sum + p.totalPoints);

                return Column(

                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [

                    Semantics(

                      label: 'Total penalty points: $total',

                      child: Chip(

                        label: Text('Total: $total points'),

                        backgroundColor: total < 0 ? AppColors.error.withValues(alpha: 0.1) : null,

                        padding: AppSpacing.chipPadding,

                      ),

                    ),

                    const SizedBox(height: AppSpacing.sm),

                    if (penalties.isEmpty)

                      const EmptyState(

                        title: 'No penalties',

                        message: 'Keep up the good attendance and punctuality.',

                        icon: Icons.emoji_events_outlined,

                      ),

                    ...penalties.map(

                      (p) => AppAdminRowCard(

                        title: p.type.replaceAll('_', ' '),

                        subtitle: p.notes,

                        icon: Icons.gavel_outlined,

                        accentColor: AppColors.warning,

                        trailing: Text(

                          '${p.totalPoints}',

                          style: const TextStyle(fontWeight: FontWeight.w700),

                        ),

                      ),

                    ),

                  ],

                );

              },

            ),

            const SizedBox(height: AppSpacing.lg),

            const HubSectionHeader(title: 'Presentations', subtitle: 'Scores from class presentations'),

            presentationsAsync.when(

              loading: () => const LoadingState(kind: LoadingSkeletonKind.list),

              error: (e, _) => Text(e.toString()),

              data: (presentations) => Column(

                crossAxisAlignment: CrossAxisAlignment.start,

                children: [

                  if (presentations.isEmpty)

                    const EmptyState(

                      title: 'No presentation scores',

                      message: 'Presentation scores from your teacher appear here.',

                      icon: Icons.mic_outlined,

                    ),

                  ...presentations.map(

                    (p) => AppAdminRowCard(

                      title: 'Score: ${p.score}/10',

                      subtitle: p.notes.isEmpty ? p.evaluatedByName ?? '' : p.notes,

                      icon: Icons.mic_outlined,

                      accentColor: AppColors.secondary,

                      trailing: Text('${p.date.day}/${p.date.month}'),

                    ),

                  ),

                ],

              ),

            ),

          ],

        ),

      ),

    );

  }

}


