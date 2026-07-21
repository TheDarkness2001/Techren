import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'src/core/constants/api_constants.dart';
import 'src/presentation/providers/app_preferences_provider.dart';
import 'src/presentation/providers/auth_provider.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  ApiConstants.assertReleaseConfig();

  // Load theme/locale before first frame so Responsively / web doesn't flash
  // light login then rebuild into dark (looks like "login → loading again").
  final prefs = await SharedPreferences.getInstance();
  final initialLocale = LocaleNotifier.localeFromPrefs(prefs);
  final initialThemeMode = ThemeModeNotifier.themeModeFromPrefs(prefs);

  final container = ProviderContainer(
    overrides: [
      localeProvider.overrideWith((ref) => LocaleNotifier(initialLocale: initialLocale)),
      themeModeProvider.overrideWith((ref) => ThemeModeNotifier(initialThemeMode: initialThemeMode)),
    ],
  );

  // Start session restore immediately (don't wait for SplashScreen mount).
  container.read(authProvider.notifier).bootstrap();

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const TechRenApp(),
    ),
  );
}
