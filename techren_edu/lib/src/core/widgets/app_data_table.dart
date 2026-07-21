import 'package:flutter/material.dart';

import '../theme/app_radius.dart';
import '../theme/app_semantic_colors.dart';
import '../theme/app_spacing.dart';

/// Styled data table panel — card wrapper + scroll + header row for admin screens.
class AppDataTable extends StatelessWidget {
  const AppDataTable({
    super.key,
    required this.columns,
    required this.rows,
    this.onSelectChanged,
    this.emptyMessage,
  });

  final List<String> columns;
  final List<AppDataRow> rows;
  final ValueChanged<int>? onSelectChanged;
  final String? emptyMessage;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return Center(
        child: Text(
          emptyMessage ?? 'No records found',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: context.semantic.textMuted),
        ),
      );
    }

    final border = BorderSide(color: context.semantic.border.withValues(alpha: 0.8));

    return Semantics(
      label: 'Data table with ${rows.length} rows',
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: MediaQuery.sizeOf(context).width - AppSpacing.lg * 2),
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(context.semantic.surfaceContainer),
              headingRowHeight: 52,
              dataRowMinHeight: 64,
              dataRowMaxHeight: 72,
              headingTextStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    letterSpacing: 0.4,
                  ),
              dataTextStyle: Theme.of(context).textTheme.bodyMedium,
              columnSpacing: AppSpacing.lg,
              horizontalMargin: AppSpacing.md,
              dividerThickness: 1,
              border: TableBorder(
                horizontalInside: border,
                bottom: border,
              ),
              columns: [
                for (final column in columns) DataColumn(label: Text(column.toUpperCase())),
              ],
              rows: [
                for (var i = 0; i < rows.length; i++)
                  DataRow(
                    onSelectChanged: onSelectChanged == null ? null : (_) => onSelectChanged!(i),
                    cells: [
                      for (final cell in rows[i].cells) DataCell(cell),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AppDataRow {
  const AppDataRow({required this.cells});

  final List<Widget> cells;
}

/// Compact status badge for table cells.
class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.label, required this.color, this.background});

  final String label;
  final Color color;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
      decoration: BoxDecoration(
        color: background ?? color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}
