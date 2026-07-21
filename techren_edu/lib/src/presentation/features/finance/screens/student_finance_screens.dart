import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/go_back_icon_button.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/routing/student_navigation.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/adaptive_scaffold.dart';
import '../../../../core/widgets/app_hub_card.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../providers/finance_provider.dart';

class StudentExamsScreen extends ConsumerWidget {
  const StudentExamsScreen({
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
    final l10n = context.l10n;
    final examsAsync = ref.watch(studentExamsProvider);
    final index = navItems.indexWhere((i) => selectedRoute.startsWith(i.route));

    return AdaptiveScaffold(
      title: l10n.myExams,
      selectedIndex: index >= 0 ? index : selectedIndex,
      items: navItems,
      onDestinationSelected: (i) => onStudentNavSelected(context, navItems, i),
      actions: [
        GoBackIconButton(fallbackRoute: '/student/profile'),
      ],
      body: examsAsync.when(
        loading: () => const LoadingState(kind: LoadingSkeletonKind.list),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (exams) {
          if (exams.isEmpty) {
            return const EmptyState(
              title: 'No exam results',
              message: 'Your institutional exam results will appear here.',
              icon: Icons.quiz_outlined,
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(studentExamsProvider),
            child: ListView.builder(
              padding: AppSpacing.listGutter,
              itemCount: exams.length,
              itemBuilder: (context, index) {
                final exam = exams[index];
                final myResult = exam.results.isNotEmpty ? exam.results.first : null;
                final passed = myResult?.passed ?? false;
                return AppAdminRowCard(
                  title: exam.examName,
                  subtitle: '${exam.subject} · ${exam.status}',
                  icon: passed ? Icons.check_circle_outline : Icons.cancel_outlined,
                  accentColor: passed ? AppColors.success : AppColors.error,
                  trailing: Text('${myResult?.marksObtained ?? 0}/${exam.totalMarks}'),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class StudentPaymentsScreen extends ConsumerWidget {
  const StudentPaymentsScreen({
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
    final l10n = context.l10n;
    final paymentsAsync = ref.watch(studentPaymentsProvider);
    final index = navItems.indexWhere((i) => selectedRoute.startsWith(i.route));

    return AdaptiveScaffold(
      title: l10n.myPayments,
      selectedIndex: index >= 0 ? index : selectedIndex,
      items: navItems,
      onDestinationSelected: (i) => onStudentNavSelected(context, navItems, i),
      actions: [
        GoBackIconButton(fallbackRoute: '/student/profile'),
      ],
      body: paymentsAsync.when(
        loading: () => const LoadingState(kind: LoadingSkeletonKind.list),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (payments) {
          if (payments.isEmpty) {
            return const EmptyState(
              title: 'No payments',
              message: 'Your payment history will appear here.',
              icon: Icons.payments_outlined,
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(studentPaymentsProvider),
            child: ListView.builder(
              padding: AppSpacing.listGutter,
              itemCount: payments.length,
              itemBuilder: (context, index) {
                final payment = payments[index];
                return AppAdminRowCard(
                  title: payment.subject,
                  subtitle: '${payment.month}/${payment.year} · ${payment.status}',
                  icon: payment.status == 'paid' ? Icons.check_circle_outline : Icons.schedule_outlined,
                  accentColor: payment.status == 'paid' ? AppColors.success : AppColors.tertiary,
                  trailing: Text('${payment.amount.toStringAsFixed(0)} UZS'),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
