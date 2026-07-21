# Phase 5 — Flutter Folder Structure

**Project name:** `techren_edu`  
**Architecture:** Clean Architecture + Riverpod + go_router  
**Min SDK:** Flutter 3.24+ / Dart 3.5+

---

## 1. Root Structure

```
techren_edu/
├── android/
├── ios/
├── windows/
├── linux/
├── macos/                    # optional future
├── web/                      # disabled in production; dev preview only
├── assets/
│   ├── images/
│   ├── icons/
│   ├── animations/           # Lottie/Rive
│   └── fonts/
├── lib/
│   ├── main.dart
│   ├── app.dart
│   ├── bootstrap.dart        # init: storage, cache, firebase
│   └── src/
│       ├── core/
│       ├── domain/
│       ├── data/
│       ├── presentation/
│       └── l10n/
├── test/
│   ├── unit/
│   ├── widget/
│   └── integration/
├── pubspec.yaml
└── analysis_options.yaml
```

---

## 2. `lib/src/core/` — Shared Infrastructure

```
core/
├── constants/
│   ├── api_constants.dart
│   ├── app_constants.dart
│   ├── storage_keys.dart
│   └── permission_keys.dart
├── theme/
│   ├── app_theme.dart
│   ├── app_colors.dart
│   ├── app_typography.dart
│   ├── app_spacing.dart
│   └── app_shadows.dart
├── extensions/
│   ├── context_extensions.dart
│   ├── datetime_extensions.dart
│   ├── string_extensions.dart
│   └── num_extensions.dart
├── utils/
│   ├── validators.dart
│   ├── formatters.dart
│   ├── debouncer.dart
│   └── responsive.dart
├── errors/
│   ├── app_exception.dart
│   ├── failure.dart
│   └── error_mapper.dart
├── network/
│   ├── dio_client.dart
│   ├── auth_interceptor.dart
│   ├── refresh_interceptor.dart
│   └── connectivity_service.dart
├── storage/
│   ├── secure_storage_service.dart
│   └── cache_service.dart
├── routing/
│   ├── app_router.dart
│   ├── route_names.dart
│   ├── route_guards.dart
│   └── shell_scaffold.dart
└── widgets/
    ├── adaptive_scaffold.dart
    ├── app_bottom_nav.dart
    ├── app_navigation_rail.dart
    ├── loading_skeleton.dart
    ├── empty_state.dart
    ├── error_state.dart
    ├── pull_to_refresh_wrapper.dart
    ├── confirmation_dialog.dart
    ├── search_field.dart
    ├── filter_chip_bar.dart
    ├── stat_card.dart
    ├── profile_avatar.dart
    └── offline_banner.dart
```

---

## 3. `lib/src/domain/` — Business Logic (Pure Dart)

```
domain/
├── entities/
│   ├── user.dart
│   ├── branch.dart
│   ├── student.dart
│   ├── teacher.dart
│   ├── subject.dart
│   ├── exam_group.dart
│   ├── class_schedule.dart
│   ├── attendance.dart
│   ├── feedback.dart
│   ├── exam.dart
│   ├── payment.dart
│   ├── language.dart
│   ├── level.dart
│   ├── lesson.dart
│   ├── word.dart
│   ├── sentence.dart
│   ├── listening_exercise.dart
│   ├── video_lesson.dart
│   ├── topic_test.dart
│   ├── penalty.dart
│   ├── gamification_profile.dart
│   └── achievement.dart
├── enums/
│   ├── user_role.dart
│   ├── user_type.dart
│   ├── module_type.dart
│   ├── direction_mode.dart
│   ├── lesson_status.dart
│   └── listening_tier.dart
├── repositories/              # abstract contracts
│   ├── auth_repository.dart
│   ├── branch_repository.dart
│   ├── student_repository.dart
│   ├── teacher_repository.dart
│   ├── schedule_repository.dart
│   ├── attendance_repository.dart
│   ├── feedback_repository.dart
│   ├── exam_repository.dart
│   ├── payment_repository.dart
│   ├── homework_repository.dart
│   ├── sentence_repository.dart
│   ├── listening_repository.dart
│   ├── video_repository.dart
│   ├── competition_repository.dart
│   ├── gamification_repository.dart
│   └── settings_repository.dart
└── usecases/
    ├── auth/
    │   ├── login_usecase.dart
    │   ├── logout_usecase.dart
    │   └── get_current_user_usecase.dart
    ├── learning/
    │   ├── get_random_word_usecase.dart
    │   ├── check_word_answer_usecase.dart
    │   ├── submit_word_result_usecase.dart
    │   ├── check_sentence_answer_usecase.dart
    │   ├── check_listening_answer_usecase.dart
    │   └── submit_exam_usecase.dart
    └── ...
```

---

## 4. `lib/src/data/` — Data Layer

```
data/
├── models/                    # JSON serializable DTOs
│   ├── user_model.dart
│   ├── student_model.dart
│   ├── word_model.dart
│   ├── sentence_check_result_model.dart
│   └── ...
├── datasources/
│   ├── remote/
│   │   ├── auth_api.dart
│   │   ├── students_api.dart
│   │   ├── homework_api.dart
│   │   ├── sentences_api.dart
│   │   ├── listening_api.dart
│   │   ├── video_api.dart
│   │   └── ...
│   └── local/
│       ├── auth_local_datasource.dart
│       ├── cache_datasource.dart
│       └── offline_queue_datasource.dart
├── repositories/              # implements domain contracts
│   ├── auth_repository_impl.dart
│   ├── homework_repository_impl.dart
│   └── ...
└── mappers/
    ├── user_mapper.dart
    ├── word_mapper.dart
    └── ...
```

---

## 5. `lib/src/presentation/` — UI Layer

```
presentation/
├── providers/
│   ├── auth_provider.dart
│   ├── branch_provider.dart
│   ├── theme_provider.dart
│   ├── locale_provider.dart
│   └── connectivity_provider.dart
├── features/
│   ├── auth/
│   │   ├── screens/
│   │   │   ├── login_screen.dart
│   │   │   └── splash_screen.dart
│   │   ├── widgets/
│   │   │   └── login_form.dart
│   │   └── providers/
│   │       └── login_provider.dart
│   ├── founder/
│   │   ├── screens/
│   │   │   ├── founder_dashboard_screen.dart
│   │   │   └── branch_management_screen.dart
│   │   └── widgets/
│   ├── manager/
│   │   ├── screens/
│   │   │   └── manager_dashboard_screen.dart
│   │   └── widgets/
│   ├── admin/
│   │   ├── screens/
│   │   │   ├── admin_dashboard_screen.dart
│   │   │   ├── people_screen.dart
│   │   │   ├── revenue_screen.dart
│   │   │   └── recycle_bin_screen.dart
│   │   └── widgets/
│   ├── teacher/
│   │   ├── screens/
│   │   │   ├── teacher_dashboard_screen.dart
│   │   │   ├── attendance_screen.dart
│   │   │   ├── feedback_screen.dart
│   │   │   ├── my_classes_screen.dart
│   │   │   └── earnings_screen.dart
│   │   └── widgets/
│   ├── student/
│   │   ├── screens/
│   │   │   ├── student_dashboard_screen.dart
│   │   │   ├── timetable_screen.dart
│   │   │   ├── results_screen.dart
│   │   │   └── payments_screen.dart
│   │   └── widgets/
│   ├── parent/                # future-ready
│   │   ├── screens/
│   │   │   └── child_profile_screen.dart
│   │   └── widgets/
│   ├── learning/
│   │   ├── words/
│   │   │   ├── screens/
│   │   │   │   ├── words_hub_screen.dart
│   │   │   │   ├── word_practice_screen.dart
│   │   │   │   ├── word_exam_screen.dart
│   │   │   │   └── words_leaderboard_screen.dart
│   │   │   ├── widgets/
│   │   │   │   ├── word_flash_card.dart
│   │   │   │   ├── direction_toggle.dart
│   │   │   │   └── accuracy_ring.dart
│   │   │   └── providers/
│   │   │       └── word_practice_provider.dart
│   │   ├── sentences/
│   │   │   ├── screens/
│   │   │   │   ├── sentences_hub_screen.dart
│   │   │   │   ├── sentence_practice_screen.dart
│   │   │   │   └── sentence_analysis_sheet.dart
│   │   │   └── widgets/
│   │   │       ├── sentence_input_field.dart
│   │   │       └── grammar_error_chip.dart
│   │   ├── listening/
│   │   │   ├── screens/
│   │   │   │   ├── listening_hub_screen.dart
│   │   │   │   └── listening_practice_screen.dart
│   │   │   └── widgets/
│   │   │       ├── audio_player_controls.dart
│   │   │       └── tier_result_card.dart
│   │   ├── video/
│   │   │   ├── screens/
│   │   │   │   ├── video_hub_screen.dart
│   │   │   │   ├── video_player_screen.dart
│   │   │   │   └── topic_test_screen.dart
│   │   │   └── widgets/
│   │   │       ├── watch_progress_bar.dart
│   │   │       └── anti_cheat_overlay.dart
│   │   └── shared/
│   │       ├── screens/
│   │       │   ├── learning_hub_screen.dart
│   │       │   ├── level_picker_screen.dart
│   │       │   └── lesson_picker_screen.dart
│   │       └── widgets/
│   │           ├── module_card.dart
│   │           ├── level_progress_tile.dart
│   │           ├── leaderboard_table.dart
│   │           └── unlock_badge.dart
│   ├── scheduling/
│   │   ├── screens/
│   │   └── widgets/
│   ├── competition/
│   │   ├── screens/
│   │   └── widgets/
│   ├── gamification/
│   │   ├── screens/
│   │   │   ├── xp_profile_screen.dart
│   │   │   └── achievements_screen.dart
│   │   └── widgets/
│   │       ├── xp_bar.dart
│   │       ├── streak_flame.dart
│   │       └── achievement_badge.dart
│   ├── notifications/
│   │   ├── screens/
│   │   └── widgets/
│   ├── profile/
│   │   ├── screens/
│   │   │   ├── profile_screen.dart
│   │   │   └── settings_screen.dart
│   │   └── widgets/
│   └── cms/                   # staff learning content management
│       ├── screens/
│       │   ├── content_manager_screen.dart
│       │   ├── exam_control_screen.dart
│       │   └── student_progress_screen.dart
│       └── widgets/
└── shells/
    ├── student_shell.dart
    ├── teacher_shell.dart
    ├── staff_shell.dart
    ├── founder_shell.dart
    └── parent_shell.dart
```

---

## 6. Localization — `lib/src/l10n/`

```
l10n/
├── app_en.arb
├── app_uz.arb
├── app_ru.arb
└── l10n.yaml
```

Supported languages: English, Uzbek, Russian (matching legacy platform).

---

## 7. Key Dependencies (`pubspec.yaml`)

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter

  # State & routing
  flutter_riverpod: ^2.5.0
  riverpod_annotation: ^2.3.0
  go_router: ^14.0.0

  # Network
  dio: ^5.4.0
  connectivity_plus: ^6.0.0

  # Storage
  flutter_secure_storage: ^9.0.0
  hive_flutter: ^1.1.0

  # UI
  google_fonts: ^6.2.0
  shimmer: ^3.0.0
  cached_network_image: ^3.3.0
  flutter_animate: ^4.5.0

  # Media
  just_audio: ^0.9.36
  youtube_player_iframe: ^5.1.0
  image_picker: ^1.0.0

  # Utils
  intl: ^0.19.0
  equatable: ^2.0.5
  freezed_annotation: ^2.4.0
  json_annotation: ^4.9.0

  # Push
  firebase_core: ^3.0.0
  firebase_messaging: ^15.0.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  build_runner: ^2.4.0
  freezed: ^2.5.0
  json_serializable: ^6.8.0
  riverpod_generator: ^2.4.0
  mocktail: ^1.0.0
```

---

## 8. State Management Patterns

| Pattern | Usage |
|---------|-------|
| `AsyncNotifier` | Screen-level data fetching |
| `StateNotifier` | Form state, practice sessions |
| `FutureProvider` | One-shot reads (settings) |
| `StreamProvider` | Connectivity, auth state |
| `family` | Parameterized providers (lessonId) |

### Practice session example

```dart
// word_practice_provider.dart
@riverpod
class WordPractice extends _$WordPractice {
  @override
  WordPracticeState build(String lessonId) => WordPracticeState.initial();

  Future<void> loadNextWord(DirectionMode direction) async { ... }
  Future<CheckResult> submitAnswer(String answer) async { ... }
}
```

---

## 9. Adaptive Layout Strategy

```dart
// adaptive_scaffold.dart
Widget build(BuildContext context) {
  return LayoutBuilder(builder: (context, constraints) {
    if (constraints.maxWidth >= 1024) {
      return _ExpandedLayout(navigationItems, child);
    }
    if (constraints.maxWidth >= 600) {
      return _MediumLayout(navigationItems, child);
    }
    return _CompactLayout(navigationItems, child);
  });
}
```

| Layout | Navigation | Content |
|--------|------------|---------|
| Compact | Bottom nav (4–5 items) | Full-width single pane |
| Medium | Navigation rail | Master-detail optional |
| Expanded | Permanent rail | List + detail split pane |

---

## 10. Testing Structure

```
test/
├── unit/
│   ├── domain/
│   │   └── check_sentence_answer_test.dart  # mirrors server validators
│   └── data/
│       └── auth_repository_test.dart
├── widget/
│   ├── word_practice_screen_test.dart
│   └── login_screen_test.dart
└── integration/
    └── student_learning_flow_test.dart
```

---

## 11. Naming Conventions

| Item | Convention | Example |
|------|------------|---------|
| Files | snake_case | `word_practice_screen.dart` |
| Classes | PascalCase | `WordPracticeScreen` |
| Providers | camelCase + Provider | `wordPracticeProvider` |
| Routes | kebab in path | `/learning/words/practice/:lessonId` |
| API models | suffix `Model` | `WordModel` |
| Domain entities | no suffix | `Word` |

---

*Next: [Backend Structure](./05-BACKEND-STRUCTURE.md)*
