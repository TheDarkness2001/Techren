import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import 'app_hub_card.dart';

/// Prefer full name; if too long, use first name + student id.
String compactLeaderboardName(String name, String studentCode, {int maxChars = 16}) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) return studentCode.isNotEmpty ? studentCode : 'Student';
  if (trimmed.length <= maxChars) return trimmed;
  final parts = trimmed.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  final first = parts.isNotEmpty ? parts.first : trimmed;
  if (studentCode.isNotEmpty) return '$first · $studentCode';
  return first;
}

bool isCurrentLeaderboardEntry({
  required String entryName,
  required String entryCode,
  required int entryRank,
  required String? meName,
  required String? meCode,
  required int? meRank,
}) {
  if (meRank == null) return false;
  if (meCode != null && meCode.isNotEmpty && entryCode == meCode) return true;
  return entryRank == meRank && entryName == (meName ?? '');
}

/// Top-10 list + optional separated "your place" row when rank is below 10.
class StudentLeaderboardList extends StatelessWidget {
  const StudentLeaderboardList({
    super.key,
    required this.entries,
    required this.onRefresh,
    this.currentRank,
    this.currentName,
    this.currentCode,
    this.outsideTopBuilder,
    this.emptyMessage = 'No rankings yet.',
  });

  final List<Widget> entries;
  final Future<void> Function() onRefresh;
  final int? currentRank;
  final String? currentName;
  final String? currentCode;
  final Widget Function()? outsideTopBuilder;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    final showOutside = currentRank != null && currentRank! > 10 && outsideTopBuilder != null;

    if (entries.isEmpty && !showOutside) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: AppSpacing.listGutter,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xl),
              child: Text(emptyMessage, textAlign: TextAlign.center),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: AppSpacing.listGutter,
        children: [
          ...entries,
          if (showOutside) ...[
            const SizedBox(height: AppSpacing.md),
            const HubSectionHeader(
              title: 'Your place',
              subtitle: 'Outside the top 10',
            ),
            outsideTopBuilder!(),
          ],
        ],
      ),
    );
  }
}

LeaderboardHubCard buildOutsideTopCard({
  required int rank,
  required String title,
  required String subtitle,
  required String trailing,
}) {
  return LeaderboardHubCard(
    rank: rank,
    title: title,
    subtitle: subtitle,
    trailing: trailing,
    highlighted: true,
  );
}
