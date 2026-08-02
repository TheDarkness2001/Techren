class NewsMedia {
  const NewsMedia({
    required this.url,
    this.mime = '',
    this.name = '',
    this.size = 0,
    this.kind = 'file',
  });

  final String url;
  final String mime;
  final String name;
  final int size;
  final String kind;

  factory NewsMedia.fromJson(Map<String, dynamic> json) => NewsMedia(
        url: json['url']?.toString() ?? '',
        mime: json['mime']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        size: (json['size'] as num?)?.toInt() ?? 0,
        kind: json['kind']?.toString() ?? 'file',
      );

  Map<String, dynamic> toJson() => {
        'url': url,
        'mime': mime,
        'name': name,
        'size': size,
        'kind': kind,
      };
}

class NewsLink {
  const NewsLink({
    required this.url,
    this.provider = '',
    this.previewTitle = '',
    this.previewImage = '',
    this.previewDesc = '',
  });

  final String url;
  final String provider;
  final String previewTitle;
  final String previewImage;
  final String previewDesc;

  factory NewsLink.fromJson(Map<String, dynamic> json) => NewsLink(
        url: json['url']?.toString() ?? '',
        provider: json['provider']?.toString() ?? '',
        previewTitle: json['previewTitle']?.toString() ?? '',
        previewImage: json['previewImage']?.toString() ?? '',
        previewDesc: json['previewDesc']?.toString() ?? '',
      );

  Map<String, dynamic> toJson() => {
        'url': url,
        'provider': provider,
        'previewTitle': previewTitle,
        'previewImage': previewImage,
        'previewDesc': previewDesc,
      };
}

class NewsAudience {
  const NewsAudience({
    this.mode = 'everyone',
    this.roles = const [],
    this.subjectIds = const [],
    this.examGroupIds = const [],
    this.branchIds = const [],
  });

  final String mode;
  final List<String> roles;
  final List<String> subjectIds;
  final List<String> examGroupIds;
  final List<String> branchIds;

  factory NewsAudience.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const NewsAudience();
    return NewsAudience(
      mode: json['mode']?.toString() ?? 'everyone',
      roles: (json['roles'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
      subjectIds: (json['subjectIds'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
      examGroupIds: (json['examGroupIds'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
      branchIds: (json['branchIds'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'mode': mode,
        'roles': roles,
        'subjectIds': subjectIds,
        'examGroupIds': examGroupIds,
        'branchIds': branchIds,
      };
}

class NewsEventInfo {
  const NewsEventInfo({
    this.startsAt,
    this.endsAt,
    this.location = '',
    this.joinUrl = '',
    this.registrationUrl = '',
    this.registrationCount = 0,
    this.registered = false,
  });

  final DateTime? startsAt;
  final DateTime? endsAt;
  final String location;
  final String joinUrl;
  final String registrationUrl;
  final int registrationCount;
  final bool registered;

  factory NewsEventInfo.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const NewsEventInfo();
    final regs = json['registrations'] as List<dynamic>? ?? [];
    final count = (json['registrationCount'] as num?)?.toInt() ?? regs.length;
    return NewsEventInfo(
      startsAt: json['startsAt'] != null ? DateTime.tryParse(json['startsAt'].toString()) : null,
      endsAt: json['endsAt'] != null ? DateTime.tryParse(json['endsAt'].toString()) : null,
      location: json['location']?.toString() ?? '',
      joinUrl: json['joinUrl']?.toString() ?? '',
      registrationUrl: json['registrationUrl']?.toString() ?? '',
      registrationCount: count,
      registered: json['registered'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        if (startsAt != null) 'startsAt': startsAt!.toIso8601String(),
        if (endsAt != null) 'endsAt': endsAt!.toIso8601String(),
        'location': location,
        'joinUrl': joinUrl,
        'registrationUrl': registrationUrl,
      };
}

class NewsStats {
  const NewsStats({
    this.views = 0,
    this.clicks = 0,
    this.commentCount = 0,
    this.reactionCounts = const {},
  });

  final int views;
  final int clicks;
  final int commentCount;
  final Map<String, int> reactionCounts;

  factory NewsStats.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const NewsStats();
    final raw = json['reactionCounts'];
    final map = <String, int>{};
    if (raw is Map) {
      raw.forEach((k, v) => map[k.toString()] = (v as num?)?.toInt() ?? 0);
    }
    return NewsStats(
      views: (json['views'] as num?)?.toInt() ?? 0,
      clicks: (json['clicks'] as num?)?.toInt() ?? 0,
      commentCount: (json['commentCount'] as num?)?.toInt() ?? 0,
      reactionCounts: map,
    );
  }
}

class PollOption {
  const PollOption({
    required this.id,
    required this.label,
    this.order = 0,
    this.count,
    this.percent,
  });

  final String id;
  final String label;
  final int order;
  final int? count;
  final double? percent;

  factory PollOption.fromJson(Map<String, dynamic> json) => PollOption(
        id: json['id']?.toString() ?? '',
        label: json['label']?.toString() ?? '',
        order: (json['order'] as num?)?.toInt() ?? 0,
        count: (json['count'] as num?)?.toInt(),
        percent: (json['percent'] as num?)?.toDouble(),
      );
}

class NewsPoll {
  const NewsPoll({
    required this.id,
    required this.question,
    this.pollType = 'single',
    this.options = const [],
    this.allowChangeVote = false,
    this.resultsVisibility = 'immediate',
    this.status = 'draft',
    this.open = false,
    this.totalVoters,
    this.myOptionIds = const [],
    this.hasVoted = false,
    this.postId,
  });

  final String id;
  final String question;
  final String pollType;
  final List<PollOption> options;
  final bool allowChangeVote;
  final String resultsVisibility;
  final String status;
  final bool open;
  final int? totalVoters;
  final List<String> myOptionIds;
  final bool hasVoted;
  final String? postId;

  factory NewsPoll.fromJson(Map<String, dynamic> json) => NewsPoll(
        id: json['id']?.toString() ?? '',
        question: json['question']?.toString() ?? '',
        pollType: json['pollType']?.toString() ?? 'single',
        options: (json['options'] as List<dynamic>? ?? [])
            .whereType<Map>()
            .map((e) => PollOption.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
        allowChangeVote: json['allowChangeVote'] == true,
        resultsVisibility: json['resultsVisibility']?.toString() ?? 'immediate',
        status: json['status']?.toString() ?? 'draft',
        open: json['open'] == true,
        totalVoters: (json['totalVoters'] as num?)?.toInt(),
        myOptionIds: (json['myOptionIds'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
        hasVoted: json['hasVoted'] == true,
        postId: json['postId']?.toString(),
      );

  NewsPoll copyWith({
    List<PollOption>? options,
    int? totalVoters,
    List<String>? myOptionIds,
    bool? hasVoted,
    bool? open,
    String? status,
  }) =>
      NewsPoll(
        id: id,
        question: question,
        pollType: pollType,
        options: options ?? this.options,
        allowChangeVote: allowChangeVote,
        resultsVisibility: resultsVisibility,
        status: status ?? this.status,
        open: open ?? this.open,
        totalVoters: totalVoters ?? this.totalVoters,
        myOptionIds: myOptionIds ?? this.myOptionIds,
        hasVoted: hasVoted ?? this.hasVoted,
        postId: postId,
      );
}

class NewsPost {
  const NewsPost({
    required this.id,
    required this.title,
    this.type = 'announcement',
    this.body = '',
    this.category = 'News',
    this.tags = const [],
    this.authorId = '',
    this.authorName = '',
    this.status = 'draft',
    this.publishAt,
    this.expiresAt,
    this.pinned = false,
    this.pinOrder = 0,
    this.commentsEnabled = true,
    this.reactionsEnabled = true,
    this.audience = const NewsAudience(),
    this.media = const [],
    this.links = const [],
    this.event,
    this.pollId,
    this.poll,
    this.showAsQuoteOfDay = false,
    this.quoteDate,
    this.stats = const NewsStats(),
    this.myReaction,
    this.createdAt,
  });

  final String id;
  final String title;
  final String type;
  final String body;
  final String category;
  final List<String> tags;
  final String authorId;
  final String authorName;
  final String status;
  final DateTime? publishAt;
  final DateTime? expiresAt;
  final bool pinned;
  final int pinOrder;
  final bool commentsEnabled;
  final bool reactionsEnabled;
  final NewsAudience audience;
  final List<NewsMedia> media;
  final List<NewsLink> links;
  final NewsEventInfo? event;
  final String? pollId;
  final NewsPoll? poll;
  final bool showAsQuoteOfDay;
  final DateTime? quoteDate;
  final NewsStats stats;
  final String? myReaction;
  final DateTime? createdAt;

  factory NewsPost.fromJson(Map<String, dynamic> json) => NewsPost(
        id: json['id']?.toString() ?? '',
        title: json['title']?.toString() ?? '',
        type: json['type']?.toString() ?? 'announcement',
        body: json['body']?.toString() ?? '',
        category: json['category']?.toString() ?? 'News',
        tags: (json['tags'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
        authorId: json['authorId']?.toString() ?? '',
        authorName: json['authorName']?.toString() ?? '',
        status: json['status']?.toString() ?? 'draft',
        publishAt: json['publishAt'] != null ? DateTime.tryParse(json['publishAt'].toString()) : null,
        expiresAt: json['expiresAt'] != null ? DateTime.tryParse(json['expiresAt'].toString()) : null,
        pinned: json['pinned'] == true,
        pinOrder: (json['pinOrder'] as num?)?.toInt() ?? 0,
        commentsEnabled: json['commentsEnabled'] != false,
        reactionsEnabled: json['reactionsEnabled'] != false,
        audience: NewsAudience.fromJson(
          json['audience'] is Map ? Map<String, dynamic>.from(json['audience'] as Map) : null,
        ),
        media: (json['media'] as List<dynamic>? ?? [])
            .whereType<Map>()
            .map((e) => NewsMedia.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
        links: (json['links'] as List<dynamic>? ?? [])
            .whereType<Map>()
            .map((e) => NewsLink.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
        event: json['event'] is Map
            ? NewsEventInfo.fromJson(Map<String, dynamic>.from(json['event'] as Map))
            : null,
        pollId: json['pollId']?.toString(),
        poll: json['poll'] is Map ? NewsPoll.fromJson(Map<String, dynamic>.from(json['poll'] as Map)) : null,
        showAsQuoteOfDay: json['showAsQuoteOfDay'] == true,
        quoteDate: json['quoteDate'] != null ? DateTime.tryParse(json['quoteDate'].toString()) : null,
        stats: NewsStats.fromJson(
          json['stats'] is Map ? Map<String, dynamic>.from(json['stats'] as Map) : null,
        ),
        myReaction: json['myReaction']?.toString(),
        createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
      );

  NewsPost copyWith({NewsPoll? poll, String? myReaction, NewsStats? stats}) => NewsPost(
        id: id,
        title: title,
        type: type,
        body: body,
        category: category,
        tags: tags,
        authorId: authorId,
        authorName: authorName,
        status: status,
        publishAt: publishAt,
        expiresAt: expiresAt,
        pinned: pinned,
        pinOrder: pinOrder,
        commentsEnabled: commentsEnabled,
        reactionsEnabled: reactionsEnabled,
        audience: audience,
        media: media,
        links: links,
        event: event,
        pollId: pollId,
        poll: poll ?? this.poll,
        showAsQuoteOfDay: showAsQuoteOfDay,
        quoteDate: quoteDate,
        stats: stats ?? this.stats,
        myReaction: myReaction ?? this.myReaction,
        createdAt: createdAt,
      );
}

class NewsComment {
  const NewsComment({
    required this.id,
    required this.postId,
    required this.body,
    this.authorId = '',
    this.authorName = '',
    this.authorType = 'student',
    this.parentId,
    this.createdAt,
  });

  final String id;
  final String postId;
  final String body;
  final String authorId;
  final String authorName;
  final String authorType;
  final String? parentId;
  final DateTime? createdAt;

  factory NewsComment.fromJson(Map<String, dynamic> json) => NewsComment(
        id: json['id']?.toString() ?? '',
        postId: json['postId']?.toString() ?? '',
        body: json['body']?.toString() ?? '',
        authorId: json['authorId']?.toString() ?? '',
        authorName: json['authorName']?.toString() ?? '',
        authorType: json['authorType']?.toString() ?? 'student',
        parentId: json['parentId']?.toString(),
        createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
      );
}

class NewsCategory {
  const NewsCategory({required this.id, required this.name, this.slug = ''});

  final String id;
  final String name;
  final String slug;

  factory NewsCategory.fromJson(Map<String, dynamic> json) => NewsCategory(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        slug: json['slug']?.toString() ?? '',
      );
}

class NewsFeedPage {
  const NewsFeedPage({
    required this.items,
    this.nextCursor,
    this.quoteOfDay,
  });

  final List<NewsPost> items;
  final String? nextCursor;
  final NewsPost? quoteOfDay;

  factory NewsFeedPage.fromJson(Map<String, dynamic> json) => NewsFeedPage(
        items: (json['items'] as List<dynamic>? ?? [])
            .whereType<Map>()
            .map((e) => NewsPost.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
        nextCursor: json['nextCursor']?.toString(),
        quoteOfDay: json['quoteOfDay'] is Map
            ? NewsPost.fromJson(Map<String, dynamic>.from(json['quoteOfDay'] as Map))
            : null,
      );
}
