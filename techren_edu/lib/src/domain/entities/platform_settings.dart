class PlatformSettings {
  const PlatformSettings({
    required this.featureFlags,
    required this.rolePermissions,
    this.updatedAt,
  });

  /// Used before login / when settings cannot be loaded.
  static const empty = PlatformSettings(
    featureFlags: FeatureFlags(),
    rolePermissions: {},
  );

  final FeatureFlags featureFlags;
  final Map<String, Map<String, bool>> rolePermissions;
  final DateTime? updatedAt;

  factory PlatformSettings.fromJson(Map<String, dynamic> json) {
    final flags = json['featureFlags'] as Map<String, dynamic>? ?? {};
    final perms = json['rolePermissions'] as Map<String, dynamic>? ?? {};

    return PlatformSettings(
      featureFlags: FeatureFlags.fromJson(flags),
      rolePermissions: perms.map(
        (role, value) => MapEntry(
          role,
          (value as Map<String, dynamic>).map((k, v) => MapEntry(k, v == true)),
        ),
      ),
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt'].toString()) : null,
    );
  }

  Map<String, dynamic> toUpdateJson() => {
        'featureFlags': featureFlags.toJson(),
        'rolePermissions': rolePermissions,
      };
}

class FeatureFlags {
  const FeatureFlags({
    this.walletEnabled = false,
    this.gamificationEnabled = true,
    this.parentPortalEnabled = false,
    this.teachersCanCreatePolls = false,
  });

  final bool walletEnabled;
  final bool gamificationEnabled;
  final bool parentPortalEnabled;
  final bool teachersCanCreatePolls;

  factory FeatureFlags.fromJson(Map<String, dynamic> json) => FeatureFlags(
        walletEnabled: json['walletEnabled'] as bool? ?? false,
        gamificationEnabled: json['gamificationEnabled'] as bool? ?? true,
        parentPortalEnabled: json['parentPortalEnabled'] as bool? ?? false,
        teachersCanCreatePolls: json['teachersCanCreatePolls'] as bool? ?? false,
      );

  FeatureFlags copyWith({
    bool? walletEnabled,
    bool? gamificationEnabled,
    bool? parentPortalEnabled,
    bool? teachersCanCreatePolls,
  }) =>
      FeatureFlags(
        walletEnabled: walletEnabled ?? this.walletEnabled,
        gamificationEnabled: gamificationEnabled ?? this.gamificationEnabled,
        parentPortalEnabled: parentPortalEnabled ?? this.parentPortalEnabled,
        teachersCanCreatePolls: teachersCanCreatePolls ?? this.teachersCanCreatePolls,
      );

  Map<String, dynamic> toJson() => {
        'walletEnabled': walletEnabled,
        'gamificationEnabled': gamificationEnabled,
        'parentPortalEnabled': parentPortalEnabled,
        'teachersCanCreatePolls': teachersCanCreatePolls,
      };
}

const permissionLabels = <String, String>{
  'canViewStudents': 'View students',
  'canManageStudents': 'Manage students',
  'canViewAttendance': 'View attendance',
  'canManageAttendance': 'Manage attendance',
  'canViewFeedback': 'View feedback',
  'canManageFeedback': 'Manage feedback',
  'canViewPayments': 'View payments',
  'canManagePayments': 'Manage payments',
  'canViewRevenue': 'View revenue',
  'canManageRevenue': 'Manage revenue',
  'canViewScheduler': 'View scheduler',
  'canManageScheduler': 'Manage scheduler',
  'canViewTimetable': 'View timetable',
  'canManageTimetable': 'Manage timetable',
  'canViewExams': 'View exams',
  'canManageExams': 'Manage exams',
  'canManageSettings': 'Manage settings',
  'canManageHomework': 'Manage homework / CMS',
  'canManageVideoLessons': 'Manage video lessons',
  'canViewWallet': 'View wallet',
  'canManageWallet': 'Manage wallet',
  'canUseCommunications': 'Use messages',
  'canBroadcast': 'Send broadcasts',
  'canModerateCommunications': 'Moderate messages',
  'canViewNewsFeed': 'View news feed',
  'canCreateNews': 'Create news posts',
  'canManageNews': 'Manage all news',
  'canCreatePolls': 'Create polls',
  'canModerateNews': 'Moderate news',
};

const editableRoles = ['teacher', 'sales', 'receptionist', 'manager'];
