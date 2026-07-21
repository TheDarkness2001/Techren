class PenaltyRecord {
  const PenaltyRecord({
    required this.id,
    required this.type,
    required this.points,
    required this.quantity,
    required this.totalPoints,
    required this.date,
    required this.notes,
    required this.isReverted,
    this.studentName,
    this.recordedByName,
  });

  final String id;
  final String type;
  final int points;
  final int quantity;
  final int totalPoints;
  final DateTime date;
  final String notes;
  final bool isReverted;
  final String? studentName;
  final String? recordedByName;

  factory PenaltyRecord.fromJson(Map<String, dynamic> json) => PenaltyRecord(
        id: json['id']?.toString() ?? '',
        type: json['type'] as String? ?? '',
        points: json['points'] as int? ?? 0,
        quantity: json['quantity'] as int? ?? 1,
        totalPoints: json['totalPoints'] as int? ?? 0,
        date: DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now(),
        notes: json['notes'] as String? ?? '',
        isReverted: json['isReverted'] as bool? ?? false,
        studentName: json['studentName'] as String?,
        recordedByName: json['recordedByName'] as String?,
      );
}

class PresentationRecord {
  const PresentationRecord({
    required this.id,
    required this.score,
    required this.date,
    required this.notes,
    this.evaluatedByName,
  });

  final String id;
  final int score;
  final DateTime date;
  final String notes;
  final String? evaluatedByName;

  factory PresentationRecord.fromJson(Map<String, dynamic> json) => PresentationRecord(
        id: json['id']?.toString() ?? '',
        score: json['score'] as int? ?? 0,
        date: DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now(),
        notes: json['notes'] as String? ?? '',
        evaluatedByName: json['evaluatedByName'] as String?,
      );
}

class TopPresenter {
  const TopPresenter({
    required this.rank,
    required this.studentId,
    required this.name,
    required this.studentCode,
    required this.avgScore,
    required this.count,
  });

  final int rank;
  final String studentId;
  final String name;
  final String studentCode;
  final double avgScore;
  final int count;

  factory TopPresenter.fromJson(Map<String, dynamic> json) => TopPresenter(
        rank: json['rank'] as int? ?? 0,
        studentId: json['studentId']?.toString() ?? '',
        name: json['name'] as String? ?? '',
        studentCode: json['studentCode'] as String? ?? '',
        avgScore: (json['avgScore'] as num?)?.toDouble() ?? 0,
        count: json['count'] as int? ?? 0,
      );
}

class BonusPreview {
  const BonusPreview({
    required this.totalPenalties,
    required this.firstPlaceAmount,
    required this.secondPlaceAmount,
    required this.centerAmount,
    required this.topPresenters,
  });

  final int totalPenalties;
  final int firstPlaceAmount;
  final int secondPlaceAmount;
  final int centerAmount;
  final List<TopPresenter> topPresenters;

  factory BonusPreview.fromJson(Map<String, dynamic> json) => BonusPreview(
        totalPenalties: json['totalPenalties'] as int? ?? 0,
        firstPlaceAmount: (json['firstPlace']?['amount'] as int?) ?? 0,
        secondPlaceAmount: (json['secondPlace']?['amount'] as int?) ?? 0,
        centerAmount: (json['educationCenter']?['amount'] as int?) ?? 0,
        topPresenters: (json['topPresenters'] as List<dynamic>? ?? [])
            .map((e) => TopPresenter.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class BonusPeriod {
  const BonusPeriod({
    required this.year,
    required this.month,
    required this.status,
    required this.totalPenalties,
    required this.totalBonusesDistributed,
  });

  final int year;
  final int month;
  final String status;
  final int totalPenalties;
  final int totalBonusesDistributed;

  factory BonusPeriod.fromJson(Map<String, dynamic> json) => BonusPeriod(
        year: json['year'] as int? ?? 0,
        month: json['month'] as int? ?? 0,
        status: json['status'] as String? ?? 'open',
        totalPenalties: json['totalPenalties'] as int? ?? 0,
        totalBonusesDistributed: json['totalBonusesDistributed'] as int? ?? 0,
      );
}
