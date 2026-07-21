import 'package:flutter_riverpod/flutter_riverpod.dart';

/// `all` = no branch filter (founder sees every branch).
class StaffBranchFilterNotifier extends StateNotifier<String> {
  StaffBranchFilterNotifier() : super('all');

  void select(String branchId) => state = branchId;

  String? get activeBranchId => state == 'all' ? null : state;
}

final staffBranchFilterProvider = StateNotifierProvider<StaffBranchFilterNotifier, String>((ref) {
  return StaffBranchFilterNotifier();
});
