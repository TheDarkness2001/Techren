import 'paginated_result.dart';

class AppNotification {
  const AppNotification({
    required this.id,
    required this.userId,
    required this.userType,
    this.studentId,
    required this.title,
    required this.body,
    required this.eventType,
    required this.channel,
    required this.date,
    this.data,
    this.readAt,
    this.pushStatus,
    this.createdAt,
  });

  final String id;
  final String userId;
  final String userType;
  final String? studentId;
  final String title;
  final String body;
  final String eventType;
  final String channel;
  final String date;
  final Map<String, dynamic>? data;
  final DateTime? readAt;
  final String? pushStatus;
  final DateTime? createdAt;

  bool get isRead => readAt != null;

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String,
      userId: (json['userId'] ?? '').toString(),
      userType: json['userType'] as String? ?? 'student',
      studentId: json['studentId']?.toString(),
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      eventType: json['eventType'] as String? ?? '',
      channel: json['channel'] as String? ?? 'in_app',
      date: json['date'] as String? ?? '',
      data: json['data'] as Map<String, dynamic>?,
      readAt: json['readAt'] != null ? DateTime.tryParse(json['readAt'].toString()) : null,
      pushStatus: json['pushStatus'] as String?,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
    );
  }
}

class NotificationInbox {
  const NotificationInbox({
    required this.notifications,
    required this.unreadCount,
    this.page = 1,
    this.limit = 20,
    this.total = 0,
    this.totalPages = 1,
  });

  final List<AppNotification> notifications;
  final int unreadCount;
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  bool get hasMore => page < totalPages;

  PaginatedResult<AppNotification> get paginated => PaginatedResult(
        items: notifications,
        page: page,
        limit: limit,
        total: total,
        totalPages: totalPages,
      );

  factory NotificationInbox.fromJson(Map<String, dynamic> json) {
    final meta = json['meta'] as Map<String, dynamic>? ?? {};
    return NotificationInbox(
      notifications: (json['notifications'] as List<dynamic>? ?? [])
          .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
          .toList(),
      unreadCount: json['unreadCount'] as int? ?? 0,
      page: meta['page'] as int? ?? 1,
      limit: meta['limit'] as int? ?? 20,
      total: meta['total'] as int? ?? (json['notifications'] as List<dynamic>? ?? []).length,
      totalPages: meta['totalPages'] as int? ?? 1,
    );
  }
}

class ParentNotificationSettings {
  const ParentNotificationSettings({
    required this.studentId,
    required this.channels,
    required this.events,
    required this.quietHoursStart,
    required this.quietHoursEnd,
    required this.timezone,
  });

  final String studentId;
  final NotificationChannels channels;
  final NotificationEvents events;
  final String quietHoursStart;
  final String quietHoursEnd;
  final String timezone;

  factory ParentNotificationSettings.fromJson(Map<String, dynamic> json) {
    return ParentNotificationSettings(
      studentId: (json['studentId'] ?? '').toString(),
      channels: NotificationChannels.fromJson(json['channels'] as Map<String, dynamic>? ?? {}),
      events: NotificationEvents.fromJson(json['events'] as Map<String, dynamic>? ?? {}),
      quietHoursStart: json['quietHoursStart'] as String? ?? '22:00',
      quietHoursEnd: json['quietHoursEnd'] as String? ?? '08:00',
      timezone: json['timezone'] as String? ?? 'Asia/Tashkent',
    );
  }

  Map<String, dynamic> toJson() => {
        'channels': channels.toJson(),
        'events': events.toJson(),
        'quietHoursStart': quietHoursStart,
        'quietHoursEnd': quietHoursEnd,
        'timezone': timezone,
      };
}

class NotificationChannels {
  const NotificationChannels({required this.push, required this.inApp});

  final bool push;
  final bool inApp;

  factory NotificationChannels.fromJson(Map<String, dynamic> json) {
    return NotificationChannels(
      push: json['push'] as bool? ?? true,
      inApp: json['inApp'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {'push': push, 'inApp': inApp};
}

class NotificationEvents {
  const NotificationEvents({
    required this.feedback,
    required this.attendance,
    required this.payment,
    required this.exam,
  });

  final bool feedback;
  final bool attendance;
  final bool payment;
  final bool exam;

  factory NotificationEvents.fromJson(Map<String, dynamic> json) {
    return NotificationEvents(
      feedback: json['feedback'] as bool? ?? true,
      attendance: json['attendance'] as bool? ?? true,
      payment: json['payment'] as bool? ?? true,
      exam: json['exam'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'feedback': feedback,
        'attendance': attendance,
        'payment': payment,
        'exam': exam,
      };
}
