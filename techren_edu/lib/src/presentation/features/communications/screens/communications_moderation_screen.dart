import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/adaptive_scaffold.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../domain/entities/communication.dart';
import '../../../providers/communications_provider.dart';

class CommunicationsModerationScreen extends ConsumerStatefulWidget {
  const CommunicationsModerationScreen({
    super.key,
    required this.navItems,
    required this.selectedRoute,
    this.routePrefix = '/admin',
  });

  final List<NavItem> navItems;
  final String selectedRoute;
  final String routePrefix;

  @override
  ConsumerState<CommunicationsModerationScreen> createState() => _CommunicationsModerationScreenState();
}

class _CommunicationsModerationScreenState extends ConsumerState<CommunicationsModerationScreen> {
  final _search = TextEditingController();
  List<ChatMessage> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await ref.read(communicationsApiProvider).moderationInbox(q: _search.text.trim());
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _delete(String id) async {
    try {
      await ref.read(communicationsApiProvider).moderateMessage(id, deleted: true, note: 'Removed by moderator');
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = widget.navItems.indexWhere(
      (i) => widget.selectedRoute.startsWith(i.route) || i.route.contains('/messages'),
    );

    return AdaptiveScaffold(
      title: 'Message moderation',
      selectedIndex: selectedIndex < 0 ? 0 : selectedIndex,
      selectedRoute: widget.selectedRoute,
      items: widget.navItems,
      onDestinationSelected: (i) => context.go(widget.navItems[i].route),
      actions: [
        IconButton(
          tooltip: 'Back to Messages',
          onPressed: () => context.go('${widget.routePrefix}/messages'),
          icon: const Icon(Icons.chat_bubble_outline),
        ),
        IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
      ],
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: TextField(
              controller: _search,
              decoration: InputDecoration(
                hintText: 'Search messages…',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(onPressed: _load, icon: const Icon(Icons.check)),
              ),
              onSubmitted: (_) => _load(),
            ),
          ),
          Expanded(
            child: _loading
                ? const LoadingState(message: 'Loading…')
                : _error != null
                    ? ErrorState(message: _error!, onRetry: _load)
                    : _items.isEmpty
                        ? const EmptyState(title: 'No messages', message: 'Moderation inbox is empty.')
                        : ListView.separated(
                            padding: AppSpacing.pagePaddingWide,
                            itemCount: _items.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (context, i) {
                              final m = _items[i];
                              return Card(
                                child: ListTile(
                                  title: Text(
                                    m.body.isNotEmpty ? m.body : '(attachment / system)',
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: Text('${m.senderType} · ${m.conversationId} · ${m.status}'),
                                  trailing: IconButton(
                                    tooltip: 'Delete',
                                    onPressed: () => _delete(m.id),
                                    icon: const Icon(Icons.delete_outline),
                                  ),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}
