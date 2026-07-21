class RecycleBinEntry {
  const RecycleBinEntry({
    required this.id,
    required this.collectionName,
    required this.documentId,
    required this.label,
    required this.moduleType,
    this.cascadeGroupId,
    this.deletedBy,
    this.deletedAt,
    this.isImportant = false,
    this.restoredAt,
    this.purgedAt,
    this.createdAt,
  });

  final String id;
  final String collectionName;
  final String documentId;
  final String label;
  final String moduleType;
  final String? cascadeGroupId;
  final String? deletedBy;
  final DateTime? deletedAt;
  final bool isImportant;
  final DateTime? restoredAt;
  final DateTime? purgedAt;
  final DateTime? createdAt;

  factory RecycleBinEntry.fromJson(Map<String, dynamic> json) {
    return RecycleBinEntry(
      id: json['id'] as String,
      collectionName: json['collectionName'] as String? ?? '',
      documentId: (json['documentId'] ?? '').toString(),
      label: json['label'] as String? ?? '',
      moduleType: json['moduleType'] as String? ?? '',
      cascadeGroupId: json['cascadeGroupId'] as String?,
      deletedBy: json['deletedBy'] as String?,
      deletedAt: json['deletedAt'] != null ? DateTime.tryParse(json['deletedAt'].toString()) : null,
      isImportant: json['isImportant'] as bool? ?? false,
      restoredAt: json['restoredAt'] != null ? DateTime.tryParse(json['restoredAt'].toString()) : null,
      purgedAt: json['purgedAt'] != null ? DateTime.tryParse(json['purgedAt'].toString()) : null,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
    );
  }
}

class RecycleBinSnapshot {
  const RecycleBinSnapshot({
    required this.id,
    required this.version,
    required this.changeType,
    this.changedBy,
    this.createdAt,
    required this.snapshot,
  });

  final String id;
  final int version;
  final String changeType;
  final String? changedBy;
  final DateTime? createdAt;
  final Map<String, dynamic> snapshot;

  factory RecycleBinSnapshot.fromJson(Map<String, dynamic> json) {
    return RecycleBinSnapshot(
      id: json['id'] as String,
      version: json['version'] as int? ?? 1,
      changeType: json['changeType'] as String? ?? 'update',
      changedBy: json['changedBy'] as String?,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
      snapshot: Map<String, dynamic>.from(json['snapshot'] as Map? ?? {}),
    );
  }
}

class RecycleBinSnapshotDetail {
  const RecycleBinSnapshotDetail({
    required this.entry,
    required this.snapshots,
  });

  final RecycleBinEntry entry;
  final List<RecycleBinSnapshot> snapshots;

  factory RecycleBinSnapshotDetail.fromJson(Map<String, dynamic> json) {
    return RecycleBinSnapshotDetail(
      entry: RecycleBinEntry.fromJson(json['entry'] as Map<String, dynamic>),
      snapshots: (json['snapshots'] as List<dynamic>? ?? [])
          .map((e) => RecycleBinSnapshot.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class RecycleBinRestoreResult {
  const RecycleBinRestoreResult({
    required this.restoredCount,
    required this.items,
  });

  final int restoredCount;
  final List<RecycleBinEntry> items;

  factory RecycleBinRestoreResult.fromJson(Map<String, dynamic> json) {
    return RecycleBinRestoreResult(
      restoredCount: json['restoredCount'] as int? ?? 0,
      items: (json['items'] as List<dynamic>? ?? [])
          .map((e) => RecycleBinEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class RecycleBinPurgeAllResult {
  const RecycleBinPurgeAllResult({
    required this.purgedCount,
  });

  final int purgedCount;

  factory RecycleBinPurgeAllResult.fromJson(Map<String, dynamic> json) {
    return RecycleBinPurgeAllResult(purgedCount: json['purgedCount'] as int? ?? 0);
  }
}
