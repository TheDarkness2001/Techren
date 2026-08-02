class ChatAttachment {
  const ChatAttachment({
    required this.url,
    this.kind = 'file',
    this.name = '',
    this.mime = '',
    this.size = 0,
    this.durationSec = 0,
  });

  final String url;
  final String kind;
  final String name;
  final String mime;
  final int size;
  final int durationSec;

  factory ChatAttachment.fromJson(Map<String, dynamic> json) => ChatAttachment(
        url: json['url']?.toString() ?? '',
        kind: json['kind']?.toString() ?? 'file',
        name: json['name']?.toString() ?? '',
        mime: json['mime']?.toString() ?? '',
        size: (json['size'] as num?)?.toInt() ?? 0,
        durationSec: (json['durationSec'] as num?)?.toInt() ?? 0,
      );
}

class ChatParticipant {
  const ChatParticipant({
    required this.userId,
    required this.userType,
    this.role = 'member',
  });

  final String userId;
  final String userType;
  final String role;

  factory ChatParticipant.fromJson(Map<String, dynamic> json) => ChatParticipant(
        userId: json['userId']?.toString() ?? '',
        userType: json['userType']?.toString() ?? 'teacher',
        role: json['role']?.toString() ?? 'member',
      );
}

class ChatMention {
  const ChatMention({required this.userId, required this.userType, this.name = ''});

  final String userId;
  final String userType;
  final String name;

  factory ChatMention.fromJson(Map<String, dynamic> json) => ChatMention(
        userId: json['userId']?.toString() ?? '',
        userType: json['userType']?.toString() ?? 'teacher',
        name: json['name']?.toString() ?? '',
      );
}

class Conversation {
  const Conversation({
    required this.id,
    required this.type,
    this.title = '',
    this.description = '',
    this.avatarUrl,
    this.examGroupId,
    this.subjectId,
    this.allowReplies = true,
    this.archived = false,
    this.pinned = false,
    this.muted = false,
    this.lastMessageAt,
    this.lastMessagePreview = '',
    this.participantCount = 0,
    this.participants = const [],
    this.unreadCount = 0,
    this.pinnedMessageId,
  });

  final String id;
  final String type;
  final String title;
  final String description;
  final String? avatarUrl;
  final String? examGroupId;
  final String? subjectId;
  final bool allowReplies;
  final bool archived;
  final bool pinned;
  final bool muted;
  final DateTime? lastMessageAt;
  final String lastMessagePreview;
  final int participantCount;
  final List<ChatParticipant> participants;
  final int unreadCount;
  final String? pinnedMessageId;

  factory Conversation.fromJson(Map<String, dynamic> json) => Conversation(
        id: json['id']?.toString() ?? '',
        type: json['type']?.toString() ?? 'private',
        title: json['title']?.toString() ?? '',
        description: json['description']?.toString() ?? '',
        avatarUrl: json['avatarUrl']?.toString(),
        examGroupId: json['examGroupId']?.toString(),
        subjectId: json['subjectId']?.toString(),
        allowReplies: json['allowReplies'] != false,
        archived: json['archived'] == true,
        pinned: json['pinned'] == true,
        muted: json['muted'] == true,
        lastMessageAt: json['lastMessageAt'] != null
            ? DateTime.tryParse(json['lastMessageAt'].toString())
            : null,
        lastMessagePreview: json['lastMessagePreview']?.toString() ?? '',
        participantCount: (json['participantCount'] as num?)?.toInt() ?? 0,
        participants: (json['participants'] as List<dynamic>? ?? [])
            .whereType<Map>()
            .map((e) => ChatParticipant.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
        unreadCount: (json['unreadCount'] as num?)?.toInt() ?? 0,
        pinnedMessageId: json['pinnedMessageId']?.toString(),
      );

  Conversation copyWith({int? unreadCount, String? lastMessagePreview, DateTime? lastMessageAt}) =>
      Conversation(
        id: id,
        type: type,
        title: title,
        description: description,
        avatarUrl: avatarUrl,
        examGroupId: examGroupId,
        subjectId: subjectId,
        allowReplies: allowReplies,
        archived: archived,
        pinned: pinned,
        muted: muted,
        lastMessageAt: lastMessageAt ?? this.lastMessageAt,
        lastMessagePreview: lastMessagePreview ?? this.lastMessagePreview,
        participantCount: participantCount,
        participants: participants,
        unreadCount: unreadCount ?? this.unreadCount,
        pinnedMessageId: pinnedMessageId,
      );
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderType,
    this.body = '',
    this.attachments = const [],
    this.replyToId,
    this.forwardFromId,
    this.reactions = const {},
    this.myReactions = const [],
    this.mentions = const [],
    this.starred = false,
    this.status = 'sent',
    this.messageType = 'text',
    this.pollId,
    this.scheduledAt,
    this.callPayload,
    this.clientId,
    this.createdAt,
    this.editedAt,
    this.deletedAt,
  });

  final String id;
  final String conversationId;
  final String senderId;
  final String senderType;
  final String body;
  final List<ChatAttachment> attachments;
  final String? replyToId;
  final String? forwardFromId;
  final Map<String, int> reactions;
  final List<String> myReactions;
  final List<ChatMention> mentions;
  final bool starred;
  final String status;
  final String messageType;
  final String? pollId;
  final DateTime? scheduledAt;
  final Map<String, dynamic>? callPayload;
  final String? clientId;
  final DateTime? createdAt;
  final DateTime? editedAt;
  final DateTime? deletedAt;

  bool get isDeleted => status == 'deleted' || deletedAt != null;
  bool get isScheduled => status == 'scheduled';

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    final rawReactions = json['reactions'];
    final map = <String, int>{};
    if (rawReactions is Map) {
      rawReactions.forEach((k, v) => map[k.toString()] = (v as num?)?.toInt() ?? 0);
    }
    final call = json['callPayload'];
    return ChatMessage(
      id: json['id']?.toString() ?? '',
      conversationId: json['conversationId']?.toString() ?? '',
      senderId: json['senderId']?.toString() ?? '',
      senderType: json['senderType']?.toString() ?? 'teacher',
      body: json['body']?.toString() ?? '',
      attachments: (json['attachments'] as List<dynamic>? ?? [])
          .whereType<Map>()
          .map((e) => ChatAttachment.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      replyToId: json['replyToId']?.toString(),
      forwardFromId: json['forwardFromId']?.toString(),
      reactions: map,
      myReactions: (json['myReactions'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
      mentions: (json['mentions'] as List<dynamic>? ?? [])
          .whereType<Map>()
          .map((e) => ChatMention.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      starred: json['starred'] == true,
      status: json['status']?.toString() ?? 'sent',
      messageType: json['messageType']?.toString() ?? 'text',
      pollId: json['pollId']?.toString(),
      scheduledAt: json['scheduledAt'] != null ? DateTime.tryParse(json['scheduledAt'].toString()) : null,
      callPayload: call is Map ? Map<String, dynamic>.from(call) : null,
      clientId: json['clientId']?.toString(),
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
      editedAt: json['editedAt'] != null ? DateTime.tryParse(json['editedAt'].toString()) : null,
      deletedAt: json['deletedAt'] != null ? DateTime.tryParse(json['deletedAt'].toString()) : null,
    );
  }
}

class DirectoryUser {
  const DirectoryUser({
    required this.id,
    required this.userType,
    required this.name,
    this.email,
    this.phone,
    this.role,
    this.profileImage,
  });

  final String id;
  final String userType;
  final String name;
  final String? email;
  final String? phone;
  final String? role;
  final String? profileImage;

  factory DirectoryUser.fromJson(Map<String, dynamic> json) => DirectoryUser(
        id: json['id']?.toString() ?? '',
        userType: json['userType']?.toString() ?? 'teacher',
        name: json['name']?.toString() ?? '',
        email: json['email']?.toString(),
        phone: json['phone']?.toString(),
        role: json['role']?.toString(),
        profileImage: json['profileImage']?.toString(),
      );
}
