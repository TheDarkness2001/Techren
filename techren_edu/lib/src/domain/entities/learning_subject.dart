import 'package:equatable/equatable.dart';

class LearningModuleDef extends Equatable {
  const LearningModuleDef({
    required this.key,
    required this.label,
    required this.category,
    this.icon = 'menu_book',
    this.audience = 'all',
    this.enabled = true,
  });

  final String key;
  final String label;
  final String category;
  final String icon;
  final String audience;
  final bool enabled;

  factory LearningModuleDef.fromJson(Map<String, dynamic> json) => LearningModuleDef(
        key: json['key'] as String? ?? '',
        label: json['label'] as String? ?? '',
        category: json['category'] as String? ?? 'learning',
        icon: json['icon'] as String? ?? 'menu_book',
        audience: json['audience'] as String? ?? 'all',
        enabled: json['enabled'] as bool? ?? true,
      );

  @override
  List<Object?> get props => [key, label];
}

class LearningSubjectCard extends Equatable {
  const LearningSubjectCard({
    required this.id,
    required this.name,
    this.code,
    this.icon = 'menu_book',
    this.color = '#2563EB',
    this.description = '',
    this.levelLabel = 'Active',
    this.progressPercent = 0,
    this.lastActivity,
    this.groupCount = 0,
    this.studentCount = 0,
    this.modules = const [],
  });

  final String id;
  final String name;
  final String? code;
  final String icon;
  final String color;
  final String description;
  final String levelLabel;
  final int progressPercent;
  final DateTime? lastActivity;
  final int groupCount;
  final int studentCount;
  final List<LearningModuleDef> modules;

  factory LearningSubjectCard.fromJson(Map<String, dynamic> json) => LearningSubjectCard(
        id: json['id']?.toString() ?? '',
        name: json['name'] as String? ?? '',
        code: json['code'] as String?,
        icon: json['icon'] as String? ?? 'menu_book',
        color: json['color'] as String? ?? '#2563EB',
        description: json['description'] as String? ?? '',
        levelLabel: json['levelLabel'] as String? ?? json['code'] as String? ?? 'Active',
        progressPercent: (json['progressPercent'] as num?)?.round() ?? 0,
        lastActivity: DateTime.tryParse(json['lastActivity']?.toString() ?? ''),
        groupCount: json['groupCount'] as int? ?? 0,
        studentCount: json['studentCount'] as int? ?? 0,
        modules: (json['modules'] as List<dynamic>? ?? [])
            .map((e) => LearningModuleDef.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  @override
  List<Object?> get props => [id, name];
}

class LearningSubjectDashboard extends LearningSubjectCard {
  const LearningSubjectDashboard({
    required super.id,
    required super.name,
    super.code,
    super.icon,
    super.color,
    super.description,
    super.levelLabel,
    super.progressPercent,
    super.lastActivity,
    super.groupCount,
    super.studentCount,
    super.modules,
    this.modulesByCategory = const {},
    this.allModules = const [],
  });

  final Map<String, List<LearningModuleDef>> modulesByCategory;
  final List<LearningModuleDef> allModules;

  factory LearningSubjectDashboard.fromJson(Map<String, dynamic> json) {
    final byCategoryRaw = json['modulesByCategory'] as Map<String, dynamic>? ?? {};
    final byCategory = <String, List<LearningModuleDef>>{};
    for (final entry in byCategoryRaw.entries) {
      byCategory[entry.key] = (entry.value as List<dynamic>? ?? [])
          .map((e) => LearningModuleDef.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    final card = LearningSubjectCard.fromJson(json);
    final allModules = (json['allModules'] as List<dynamic>? ?? [])
        .map((e) => LearningModuleDef.fromJson(e as Map<String, dynamic>))
        .toList();
    return LearningSubjectDashboard(
      id: card.id,
      name: card.name,
      code: card.code,
      icon: card.icon,
      color: card.color,
      description: card.description,
      levelLabel: card.levelLabel,
      progressPercent: card.progressPercent,
      lastActivity: card.lastActivity,
      groupCount: card.groupCount,
      studentCount: card.studentCount,
      modules: card.modules,
      modulesByCategory: byCategory,
      allModules: allModules.isNotEmpty ? allModules : card.modules,
    );
  }
}
