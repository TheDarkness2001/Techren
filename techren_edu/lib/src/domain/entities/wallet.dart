class WalletBalance {
  const WalletBalance({
    required this.id,
    required this.studentId,
    required this.balanceTyiyn,
    required this.balanceSom,
    this.isLocked = false,
    this.graceBalanceTyiyn = 0,
  });

  final String id;
  final String studentId;
  final int balanceTyiyn;
  final double balanceSom;
  final bool isLocked;
  final int graceBalanceTyiyn;

  factory WalletBalance.fromJson(Map<String, dynamic> json) {
    return WalletBalance(
      id: json['id'] as String,
      studentId: json['studentId']?.toString() ?? '',
      balanceTyiyn: json['balanceTyiyn'] as int? ?? 0,
      balanceSom: (json['balanceSom'] as num?)?.toDouble() ?? 0,
      isLocked: json['isLocked'] as bool? ?? false,
      graceBalanceTyiyn: json['graceBalanceTyiyn'] as int? ?? 0,
    );
  }
}

class WalletTransaction {
  const WalletTransaction({
    required this.id,
    required this.type,
    required this.amountTyiyn,
    required this.amountSom,
    required this.balanceAfterSom,
    this.description,
    required this.createdAt,
  });

  final String id;
  final String type;
  final int amountTyiyn;
  final double amountSom;
  final double balanceAfterSom;
  final String? description;
  final DateTime createdAt;

  bool get isCredit => type == 'topup' || type == 'refund';

  factory WalletTransaction.fromJson(Map<String, dynamic> json) {
    return WalletTransaction(
      id: json['id'] as String,
      type: json['type'] as String? ?? '',
      amountTyiyn: json['amountTyiyn'] as int? ?? 0,
      amountSom: (json['amountSom'] as num?)?.toDouble() ?? 0,
      balanceAfterSom: (json['balanceAfterSom'] as num?)?.toDouble() ?? 0,
      description: json['description'] as String?,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}

class WalletTopupResult {
  const WalletTopupResult({
    required this.wallet,
    required this.transaction,
  });

  final WalletBalance wallet;
  final WalletTransaction transaction;

  factory WalletTopupResult.fromJson(Map<String, dynamic> json) {
    return WalletTopupResult(
      wallet: WalletBalance.fromJson(json['wallet'] as Map<String, dynamic>),
      transaction: WalletTransaction.fromJson(json['transaction'] as Map<String, dynamic>),
    );
  }
}
