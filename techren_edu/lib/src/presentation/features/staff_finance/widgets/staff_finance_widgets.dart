import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_semantic_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/format_money.dart';
import '../../../../domain/entities/staff_finance.dart';

String staffFinanceInitials(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (parts.length >= 2) {
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
  if (parts.isEmpty) return '?';
  return parts.first.substring(0, parts.first.length >= 2 ? 2 : 1).toUpperCase();
}

String staffFinanceTypeLabel(String type) {
  return switch (type) {
    'per-class' => 'Class',
    'hourly' => 'Hourly',
    'commission' => 'Commission',
    'bonus' => 'Bonus',
    'adjustment' => 'Other',
    'penalty' => 'Penalty',
    'cash' => 'Cash',
    'bank-transfer' => 'Bank transfer',
    'uzcard' => 'Uzcard',
    'humo' => 'Humo',
    _ => type.replaceAll('-', ' '),
  };
}

String staffFinanceStatusLabel(String status, {bool isPayout = false}) {
  if (isPayout) {
    return switch (status) {
      'completed' => 'Confirmed',
      'cancelled' => 'Cancelled',
      _ => 'Awaiting confirmation',
    };
  }
  return switch (status) {
    'approved' => 'Approved',
    'paid' => 'Completed',
    'cancelled' => 'Cancelled',
    _ => 'Pending',
  };
}

class StaffFinanceStatusPill extends StatelessWidget {
  const StaffFinanceStatusPill({super.key, required this.status, this.isPayout = false});

  final String status;
  final bool isPayout;

  @override
  Widget build(BuildContext context) {
    final completed = status == 'completed' || status == 'paid' || status == 'approved';
    final cancelled = status == 'cancelled';
    final color = cancelled
        ? AppColors.error
        : completed
            ? AppColors.success
            : AppColors.warning;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        staffFinanceStatusLabel(status, isPayout: isPayout),
        style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12),
      ),
    );
  }
}

class StaffFinanceTypeCell extends StatelessWidget {
  const StaffFinanceTypeCell({super.key, required this.type});

  final String type;

  @override
  Widget build(BuildContext context) {
    final color = switch (type) {
      'per-class' => AppColors.info,
      'hourly' || 'commission' => AppColors.primarySoft,
      'bonus' => AppColors.success,
      _ => AppColors.warning,
    };
    final icon = switch (type) {
      'per-class' => Icons.menu_book_outlined,
      'hourly' => Icons.schedule_outlined,
      'bonus' => Icons.card_giftcard_outlined,
      _ => Icons.description_outlined,
    };
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Text(staffFinanceTypeLabel(type)),
      ],
    );
  }
}

class StaffFinanceKpiCard extends StatelessWidget {
  const StaffFinanceKpiCard({
    super.key,
    required this.label,
    required this.value,
    required this.hint,
    required this.icon,
    required this.accent,
  });

  final String label;
  final String value;
  final String hint;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final semantic = context.semantic;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: AppRadius.cardLarge,
        border: Border.all(color: semantic.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(icon, size: 18, color: accent),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: semantic.textMuted)),
          const SizedBox(height: 4),
          Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(hint, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: accent)),
        ],
      ),
    );
  }
}

class StaffFinanceSummaryStrip extends StatelessWidget {
  const StaffFinanceSummaryStrip({super.key, required this.account, this.onViewPayouts});

  final StaffAccountSummary account;
  final VoidCallback? onViewPayouts;

  @override
  Widget build(BuildContext context) {
    final semantic = context.semantic;
    final cards = [
      StaffFinanceKpiCard(
        label: 'Total Earned',
        value: formatUzs(account.totalEarned),
        hint: 'All-time earnings',
        icon: Icons.savings_outlined,
        accent: AppColors.primarySoft,
      ),
      StaffFinanceKpiCard(
        label: 'Available',
        value: formatUzs(account.availableForPayout),
        hint: 'Ready to payout',
        icon: Icons.account_balance_wallet_outlined,
        accent: const Color(0xFF818CF8),
      ),
      StaffFinanceKpiCard(
        label: 'Pending',
        value: formatUzs(account.pendingEarnings),
        hint: 'Processing',
        icon: Icons.schedule_outlined,
        accent: AppColors.warning,
      ),
      StaffFinanceKpiCard(
        label: 'Paid out',
        value: formatUzs(account.totalPaidOut),
        hint: 'Confirmed received',
        icon: Icons.check_circle_outline,
        accent: AppColors.success,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 720;
            if (wide) {
              return Row(
                children: [
                  for (var i = 0; i < cards.length; i++) ...[
                    if (i > 0) const SizedBox(width: AppSpacing.sm),
                    Expanded(child: cards[i]),
                  ],
                ],
              );
            }
            return Column(
              children: [
                for (var i = 0; i < cards.length; i++) ...[
                  if (i > 0) const SizedBox(height: AppSpacing.sm),
                  cards[i],
                ],
              ],
            );
          },
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Icon(Icons.info_outline, size: 16, color: semantic.textMuted),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Earnings are calculated from classes, lessons and other activities.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: semantic.textMuted),
              ),
            ),
            if (onViewPayouts != null)
              TextButton.icon(
                onPressed: onViewPayouts,
                icon: const Icon(Icons.open_in_new, size: 16),
                label: const Text('View payout history'),
              ),
          ],
        ),
      ],
    );
  }
}

class StaffMemberPickerCard extends StatelessWidget {
  const StaffMemberPickerCard({
    super.key,
    required this.name,
    required this.role,
    this.onTap,
  });

  final String name;
  final String role;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final semantic = context.semantic;
    return Material(
      color: scheme.surface,
      borderRadius: AppRadius.cardLarge,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.cardLarge,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: AppRadius.cardLarge,
            border: Border.all(color: semantic.border),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: const Color(0xFF6366F1).withValues(alpha: 0.2),
                child: Text(
                  staffFinanceInitials(name),
                  style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFFA5B4FC)),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                    Text(role, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: semantic.textMuted)),
                  ],
                ),
              ),
              Icon(onTap == null ? Icons.person_outline : Icons.expand_more, color: semantic.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
