import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/network/communications_socket.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_semantic_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/media_url.dart';
import '../../../../core/widgets/adaptive_scaffold.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../domain/entities/communication.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/communications_provider.dart';
import '../../../providers/staff_navigation_provider.dart';
import '../../../shells/staff_shell.dart';
import '../widgets/voice_note_player.dart';

class CommunicationsHubScreen extends ConsumerStatefulWidget {
  const CommunicationsHubScreen({
    super.key,
    this.routePrefix = '/admin',
    this.navItems = const [],
    this.selectedRoute,
    this.isStudent = false,
    this.isParent = false,
    this.homeRoute,
  });

  final String routePrefix;
  final List<NavItem> navItems;
  final String? selectedRoute;
  final bool isStudent;
  final bool isParent;
  final String? homeRoute;

  @override
  ConsumerState<CommunicationsHubScreen> createState() => _CommunicationsHubScreenState();
}

class _CommunicationsHubScreenState extends ConsumerState<CommunicationsHubScreen> {
  Conversation? _selected;
  final _messageCtrl = TextEditingController();
  final _searchCtrl = TextEditingController();
  final _composerFocus = FocusNode();
  String? _typingLabel;
  Timer? _typingDebounce;
  List<ChatMessage> _liveMessages = [];
  bool _sending = false;
  String _filter = 'all';
  bool _socketBound = false;
  CommunicationsSocket? _socket;
  ChatMessage? _replyTo;
  String _threadSearch = '';
  bool _showThreadFilter = false;
  final _recorder = AudioRecorder();
  bool _recording = false;
  int _recordElapsed = 0;
  Timer? _recordTick;
  UserPresenceInfo? _peerPresence;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initSocket();
      _consumePendingConversation();
      // Refresh badge when opening Messages (clears sticky unread from races).
      ref.invalidate(communicationsUnreadProvider);
      ref.invalidate(conversationsProvider);
    });
  }

  @override
  void dispose() {
    // Clear active chat so toast can show again after leaving Messages.
    try {
      ref.read(activeChatConversationIdProvider.notifier).state = null;
    } catch (_) {}
    if (_socketBound) {
      _socket?.off('message', _onSocketMessage);
      _socket?.off('typing', _onTyping);
      _socket?.off('stop-typing', _onStopTyping);
      _socket?.off('user-online', _onPresenceEvent);
      _socket?.off('user-offline', _onPresenceEvent);
    }
    if (_selected != null) {
      _socket?.leaveRoom(_selected!.id);
    }
    _messageCtrl.dispose();
    _searchCtrl.dispose();
    _composerFocus.dispose();
    _typingDebounce?.cancel();
    _recordTick?.cancel();
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _consumePendingConversation() async {
    final pending = ref.read(pendingOpenConversationIdProvider);
    if (pending == null || pending.isEmpty) return;
    ref.read(pendingOpenConversationIdProvider.notifier).state = null;
    try {
      final list = await ref.read(communicationsApiProvider).listConversations();
      Conversation? match;
      for (final c in list) {
        if (c.id == pending) {
          match = c;
          break;
        }
      }
      match ??= await ref.read(communicationsApiProvider).getConversation(pending);
      if (!mounted) return;
      await _openConversation(match);
    } catch (_) {
      // Ignore — user can open manually.
    }
  }

  Future<void> _initSocket() async {
    final socket = ref.read(communicationsSocketProvider);
    _socket = socket;
    await socket.connect();
    if (_socketBound) return;
    socket.on('message', _onSocketMessage);
    socket.on('typing', _onTyping);
    socket.on('stop-typing', _onStopTyping);
    socket.on('user-online', _onPresenceEvent);
    socket.on('user-offline', _onPresenceEvent);
    _socketBound = true;
  }

  void _onPresenceEvent(dynamic data) {
    if (data is! Map) return;
    final info = UserPresenceInfo.fromJson(Map<String, dynamic>.from(data));
    final peerId = _selected?.peerUserId;
    final peerType = _selected?.peerUserType;
    if (peerId == null || peerType == null) return;
    if (info.userId != peerId || info.userType != peerType) return;
    if (!mounted) return;
    setState(() => _peerPresence = info);
  }

  Future<void> _loadPeerPresence(Conversation c) async {
    final peerId = c.peerUserId;
    final peerType = c.peerUserType;
    if (c.type != 'private' || peerId == null || peerType == null) {
      setState(() => _peerPresence = null);
      return;
    }
    try {
      final presence = await ref.read(communicationsApiProvider).getPresence(
            userId: peerId,
            userType: peerType,
          );
      if (!mounted || _selected?.id != c.id) return;
      setState(() => _peerPresence = presence);
    } catch (_) {
      if (mounted && _selected?.id == c.id) {
        setState(() => _peerPresence = null);
      }
    }
  }

  String _presenceSubtitle(Conversation conv) {
    if (_typingLabel != null) return _typingLabel!;
    if (conv.type == 'private' && _peerPresence != null) {
      if (_peerPresence!.isOnline) return 'online';
      final seen = _peerPresence!.lastSeenAt;
      if (seen == null) return 'offline';
      return 'last seen ${_formatLastSeen(seen)}';
    }
    return '${conv.type} · ${conv.participantCount} members';
  }

  String _formatLastSeen(DateTime at) {
    final local = at.toLocal();
    final now = DateTime.now();
    final diff = now.difference(local);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24 && now.day == local.day) {
      final h = local.hour.toString().padLeft(2, '0');
      final m = local.minute.toString().padLeft(2, '0');
      return 'today at $h:$m';
    }
    if (diff.inDays < 2) {
      final h = local.hour.toString().padLeft(2, '0');
      final m = local.minute.toString().padLeft(2, '0');
      return 'yesterday at $h:$m';
    }
    return '${local.day}/${local.month}/${local.year}';
  }

  Widget _avatar({
    String? imageUrl,
    String? label,
    IconData? fallbackIcon,
    double radius = 20,
  }) {
    final url = resolveMediaUrl(imageUrl);
    final letter = (label ?? '').trim();
    return CircleAvatar(
      radius: radius,
      backgroundImage: url.isNotEmpty ? NetworkImage(url) : null,
      child: url.isNotEmpty
          ? null
          : (fallbackIcon != null
              ? Icon(fallbackIcon, size: radius)
              : Text(
                  letter.isNotEmpty ? letter[0].toUpperCase() : '?',
                  style: TextStyle(fontSize: radius * 0.85, fontWeight: FontWeight.w700),
                )),
    );
  }

  void _onSocketMessage(dynamic data) {
    if (data is! Map) return;
    final msg = ChatMessage.fromJson(Map<String, dynamic>.from(data));
    if (_selected?.id != msg.conversationId) {
      ref.invalidate(conversationsProvider);
      ref.invalidate(communicationsUnreadProvider);
      return;
    }
    setState(() {
      if (!_liveMessages.any((m) => m.id == msg.id || (msg.clientId != null && m.clientId == msg.clientId))) {
        _liveMessages = [..._liveMessages, msg];
      }
    });
    unawaited(() async {
      try {
        await ref.read(communicationsApiProvider).markRead(msg.conversationId);
      } catch (_) {}
      if (!mounted) return;
      ref.invalidate(conversationsProvider);
      ref.invalidate(communicationsUnreadProvider);
    }());
  }

  void _onTyping(dynamic data) {
    if (data is! Map) return;
    final convId = data['conversationId']?.toString();
    if (convId != _selected?.id) return;
    final me = ref.read(authProvider).user;
    if (me != null && data['userId']?.toString() == me.id) return;
    setState(() => _typingLabel = '${data['name'] ?? 'Someone'} is typing…');
  }

  void _onStopTyping(dynamic data) {
    if (data is! Map) return;
    if (data['conversationId']?.toString() != _selected?.id) return;
    setState(() => _typingLabel = null);
  }

  Future<void> _openConversation(Conversation c) async {
    final socket = ref.read(communicationsSocketProvider);
    if (_selected != null) socket.leaveRoom(_selected!.id);
    setState(() {
      _selected = c;
      _liveMessages = [];
      _typingLabel = null;
      _peerPresence = null;
      _threadSearch = '';
    });
    ref.read(activeChatConversationIdProvider.notifier).state = c.id;
    socket.joinRoom(c.id);
    unawaited(_loadPeerPresence(c));
    final messages = await ref.read(communicationsApiProvider).listMessages(c.id);
    if (!mounted) return;
    setState(() => _liveMessages = messages);
    await ref.read(communicationsApiProvider).markRead(c.id);
    ref.invalidate(conversationsProvider);
    ref.invalidate(communicationsUnreadProvider);
  }

  Future<void> _send({String? filePath, String? fileName, DateTime? scheduledAt, int? durationSec}) async {
    final conv = _selected;
    if (conv == null) return;
    final text = _messageCtrl.text.trim();
    if (text.isEmpty && filePath == null) return;
    setState(() => _sending = true);
    try {
      final clientId = DateTime.now().millisecondsSinceEpoch.toString();
      final msg = await ref.read(communicationsApiProvider).sendMessage(
            conv.id,
            body: text,
            clientId: clientId,
            replyToId: _replyTo?.id,
            filePath: filePath,
            fileName: fileName,
            scheduledAt: scheduledAt,
            durationSec: durationSec,
          );
      _messageCtrl.clear();
      ref.read(communicationsSocketProvider).stopTyping(conv.id);
      setState(() {
        _replyTo = null;
        if (!_liveMessages.any((m) => m.id == msg.id)) {
          _liveMessages = [..._liveMessages, msg];
        } else {
          _liveMessages = [
            for (final m in _liveMessages) m.id == msg.id ? msg : m,
          ];
        }
      });
      ref.invalidate(conversationsProvider);
      if (msg.isScheduled && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Scheduled for ${msg.scheduledAt?.toLocal()}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _toggleVoice() async {
    if (_recording) {
      _recordTick?.cancel();
      final path = await _recorder.stop();
      setState(() => _recording = false);
      if (path == null || !File(path).existsSync()) return;
      await _send(filePath: path, fileName: 'voice_note.wav', durationSec: _recordElapsed);
      return;
    }
    final ok = await _recorder.hasPermission();
    if (!ok) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Microphone permission required')),
        );
      }
      return;
    }
    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.wav';
    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.wav, sampleRate: 44100, numChannels: 1),
      path: path,
    );
    _recordElapsed = 0;
    _recordTick?.cancel();
    _recordTick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _recordElapsed += 1);
    });
    setState(() => _recording = true);
  }

  Future<void> _scheduleSend() async {
    final text = _messageCtrl.text.trim();
    if (text.isEmpty || _selected == null) return;
    final when = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      initialDate: DateTime.now().add(const Duration(hours: 1)),
    );
    if (when == null || !mounted) return;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (time == null) return;
    final scheduled = DateTime(when.year, when.month, when.day, time.hour, time.minute);
    await _send(scheduledAt: scheduled);
  }

  Future<void> _createPoll() async {
    final conv = _selected;
    if (conv == null) return;
    final q = TextEditingController();
    var type = 'yes_no';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Chat poll'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: q, decoration: const InputDecoration(labelText: 'Question')),
              DropdownButtonFormField<String>(
                value: type,
                decoration: const InputDecoration(labelText: 'Type'),
                items: const [
                  DropdownMenuItem(value: 'yes_no', child: Text('Yes / No')),
                  DropdownMenuItem(value: 'true_false', child: Text('True / False')),
                  DropdownMenuItem(value: 'rating', child: Text('Rating 1–5')),
                  DropdownMenuItem(value: 'emoji', child: Text('Emoji mood')),
                  DropdownMenuItem(value: 'single', child: Text('Single choice')),
                ],
                onChanged: (v) => setLocal(() => type = v ?? 'yes_no'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Post')),
          ],
        ),
      ),
    );
    if (ok != true || q.text.trim().isEmpty) return;
    try {
      final msg = await ref.read(communicationsApiProvider).createChatPoll(
            conv.id,
            question: q.text.trim(),
            pollType: type,
            options: type == 'single'
                ? [
                    {'label': 'Option A'},
                    {'label': 'Option B'},
                  ]
                : null,
          );
      setState(() => _liveMessages = [..._liveMessages, msg]);
      ref.invalidate(conversationsProvider);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _startCall({String media = 'audio'}) async {
    final conv = _selected;
    if (conv == null) return;
    try {
      final msg = await ref.read(communicationsApiProvider).signalCall(conv.id, media: media);
      setState(() => _liveMessages = [..._liveMessages, msg]);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${media == 'video' ? 'Video' : 'Audio'} call invite sent')),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _messageAction(ChatMessage m) async {
    final me = ref.read(authProvider).user;
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(leading: const Icon(Icons.reply), title: const Text('Reply'), onTap: () => Navigator.pop(ctx, 'reply')),
            ListTile(leading: const Icon(Icons.emoji_emotions_outlined), title: const Text('React 👍'), onTap: () => Navigator.pop(ctx, 'react')),
            ListTile(
              leading: Icon(m.starred ? Icons.star : Icons.star_border),
              title: Text(m.starred ? 'Unstar' : 'Star'),
              onTap: () => Navigator.pop(ctx, 'star'),
            ),
            ListTile(leading: const Icon(Icons.push_pin_outlined), title: const Text('Pin in chat'), onTap: () => Navigator.pop(ctx, 'pin')),
            if (me != null && m.senderId == me.id) ...[
              ListTile(leading: const Icon(Icons.edit), title: const Text('Edit'), onTap: () => Navigator.pop(ctx, 'edit')),
              ListTile(leading: const Icon(Icons.delete_outline), title: const Text('Delete'), onTap: () => Navigator.pop(ctx, 'delete')),
            ],
            ListTile(leading: const Icon(Icons.forward), title: const Text('Forward'), onTap: () => Navigator.pop(ctx, 'forward')),
          ],
        ),
      ),
    );
    if (action == null || _selected == null) return;
    final api = ref.read(communicationsApiProvider);
    try {
      switch (action) {
        case 'reply':
          setState(() => _replyTo = m);
          break;
        case 'react':
          final updated = await api.react(m.id, '👍');
          setState(() => _liveMessages = [for (final x in _liveMessages) x.id == updated.id ? updated : x]);
          break;
        case 'star':
          final updated = await api.star(m.id, starred: !m.starred);
          setState(() => _liveMessages = [for (final x in _liveMessages) x.id == updated.id ? updated : x]);
          break;
        case 'pin':
          await api.pinMessage(_selected!.id, m.id);
          ref.invalidate(conversationsProvider);
          break;
        case 'edit':
          final ctrl = TextEditingController(text: m.body);
          final ok = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Edit message'),
              content: TextField(controller: ctrl, maxLines: 4),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
              ],
            ),
          );
          if (ok == true) {
            final updated = await api.updateMessage(m.id, body: ctrl.text.trim());
            setState(() => _liveMessages = [for (final x in _liveMessages) x.id == updated.id ? updated : x]);
          }
          break;
        case 'delete':
          final updated = await api.updateMessage(m.id, deleted: true);
          setState(() => _liveMessages = [for (final x in _liveMessages) x.id == updated.id ? updated : x]);
          break;
        case 'forward':
          final convs = await api.listConversations();
          if (!mounted) return;
          final target = await showModalBottomSheet<Conversation>(
            context: context,
            builder: (ctx) => ListView(
              children: [
                for (final c in convs.where((c) => c.id != _selected!.id))
                  ListTile(
                    title: Text(c.title.isEmpty ? c.type : c.title),
                    onTap: () => Navigator.pop(ctx, c),
                  ),
              ],
            ),
          );
          if (target != null) {
            await api.forward(m.id, target.id);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Forwarded')));
            }
          }
          break;
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _toggleChat({bool? pinned, bool? muted, bool? archived}) async {
    final conv = _selected;
    if (conv == null) return;
    try {
      final updated = await ref.read(communicationsApiProvider).togglePinMute(
            conv.id,
            pinned: pinned,
            muted: muted,
            archived: archived,
          );
      setState(() => _selected = updated);
      ref.invalidate(conversationsProvider);
      if (archived == true) setState(() => _selected = null);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _globalSearch() async {
    final q = _searchCtrl.text.trim();
    if (q.isEmpty) return;
    try {
      final hits = await ref.read(communicationsApiProvider).search(q: q);
      if (!mounted) return;
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (ctx) => SizedBox(
          height: MediaQuery.sizeOf(ctx).height * 0.7,
          child: ListView(
            children: [
              const ListTile(title: Text('Search results')),
              if (hits.isEmpty) const ListTile(title: Text('No messages found')),
              for (final m in hits)
                ListTile(
                  title: Text(m.body, maxLines: 2, overflow: TextOverflow.ellipsis),
                  subtitle: Text(m.conversationId),
                  onTap: () async {
                    Navigator.pop(ctx);
                    final conv = await ref.read(communicationsApiProvider).getConversation(m.conversationId);
                    await _openConversation(conv);
                  },
                ),
            ],
          ),
        ),
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  void _onComposerChanged(String value) {
    final conv = _selected;
    if (conv == null) return;
    ref.read(communicationsSocketProvider).typing(conv.id);
    _typingDebounce?.cancel();
    _typingDebounce = Timer(const Duration(seconds: 2), () {
      ref.read(communicationsSocketProvider).stopTyping(conv.id);
    });
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(withData: false);
    if (result == null || result.files.isEmpty) return;
    final f = result.files.single;
    if (f.path == null) return;
    await _send(filePath: f.path, fileName: f.name);
  }

  Future<void> _startNewChat() async {
    try {
      final searchCtrl = TextEditingController(text: _searchCtrl.text.trim());
      List<DirectoryUser> users = await ref.read(communicationsApiProvider).directory(
            search: searchCtrl.text.trim(),
          );
      if (!mounted) return;
      final picked = await showModalBottomSheet<DirectoryUser>(
        context: context,
        isScrollControlled: true,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setSheet) {
            Future<void> runSearch(String q) async {
              final next = await ref.read(communicationsApiProvider).directory(search: q.trim());
              if (ctx.mounted) setSheet(() => users = next);
            }

            return SizedBox(
              height: MediaQuery.sizeOf(ctx).height * 0.75,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text('Start chat', style: Theme.of(ctx).textTheme.titleMedium),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      controller: searchCtrl,
                      decoration: const InputDecoration(
                        hintText: 'Search teacher or student…',
                        prefixIcon: Icon(Icons.search),
                        isDense: true,
                      ),
                      onChanged: (q) {
                        // Debounce lightly via microtask batching on each keystroke is fine for directory.
                        runSearch(q);
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: users.isEmpty
                        ? const Center(child: Text('No contacts found'))
                        : ListView.builder(
                            itemCount: users.length,
                            itemBuilder: (_, i) {
                              final u = users[i];
                              return ListTile(
                                leading: _avatar(
                                  imageUrl: u.profileImage,
                                  label: u.firstName,
                                ),
                                title: Text(u.firstName),
                                subtitle: Text(
                                  [
                                    u.userType,
                                    if (u.role != null && u.role!.isNotEmpty) u.role,
                                    if (u.name.trim().contains(' ')) u.name,
                                  ].join(' · '),
                                ),
                                onTap: () => Navigator.pop(ctx, u),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        ),
      );
      searchCtrl.dispose();
      if (picked == null) return;
      final conv = await ref.read(communicationsApiProvider).createPrivate(
            targetUserId: picked.id,
            targetUserType: picked.userType,
          );
      ref.invalidate(conversationsProvider);
      await _openConversation(conv);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  Future<void> _support() async {
    try {
      final conv = await ref.read(communicationsApiProvider).createSupport();
      ref.invalidate(conversationsProvider);
      await _openConversation(conv);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  Future<void> _broadcast() async {
    final title = TextEditingController(text: 'Announcement');
    final body = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Broadcast'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: title, decoration: const InputDecoration(labelText: 'Title')),
            TextField(controller: body, decoration: const InputDecoration(labelText: 'Message'), maxLines: 4),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Send')),
        ],
      ),
    );
    if (ok != true || body.text.trim().isEmpty) return;
    try {
      final conv = await ref.read(communicationsApiProvider).createBroadcast(
            title: title.text.trim(),
            body: body.text.trim(),
          );
      ref.invalidate(conversationsProvider);
      await _openConversation(conv);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  Future<void> _createSubjectRoom() async {
    try {
      final subjects = await ref.read(communicationsApiProvider).listSubjectOptions();
      if (!mounted) return;
      if (subjects.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No subjects found for a discussion room')),
        );
        return;
      }
      final picked = await showModalBottomSheet<({String id, String name})>(
        context: context,
        isScrollControlled: true,
        builder: (ctx) => SizedBox(
          height: MediaQuery.sizeOf(ctx).height * 0.6,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Subject discussion room', style: Theme.of(ctx).textTheme.titleMedium),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: subjects.length,
                  itemBuilder: (_, i) {
                    final s = subjects[i];
                    return ListTile(
                      leading: const Icon(Icons.menu_book_outlined),
                      title: Text(s.name),
                      onTap: () => Navigator.pop(ctx, s),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
      if (picked == null) return;
      final conv = await ref.read(communicationsApiProvider).createSubjectRoom(subjectId: picked.id);
      ref.invalidate(conversationsProvider);
      await _openConversation(conv);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(conversationsProvider);
    final me = ref.watch(authProvider).user;
    final rolePerms = ref.watch(staffRolePermissionsProvider);
    final limitedChat = widget.isStudent || widget.isParent;
    final canBroadcast = !limitedChat &&
        (me?.hasFullStaffAccess == true || me?.hasPermission('canBroadcast', rolePerms) == true);
    final messagesRoute = '${widget.routePrefix}/messages';

    Widget chatToolbar() {
      return Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.sm, AppSpacing.sm, AppSpacing.sm, 4),
        child: Row(
          children: [
            Text(
              context.l10n.chats,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const Spacer(),
            if (limitedChat)
              IconButton(
                tooltip: context.l10n.support,
                visualDensity: VisualDensity.compact,
                onPressed: _support,
                icon: const Icon(Icons.support_agent, size: 20),
              ),
            if (!limitedChat)
              IconButton(
                tooltip: context.l10n.subjectRoom,
                visualDensity: VisualDensity.compact,
                onPressed: _createSubjectRoom,
                icon: const Icon(Icons.menu_book_outlined, size: 20),
              ),
            if (!limitedChat)
              IconButton(
                tooltip: context.l10n.moderation,
                visualDensity: VisualDensity.compact,
                onPressed: () => context.go('${widget.routePrefix}/messages/moderation'),
                icon: const Icon(Icons.gavel_outlined, size: 20),
              ),
            if (canBroadcast)
              IconButton(
                tooltip: context.l10n.broadcast,
                visualDensity: VisualDensity.compact,
                onPressed: _broadcast,
                icon: const Icon(Icons.campaign_outlined, size: 20),
              ),
            if (!widget.isParent)
              IconButton(
                tooltip: context.l10n.newChat,
                visualDensity: VisualDensity.compact,
                onPressed: _startNewChat,
                icon: const Icon(Icons.edit_square, size: 20),
              ),
          ],
        ),
      );
    }

    Widget chatTile(Conversation c, {required bool selected}) {
      final scheme = Theme.of(context).colorScheme;
      final muted = context.semantic.textMuted;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: Material(
          color: selected ? scheme.onSurface.withValues(alpha: 0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: () => _openConversation(c),
            borderRadius: BorderRadius.circular(12),
            hoverColor: scheme.onSurface.withValues(alpha: 0.05),
            splashColor: scheme.onSurface.withValues(alpha: 0.08),
            highlightColor: scheme.onSurface.withValues(alpha: 0.06),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              child: Row(
                children: [
                  _avatar(
                    imageUrl: c.avatarUrl,
                    label: c.title,
                    fallbackIcon: c.type == 'private' ? null : _iconForType(c.type),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          c.title.isEmpty ? c.type : c.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          c.lastMessagePreview,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: muted),
                        ),
                      ],
                    ),
                  ),
                  if (c.unreadCount > 0) ...[
                    const SizedBox(width: 8),
                    Badge(label: Text('${c.unreadCount}')),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
    }

    Widget listPane() {
      return async.when(
        loading: () => const LoadingState(message: 'Loading chats…'),
        error: (e, _) => ErrorState(
          message: e.toString(),
          onRetry: () => ref.invalidate(conversationsProvider),
        ),
        data: (items) {
          var filtered = items;
          if (_filter == 'groups') filtered = items.where((c) => c.type == 'group').toList();
          if (_filter == 'subject') filtered = items.where((c) => c.type == 'subject').toList();
          if (_filter == 'broadcast') filtered = items.where((c) => c.type == 'broadcast').toList();
          if (_filter == 'support') filtered = items.where((c) => c.type == 'support').toList();
          if (_filter == 'private') filtered = items.where((c) => c.type == 'private').toList();
          final q = _searchCtrl.text.trim().toLowerCase();
          if (q.isNotEmpty) {
            filtered = filtered
                .where((c) => c.title.toLowerCase().contains(q) || c.lastMessagePreview.toLowerCase().contains(q))
                .toList();
          }

          return ColoredBox(
            color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.55),
            child: Column(
              children: [
                chatToolbar(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.sm, 0, AppSpacing.sm, AppSpacing.sm),
                  child: TextField(
                    controller: _searchCtrl,
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search, size: 18),
                      hintText: context.l10n.searchChats,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      suffixIcon: IconButton(
                        tooltip: context.l10n.searchMessages,
                        icon: const Icon(Icons.manage_search, size: 18),
                        onPressed: _globalSearch,
                      ),
                    ),
                    onChanged: (_) => setState(() {}),
                    onSubmitted: (_) => _globalSearch(),
                  ),
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                  child: Row(
                    children: [
                      for (final f in [
                        ('all', context.l10n.filterRecent),
                        ('private', context.l10n.filterDirect),
                        ('groups', context.l10n.navGroups),
                        ('subject', context.l10n.filterSubjects),
                        ('broadcast', context.l10n.broadcast),
                        ('support', context.l10n.support),
                      ])
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: FilterChip(
                            label: Text(f.$2, style: const TextStyle(fontSize: 12)),
                            selected: _filter == f.$1,
                            visualDensity: VisualDensity.compact,
                            onSelected: (_) => setState(() => _filter = f.$1),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Expanded(
                  child: filtered.isEmpty
                      ? EmptyState(title: context.l10n.noChatsYet, message: context.l10n.noChatsMessage)
                      : ListView.builder(
                          padding: const EdgeInsets.only(bottom: AppSpacing.md),
                          itemCount: filtered.length,
                          itemBuilder: (context, i) {
                            final c = filtered[i];
                            return chatTile(c, selected: _selected?.id == c.id);
                          },
                        ),
                ),
              ],
            ),
          );
        },
      );
    }

    Widget threadPane() {
      final conv = _selected;
      if (conv == null) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.forum_outlined, size: 48, color: context.semantic.textMuted.withValues(alpha: 0.45)),
              const SizedBox(height: 12),
              Text(
                'Select a chat',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                'Pick a conversation from the list',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: context.semantic.textMuted),
              ),
            ],
          ),
        );
      }
      final canReply = conv.type != 'broadcast' || conv.allowReplies || !limitedChat;
      final visibleMessages = _threadSearch.trim().isEmpty
          ? _liveMessages
          : _liveMessages
              .where((m) => m.body.toLowerCase().contains(_threadSearch.trim().toLowerCase()))
              .toList();
      return Column(
        children: [
          ListTile(
            leading: _avatar(
              imageUrl: conv.avatarUrl,
              label: conv.title,
              fallbackIcon: conv.type == 'private' ? null : _iconForType(conv.type),
            ),
            title: Text(conv.title.isEmpty ? conv.type : conv.title),
            subtitle: Text(_presenceSubtitle(conv)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: _showThreadFilter ? 'Hide filter' : 'Filter in thread',
                  onPressed: () => setState(() {
                    _showThreadFilter = !_showThreadFilter;
                    if (!_showThreadFilter) _threadSearch = '';
                  }),
                  icon: Icon(_showThreadFilter ? Icons.filter_list_off : Icons.filter_list),
                ),
                IconButton(
                  tooltip: conv.pinned ? 'Unpin' : 'Pin',
                  onPressed: () => _toggleChat(pinned: !conv.pinned),
                  icon: Icon(conv.pinned ? Icons.push_pin : Icons.push_pin_outlined),
                ),
                IconButton(
                  tooltip: conv.muted ? 'Unmute' : 'Mute',
                  onPressed: () => _toggleChat(muted: !conv.muted),
                  icon: Icon(conv.muted ? Icons.notifications_off : Icons.notifications_outlined),
                ),
                PopupMenuButton<String>(
                  onSelected: (v) {
                    if (v == 'archive') _toggleChat(archived: true);
                    if (v == 'refresh') _openConversation(conv);
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'refresh', child: Text('Refresh')),
                    PopupMenuItem(value: 'archive', child: Text('Archive')),
                  ],
                ),
              ],
            ),
          ),
          if (_showThreadFilter)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'Filter in thread…',
                  isDense: true,
                  prefixIcon: Icon(Icons.search, size: 18),
                ),
                onChanged: (v) => setState(() => _threadSearch = v),
              ),
            ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: visibleMessages.length,
              itemBuilder: (context, i) {
                final m = visibleMessages[i];
                final mine = me != null && m.senderId == me.id;
                final showSenderMeta = !mine;
                return Align(
                  alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                  child: GestureDetector(
                    onLongPress: () => _messageAction(m),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (showSenderMeta) ...[
                          _avatar(
                            imageUrl: m.senderProfileImage,
                            label: m.displayFirstName,
                            radius: 14,
                          ),
                          const SizedBox(width: 8),
                        ],
                        Flexible(
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.72),
                            decoration: BoxDecoration(
                              color: mine
                                  ? AppColors.primary.withValues(alpha: 0.25)
                                  : Theme.of(context).colorScheme.surfaceContainerHighest,
                              borderRadius: AppRadius.card,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (showSenderMeta)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: Text(
                                      m.displayFirstName,
                                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.primary,
                                          ),
                                    ),
                                  ),
                                if (m.replyToId != null)
                                  Text('↩ reply', style: Theme.of(context).textTheme.labelSmall),
                                if (m.forwardFromId != null)
                                  Text('↪ forwarded', style: Theme.of(context).textTheme.labelSmall),
                                if (m.isDeleted)
                                  Text(
                                    'Message deleted',
                                    style: TextStyle(fontStyle: FontStyle.italic, color: context.semantic.textMuted),
                                  )
                                else ...[
                                  if (m.isScheduled)
                                    Text(
                                      'Scheduled · ${m.scheduledAt?.toLocal()}',
                                      style: Theme.of(context).textTheme.labelSmall,
                                    ),
                                  if (m.messageType == 'call')
                                    Text(m.body.isEmpty ? '📞 Call' : m.body),
                                  if (m.body.isNotEmpty && m.messageType != 'call') Text(m.body),
                                  if (m.mentions.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Wrap(
                                        spacing: 4,
                                        children: [
                                          for (final mention in m.mentions)
                                            Chip(
                                              avatar: const Icon(Icons.alternate_email, size: 14),
                                              label: Text(mention.name.isEmpty ? mention.userType : mention.name),
                                              visualDensity: VisualDensity.compact,
                                              padding: EdgeInsets.zero,
                                            ),
                                        ],
                                      ),
                                    ),
                                  for (final a in m.attachments)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 6),
                                      child: a.kind == 'image'
                                          ? Image.network(
                                              resolveMediaUrl(a.url),
                                              height: 140,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) => Text(a.name.isEmpty ? 'Image' : a.name),
                                            )
                                          : a.kind == 'audio'
                                              ? VoiceNotePlayer(url: a.url, durationSec: a.durationSec)
                                              : Text('📎 ${a.name.isEmpty ? a.url : a.name}'),
                                    ),
                                ],
                                if (m.reactions.isNotEmpty)
                                  Wrap(
                                    spacing: 4,
                                    children: [
                                      for (final e in m.reactions.entries)
                                        Chip(
                                          label: Text('${e.key} ${e.value}'),
                                          visualDensity: VisualDensity.compact,
                                          padding: EdgeInsets.zero,
                                        ),
                                    ],
                                  ),
                                const SizedBox(height: 4),
                                Text(
                                  [
                                    m.status,
                                    if (m.editedAt != null) 'edited',
                                    if (m.starred) '★',
                                  ].join(' · '),
                                  style: Theme.of(context).textTheme.labelSmall?.copyWith(color: context.semantic.textMuted),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          if (_typingLabel != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(_typingLabel!, style: Theme.of(context).textTheme.bodySmall),
              ),
            ),
          if (_replyTo != null)
            Material(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: ListTile(
                dense: true,
                title: Text('Replying to: ${_replyTo!.body}', maxLines: 1, overflow: TextOverflow.ellipsis),
                trailing: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => setState(() => _replyTo = null),
                ),
              ),
            ),
          if (canReply)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: _recording ? 'Stop & send ($_recordElapsed s)' : 'Voice note',
                      onPressed: _sending ? null : _toggleVoice,
                      icon: Icon(
                        _recording ? Icons.stop_circle : Icons.mic_none,
                        color: _recording ? Colors.red : null,
                      ),
                    ),
                    IconButton(onPressed: _sending ? null : _pickFile, icon: const Icon(Icons.attach_file)),
                    PopupMenuButton<String>(
                      tooltip: 'More',
                      onSelected: (v) {
                        if (v == 'schedule') _scheduleSend();
                        if (v == 'poll') _createPoll();
                        if (v == 'audio') _startCall(media: 'audio');
                        if (v == 'video') _startCall(media: 'video');
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'schedule', child: Text('Schedule send')),
                        PopupMenuItem(value: 'poll', child: Text('Create poll')),
                        PopupMenuItem(value: 'audio', child: Text('Audio call invite')),
                        PopupMenuItem(value: 'video', child: Text('Video call invite')),
                      ],
                      icon: const Icon(Icons.more_horiz),
                    ),
                    Expanded(
                      child: Focus(
                        onKeyEvent: (node, event) {
                          if (event is! KeyDownEvent) return KeyEventResult.ignored;
                          if (event.logicalKey != LogicalKeyboardKey.enter &&
                              event.logicalKey != LogicalKeyboardKey.numpadEnter) {
                            return KeyEventResult.ignored;
                          }
                          // Shift+Enter keeps a newline; Enter sends.
                          if (HardwareKeyboard.instance.isShiftPressed) {
                            return KeyEventResult.ignored;
                          }
                          _send();
                          return KeyEventResult.handled;
                        },
                        child: TextField(
                          focusNode: _composerFocus,
                          controller: _messageCtrl,
                          onChanged: _onComposerChanged,
                          decoration: InputDecoration(
                            hintText: _recording ? context.l10n.recording : context.l10n.messageHint,
                            isDense: true,
                          ),
                          minLines: 1,
                          maxLines: 4,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _send(),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _sending ? null : () => _send(),
                      icon: _sending
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.send),
                    ),
                  ],
                ),
              ),
            )
          else
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text('Replies are disabled on this broadcast.'),
            ),
        ],
      );
    }

    final wide = MediaQuery.sizeOf(context).width >= 900;
    // Conversation takes the main stage; chat list docks on the right.
    final body = wide
        ? Row(
            children: [
              Expanded(child: threadPane()),
              const VerticalDivider(width: 1),
              SizedBox(width: 340, child: listPane()),
            ],
          )
        : (_selected == null
            ? listPane()
            : Column(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () {
                        if (_selected != null) {
                          ref.read(communicationsSocketProvider).leaveRoom(_selected!.id);
                        }
                        setState(() => _selected = null);
                      },
                      icon: const Icon(Icons.arrow_back),
                      label: Text(context.l10n.chats),
                    ),
                  ),
                  Expanded(child: threadPane()),
                ],
              ));

    if (widget.isStudent || widget.isParent) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(''),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go(
              widget.homeRoute ??
                  (widget.isParent ? '/parent/home' : '${widget.routePrefix}/dashboard'),
            ),
          ),
        ),
        body: body,
      );
    }

    if (widget.routePrefix == '/teacher') {
      final items = widget.navItems;
      final selected = widget.selectedRoute ?? messagesRoute;
      final selectedIndex = items.indexWhere((i) => i.route == selected);
      return AdaptiveScaffold(
        title: '',
        selectedIndex: selectedIndex < 0 ? 0 : selectedIndex,
        selectedRoute: selected,
        items: items,
        onDestinationSelected: (i) => context.go(items[i].route),
        body: body,
      );
    }

    final items = widget.navItems.isNotEmpty
        ? widget.navItems
        : (widget.routePrefix.startsWith('/founder') ? founderNavItems : adminNavItems);
    final selected = widget.selectedRoute ?? messagesRoute;
    final selectedIndex = items.indexWhere((i) => selected.startsWith(i.route) || i.route.contains('/messages'));

    return AdaptiveScaffold(
      title: '',
      selectedIndex: selectedIndex < 0 ? 0 : selectedIndex,
      selectedRoute: selected,
      items: items,
      onDestinationSelected: (i) => context.go(items[i].route),
      body: body,
    );
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'subject':
        return Icons.menu_book_outlined;
      case 'group':
        return Icons.groups_outlined;
      case 'broadcast':
        return Icons.campaign_outlined;
      case 'support':
        return Icons.support_agent;
      default:
        return Icons.chat_bubble_outline;
    }
  }
}
