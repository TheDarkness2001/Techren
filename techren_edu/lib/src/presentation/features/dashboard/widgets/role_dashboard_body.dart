import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';



import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_semantic_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/update_banner.dart';
import '../../../../domain/entities/branch.dart';
import '../../../../domain/entities/dashboard_data.dart';
import '../../../../domain/entities/person.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/identity_provider.dart';
import 'dashboard_header.dart';
import 'dashboard_widgets.dart';
import 'role_dashboard_shortcuts.dart';



/// Role-aware dashboard body — compact stats, quick actions, welcome panel.
class RoleDashboardBody extends ConsumerWidget {
  const RoleDashboardBody({super.key, required this.dashboardAsync});



  final AsyncValue<DashboardData> dashboardAsync;



  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return dashboardAsync.when(
      loading: () => const LoadingState(message: 'Loading dashboard...', kind: LoadingSkeletonKind.dashboard),
      error: (e, _) => ErrorState(message: e.toString(), onRetry: () => ref.invalidate(dashboardProvider)),
      data: (data) => RefreshIndicator(
        onRefresh: () async => ref.invalidate(dashboardProvider),
        child: ListView(
          padding: AppSpacing.pagePaddingWide,
          children: [
            const UpdateBanner(),
            DashboardStatRow(children: _statsForRole(data)),
            if (showRoleDashboardShortcuts(data.role)) ...[
              const SizedBox(height: AppSpacing.xl),
              RoleDashboardShortcuts(role: data.role),
            ],
            if (_showWelcomePanel(data.role)) ...[
              const SizedBox(height: AppSpacing.xl),
              DashboardWelcomePanel(
                userName: _displayName(ref, data),
                roleLabel: dashboardRoleLabel(data.role),
                prefix: dashboardPrefixForRole(data.role),
              ),
            ],
            if (data.recentStudents.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xl),
              DashboardSection(
                title: 'Recent students',
                child: Column(
                  children: [
                    for (final student in data.recentStudents) _RecentStudentRow(student: student),
                  ],
                ),
              ),
            ],
            if (data.role == 'founder' && data.recentBranches.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xl),
              DashboardSection(
                title: 'Recent branches',
                trailing: TextButton(
                  onPressed: () => context.go('/founder/branches'),
                  child: const Text('View all'),
                ),
                child: Column(
                  children: [
                    for (final branch in data.recentBranches) _BranchRow(branch: branch),
                  ],
                ),
              ),
            ],
            if (data.role == 'student' && data.profile != null) ...[
              const SizedBox(height: AppSpacing.xl),
              _StudentAccountCard(profile: data.profile!),
            ],
            if (_isEmptyDashboard(data)) ...[
              const SizedBox(height: AppSpacing.xl),
              _RoleEmptyPanel(role: data.role),
            ],
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }



  bool _showWelcomePanel(String role) =>
      role == 'founder' || role == 'admin' || role == 'manager' || role == 'sales' || role == 'receptionist';



  bool _isEmptyDashboard(DashboardData data) {
    if (data.role == 'student') return false;
    return !showRoleDashboardShortcuts(data.role) &&
        data.recentStudents.isEmpty &&
        data.recentBranches.isEmpty;
  }



  String _displayName(WidgetRef ref, DashboardData data) {
    if (data.greeting != null && data.greeting!.isNotEmpty) return data.greeting!;
    return ref.watch(authProvider).user?.name ?? 'User';
  }



  List<Widget> _statsForRole(DashboardData data) {
    final semantic = AppSemanticColors.light;



    switch (data.role) {
      case 'founder':
        final inactiveBranches = data.stat('branches') - data.stat('activeBranches');
        return [
          DashboardStatCard(
            label: 'Total Students',
            value: '${data.stat('students')}',
            icon: Icons.school_outlined,
            accentColor: AppColors.primary,
          ),
          DashboardStatCard(
            label: 'Total Teachers',
            value: '${data.stat('teachers')}',
            icon: Icons.groups_outlined,
            accentColor: const Color(0xFF38BDF8),
          ),
          DashboardStatCard(
            label: 'Inactive Branches',
            value: '$inactiveBranches',
            icon: Icons.apartment_outlined,
            accentColor: semantic.danger,
          ),
          DashboardStatCard(
            label: 'Active Branches',
            value: '${data.stat('activeBranches')}',
            icon: Icons.check_circle_outline,
            accentColor: semantic.success,
          ),
        ];
      case 'admin':
      case 'manager':
      case 'sales':
      case 'receptionist':
        return [
          DashboardStatCard(
            label: 'Total Students',
            value: '${data.stat('students')}',
            icon: Icons.school_outlined,
            accentColor: AppColors.primary,
          ),
          DashboardStatCard(
            label: 'Total Teachers',
            value: '${data.stat('teachers')}',
            icon: Icons.groups_outlined,
            accentColor: const Color(0xFF38BDF8),
          ),
          DashboardStatCard(
            label: 'Inactive Students',
            value: '${data.stat('inactiveStudents')}',
            icon: Icons.warning_amber_outlined,
            accentColor: semantic.danger,
          ),
          DashboardStatCard(
            label: 'Active Students',
            value: '${data.stat('activeStudents')}',
            icon: Icons.check_circle_outline,
            accentColor: semantic.success,
          ),
        ];
      case 'teacher':
        return [
          DashboardStatCard(
            label: 'Branch students',
            value: '${data.stat('studentsInBranch')}',
            icon: Icons.school_outlined,
            accentColor: AppColors.primary,
          ),
          DashboardStatCard(
            label: 'Subjects',
            value: '${data.stat('subjects')}',
            icon: Icons.menu_book_outlined,
            accentColor: AppColors.secondary,
          ),
        ];
      case 'student':
        final eligible = data.profile?.examEligibility == true;
        return [
          DashboardStatCard(
            label: 'Account status',
            value: data.profile?.status ?? 'active',
            icon: Icons.person_outline,
          ),
          DashboardStatCard(
            label: 'Exam ready',
            value: eligible ? 'Yes' : 'No',
            icon: Icons.fact_check_outlined,
            accentColor: eligible ? semantic.success : semantic.warning,
          ),
        ];
      default:
        return [const DashboardStatCard(label: 'Overview', value: '—', icon: Icons.analytics_outlined)];
    }
  }
}



class _RecentStudentRow extends StatelessWidget {
  const _RecentStudentRow({required this.student});



  final Person student;



  @override
  Widget build(BuildContext context) {
    return DashboardListTile(
      title: student.name,
      subtitle: student.email ?? student.displayId ?? 'Student',
      icon: Icons.person_outline,
      onTap: () => context.go('/admin/people'),
    );
  }
}



class _BranchRow extends StatelessWidget {
  const _BranchRow({required this.branch});



  final Branch branch;



  @override
  Widget build(BuildContext context) {
    final semantic = context.semantic;
    return DashboardListTile(
      title: branch.name,
      subtitle: branch.isActive ? 'Active branch' : 'Inactive branch',
      icon: Icons.account_tree_outlined,
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
        decoration: BoxDecoration(
          color: branch.isActive ? semantic.successContainer : semantic.dangerContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          branch.isActive ? 'Active' : 'Inactive',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: branch.isActive ? semantic.success : semantic.danger,
          ),
        ),
      ),
      onTap: () => context.go('/founder/branches'),
    );
  }
}



class _StudentAccountCard extends StatelessWidget {
  const _StudentAccountCard({required this.profile});



  final Person profile;



  @override
  Widget build(BuildContext context) {
    final eligible = profile.examEligibility == true;
    final muted = context.semantic.textMuted;



    return DashboardSection(
      title: 'Account',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.semantic.border),
        ),
        child: Column(
          children: [
            _InfoRow(label: 'Status', value: profile.status),
            const Divider(height: AppSpacing.lg),
            _InfoRow(label: 'Exam eligibility', value: eligible ? 'Eligible' : 'Not eligible'),
            if (profile.email != null) ...[
              const Divider(height: AppSpacing.lg),
              _InfoRow(label: 'Email', value: profile.email!),
            ],
            if (profile.email == null) ...[
              const Divider(height: AppSpacing.lg),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('No email on file', style: TextStyle(color: muted, fontSize: 13)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}



class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});



  final String label;
  final String value;



  @override
  Widget build(BuildContext context) {
    final muted = context.semantic.textMuted;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: muted),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}



class _RoleEmptyPanel extends StatelessWidget {
  const _RoleEmptyPanel({required this.role});



  final String role;



  @override
  Widget build(BuildContext context) {
    final (title, message, icon) = switch (role) {
      'teacher' => (
          'Ready to teach',
          'Open attendance or your class schedule to get started.',
          Icons.class_outlined,
        ),
      _ => (
          'Welcome',
          'Use the navigation menu to explore your workspace.',
          Icons.dashboard_outlined,
        ),
    };



    return EmptyState(title: title, message: message, icon: icon);
  }
}



class ErrorState extends StatelessWidget {
  const ErrorState({super.key, required this.message, this.onRetry});



  final String message;
  final VoidCallback? onRetry;



  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: context.semantic.danger),
            const SizedBox(height: AppSpacing.sm),
            Text(message, textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.md),
              FilledButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ],
        ),
      ),
    );
  }
}


