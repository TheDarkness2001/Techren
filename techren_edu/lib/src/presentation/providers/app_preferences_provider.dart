import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/l10n/app_localizations.dart';

const _localeKey = 'app_locale';
const _themeModeKey = 'app_theme_mode';

/// Persisted UI locale (en / ru / uz).
final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) => LocaleNotifier());

/// Persisted theme mode (light / dark / system).
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) => ThemeModeNotifier());

/// [AppLocalizations] for the active locale — use in providers without [BuildContext].
final appLocalizationsProvider = Provider<AppLocalizations>((ref) {
  return AppLocalizations(ref.watch(localeProvider));
});

class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier({Locale? initialLocale}) : super(initialLocale ?? const Locale('en')) {
    if (initialLocale == null) {
      _load();
    }
  }

  static Locale localeFromPrefs(SharedPreferences prefs) {
    final code = prefs.getString(_localeKey);
    if (code != null && _isSupportedCode(code)) {
      return Locale(code);
    }
    return const Locale('en');
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final next = localeFromPrefs(prefs);
    if (next != state) state = next;
  }

  Future<void> setLanguageCode(String code) async {
    if (!_isSupportedCode(code)) return;
    state = Locale(code);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, code);
  }

  static bool _isSupportedCode(String code) => ['en', 'ru', 'uz'].contains(code);
}

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier({ThemeMode? initialThemeMode}) : super(initialThemeMode ?? ThemeMode.system) {
    if (initialThemeMode == null) {
      _load();
    }
  }

  static ThemeMode themeModeFromPrefs(SharedPreferences prefs) {
    final value = prefs.getString(_themeModeKey);
    return switch (value) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final next = themeModeFromPrefs(prefs);
    if (next != state) state = next;
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    final stored = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    await prefs.setString(_themeModeKey, stored);
  }
}
