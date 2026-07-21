import 'package:flutter/material.dart';

import 'metric_card.dart';

/// Backward-compatible alias — delegates to [MetricCard] (Phase C dashboard card).
class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.color,
  });

  final String label;
  final String value;
  final IconData? icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return MetricCard(
      label: label,
      value: value,
      icon: icon ?? Icons.analytics_outlined,
      accentColor: color,
    );
  }
}
