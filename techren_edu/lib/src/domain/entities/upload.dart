class ImportPair {
  const ImportPair({
    required this.english,
    required this.uzbek,
    this.task,
    this.imageUrl,
  });

  final String english;
  final String uzbek;
  final String? task;
  final String? imageUrl;

  Map<String, String> toJson() => {
        'english': english,
        'uzbek': uzbek,
        if (task != null && task!.trim().isNotEmpty) 'task': task!.trim(),
        if (imageUrl != null && imageUrl!.trim().isNotEmpty) 'imageUrl': imageUrl!.trim(),
      };

  factory ImportPair.fromJson(Map<String, dynamic> json) => ImportPair(
        english: json['english'] as String? ?? '',
        uzbek: json['uzbek'] as String? ?? '',
        task: json['task'] as String?,
        imageUrl: json['imageUrl'] as String?,
      );
}

class ImportImageInfo {
  const ImportImageInfo({required this.url, this.filename, this.contentType});

  final String url;
  final String? filename;
  final String? contentType;

  factory ImportImageInfo.fromJson(Map<String, dynamic> json) => ImportImageInfo(
        url: json['url'] as String? ?? '',
        filename: json['filename'] as String?,
        contentType: json['contentType'] as String?,
      );
}

class ParseImportResult {
  const ParseImportResult({
    required this.pairs,
    required this.pairCount,
    this.skippedLines = const [],
    this.tasks = const [],
    this.images = const [],
    this.source,
    this.message,
    this.ocrEnabled = true,
    this.imageUrl,
  });

  final List<ImportPair> pairs;
  final int pairCount;
  final List<String> skippedLines;
  final List<String> tasks;
  final List<ImportImageInfo> images;
  final String? source;
  final String? message;
  final bool ocrEnabled;
  final String? imageUrl;

  factory ParseImportResult.fromJson(Map<String, dynamic> json) => ParseImportResult(
        pairs: (json['pairs'] as List<dynamic>? ?? [])
            .map((e) => ImportPair.fromJson(e as Map<String, dynamic>))
            .toList(),
        pairCount: json['pairCount'] as int? ?? 0,
        skippedLines: (json['skippedLines'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
        tasks: (json['tasks'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
        images: (json['images'] as List<dynamic>? ?? [])
            .map((e) => ImportImageInfo.fromJson(e as Map<String, dynamic>))
            .toList(),
        source: json['source'] as String? ?? json['filename'] as String?,
        message: json['message'] as String?,
        ocrEnabled: json['ocrEnabled'] as bool? ?? true,
        imageUrl: json['imageUrl'] as String?,
      );
}

class BulkImportResult {
  const BulkImportResult({
    required this.created,
    required this.skipped,
    this.errors = const [],
  });

  final int created;
  final int skipped;
  final List<dynamic> errors;

  factory BulkImportResult.fromJson(Map<String, dynamic> json) => BulkImportResult(
        created: json['created'] as int? ?? 0,
        skipped: json['skipped'] as int? ?? 0,
        errors: json['errors'] as List<dynamic>? ?? [],
      );
}

class UploadedFileInfo {
  const UploadedFileInfo({
    required this.filename,
    required this.url,
    this.originalName,
    this.mimeType,
    this.size,
  });

  final String filename;
  final String url;
  final String? originalName;
  final String? mimeType;
  final int? size;

  factory UploadedFileInfo.fromJson(Map<String, dynamic> json) => UploadedFileInfo(
        filename: json['filename'] as String? ?? '',
        url: json['url'] as String? ?? '',
        originalName: json['originalName'] as String?,
        mimeType: json['mimeType'] as String?,
        size: json['size'] as int?,
      );
}

class StaffLessonOption {
  const StaffLessonOption({
    required this.id,
    required this.name,
    required this.type,
    this.wordCount = 0,
  });

  final String id;
  final String name;
  final String type;
  final int wordCount;

  factory StaffLessonOption.fromJson(Map<String, dynamic> json) => StaffLessonOption(
        id: json['id']?.toString() ?? '',
        name: json['name'] as String? ?? '',
        type: json['type'] as String? ?? 'words',
        wordCount: json['wordCount'] as int? ?? 0,
      );
}
