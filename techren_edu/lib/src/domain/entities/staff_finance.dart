class StaffAccountSummary {
  const StaffAccountSummary({
    required this.staffId,
    required this.totalEarned,
    required this.totalPaidOut,
    required this.availableForPayout,
    required this.pendingEarnings,
    required this.approvedNotPaid,
    this.lastEarningDate,
    this.lastPayoutDate,
    this.currency = 'UZS',
  });

  final String staffId;
  final int totalEarned;
  final int totalPaidOut;
  final int availableForPayout;
  final int pendingEarnings;
  final int approvedNotPaid;
  final DateTime? lastEarningDate;
  final DateTime? lastPayoutDate;
  final String currency;

  factory StaffAccountSummary.fromJson(Map<String, dynamic> json) {
    return StaffAccountSummary(
      staffId: (json['staffId'] ?? '').toString(),
      totalEarned: (json['totalEarned'] as num?)?.toInt() ?? 0,
      totalPaidOut: (json['totalPaidOut'] as num?)?.toInt() ?? 0,
      availableForPayout: (json['availableForPayout'] as num?)?.toInt() ?? 0,
      pendingEarnings: (json['pendingEarnings'] as num?)?.toInt() ?? 0,
      approvedNotPaid: (json['approvedNotPaid'] as num?)?.toInt() ?? 0,
      lastEarningDate: json['lastEarningDate'] != null
          ? DateTime.tryParse(json['lastEarningDate'].toString())
          : null,
      lastPayoutDate: json['lastPayoutDate'] != null
          ? DateTime.tryParse(json['lastPayoutDate'].toString())
          : null,
      currency: json['currency'] as String? ?? 'UZS',
    );
  }
}

class StaffEarningEntry {
  const StaffEarningEntry({
    required this.id,
    required this.staffId,
    this.staffName,
    required this.amount,
    required this.earningType,
    required this.status,
    this.referenceDate,
    this.description,
    this.reason,
    this.approvedByName,
    this.approvedAt,
    this.paidAt,
    this.createdAt,
  });

  final String id;
  final String staffId;
  final String? staffName;
  final int amount;
  final String earningType;
  final String status;
  final DateTime? referenceDate;
  final String? description;
  final String? reason;
  final String? approvedByName;
  final DateTime? approvedAt;
  final DateTime? paidAt;
  final DateTime? createdAt;

  factory StaffEarningEntry.fromJson(Map<String, dynamic> json) {
    return StaffEarningEntry(
      id: json['id'] as String,
      staffId: (json['staffId'] ?? '').toString(),
      staffName: json['staffName'] as String?,
      amount: json['amount'] as int? ?? 0,
      earningType: json['earningType'] as String? ?? 'salary',
      status: json['status'] as String? ?? 'pending',
      referenceDate: json['referenceDate'] != null
          ? DateTime.tryParse(json['referenceDate'].toString())
          : null,
      description: json['description'] as String?,
      reason: json['reason'] as String?,
      approvedByName: json['approvedByName'] as String?,
      approvedAt: json['approvedAt'] != null
          ? DateTime.tryParse(json['approvedAt'].toString())
          : null,
      paidAt: json['paidAt'] != null ? DateTime.tryParse(json['paidAt'].toString()) : null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }
}

class StaffPayoutEntry {
  const StaffPayoutEntry({
    required this.id,
    required this.payoutRef,
    required this.staffId,
    this.staffName,
    required this.amount,
    required this.method,
    required this.status,
    this.referenceNumber,
    this.approvedByName,
    this.completedAt,
    this.cancelledAt,
    this.cancellationReason,
    this.notes,
    this.createdAt,
    this.earningIds = const [],
  });

  final String id;
  final String payoutRef;
  final String staffId;
  final String? staffName;
  final int amount;
  final String method;
  final String status;
  final String? referenceNumber;
  final String? approvedByName;
  final DateTime? completedAt;
  final DateTime? cancelledAt;
  final String? cancellationReason;
  final String? notes;
  final DateTime? createdAt;
  final List<String> earningIds;

  factory StaffPayoutEntry.fromJson(Map<String, dynamic> json) {
    return StaffPayoutEntry(
      id: json['id'] as String,
      payoutRef: json['payoutRef'] as String? ?? '',
      staffId: (json['staffId'] ?? '').toString(),
      staffName: json['staffName'] as String?,
      amount: json['amount'] as int? ?? 0,
      method: json['method'] as String? ?? 'cash',
      status: json['status'] as String? ?? 'pending',
      referenceNumber: json['referenceNumber'] as String?,
      approvedByName: json['approvedByName'] as String?,
      completedAt: json['completedAt'] != null
          ? DateTime.tryParse(json['completedAt'].toString())
          : null,
      cancelledAt: json['cancelledAt'] != null
          ? DateTime.tryParse(json['cancelledAt'].toString())
          : null,
      cancellationReason: json['cancellationReason'] as String?,
      notes: json['notes'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      earningIds: (json['earningIds'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
    );
  }
}

class StaffPayoutPreview {
  const StaffPayoutPreview({
    required this.staffId,
    required this.earningsCount,
    required this.totalAmount,
    required this.earnings,
  });

  final String staffId;
  final int earningsCount;
  final int totalAmount;
  final List<StaffEarningEntry> earnings;

  factory StaffPayoutPreview.fromJson(Map<String, dynamic> json) {
    return StaffPayoutPreview(
      staffId: (json['staffId'] ?? '').toString(),
      earningsCount: json['earningsCount'] as int? ?? 0,
      totalAmount: json['totalAmount'] as int? ?? 0,
      earnings: (json['earnings'] as List<dynamic>? ?? [])
          .map((e) => StaffEarningEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
