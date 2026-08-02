import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_semantic_colors.dart';
import '../theme/app_spacing.dart';

class CommandPaletteItem {
  const CommandPaletteItem({required this.label, required this.icon, required this.route});

  final String label;
  final IconData icon;
  final String route;
}

/// Searchable nav jump dialog (staff Ctrl+K / clickable hint).
Future<void> showAppCommandPalette(
  BuildContext context, {
  required List<CommandPaletteItem> items,
}) async {
  await showDialog<void>(
    context: context,
    useRootNavigator: true,
    barrierColor: Colors.black54,
    builder: (dialogContext) => _CommandPaletteDialog(items: items),
  );
}

class _CommandPaletteDialog extends StatefulWidget {
  const _CommandPaletteDialog({required this.items});

  final List<CommandPaletteItem> items;

  @override
  State<_CommandPaletteDialog> createState() => _CommandPaletteDialogState();
}

class _CommandPaletteDialogState extends State<_CommandPaletteDialog> {
  final _queryController = TextEditingController();
  final _focusNode = FocusNode();
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _queryController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  List<CommandPaletteItem> get _filtered {
    if (_query.trim().isEmpty) return widget.items;
    final q = _query.toLowerCase();
    return widget.items.where((item) => item.label.toLowerCase().contains(q)).toList();
  }

  void _go(CommandPaletteItem item) {
    Navigator.of(context).pop();
    context.go(item.route);
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final maxListHeight = MediaQuery.sizeOf(context).height * 0.45;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Jump to page',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: AppSpacing.sm),
              CallbackShortcuts(
                bindings: {
                  const SingleActivator(LogicalKeyboardKey.escape): () => Navigator.of(context).pop(),
                },
                child: TextField(
                  controller: _queryController,
                  focusNode: _focusNode,
                  autofocus: true,
                  decoration: const InputDecoration(
                    hintText: 'Search pages...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (value) => setState(() => _query = value),
                  onSubmitted: (_) {
                    if (filtered.isNotEmpty) _go(filtered.first);
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              if (filtered.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  child: Text(
                    widget.items.isEmpty ? 'No pages available.' : 'No matches.',
                    style: TextStyle(color: context.semantic.textMuted),
                  ),
                )
              else
                ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: maxListHeight),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: filtered.length.clamp(0, 12),
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      return ListTile(
                        dense: true,
                        leading: Icon(item.icon, color: AppColors.primary),
                        title: Text(item.label),
                        shape: RoundedRectangleBorder(borderRadius: AppRadius.card),
                        onTap: () => _go(item),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
