import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:techren_edu/src/core/constants/app_constants.dart';
import 'package:techren_edu/src/core/l10n/app_localizations.dart';
import 'package:techren_edu/src/core/theme/app_theme.dart';
import 'package:techren_edu/src/domain/entities/typing.dart';
import 'package:techren_edu/src/presentation/features/auth/screens/login_screen.dart';
import 'package:techren_edu/src/presentation/features/exams/widgets/exams_widgets.dart';
import 'package:techren_edu/src/presentation/features/typing/widgets/typing_widgets.dart';
import 'package:techren_edu/src/presentation/providers/app_update_provider.dart';

const _widths = <double>[
  320, 360, 375, 390, 414, 428, 768, 820, 1024, 1280, 1366, 1440,
];

Widget _harness({required Size size, required Widget child}) {
  return ProviderScope(
    overrides: [appUpdateProvider.overrideWith((ref) async => null)],
    child: MediaQuery(
      data: MediaQueryData(size: size),
      child: MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Scaffold(body: child),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  testWidgets('login, exam header, and typing grid do not overflow at 12 widths', (tester) async {
    final overflows = <String>[];
    final oldOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      final text = details.toString();
      if (text.contains('overflowed') || text.contains('OVERFLOW')) {
        overflows.add(text);
      }
      oldOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = oldOnError);

    const dash = TypingDashboard(
      subjectId: 's1',
      level: 2,
      xp: 120,
      xpInLevel: 20,
      xpToNextLevel: 80,
      bestWpm: 42,
      averageWpm: 31.5,
      accuracy: 96,
      testsCompleted: 4,
    );

    for (final width in _widths) {
      final size = Size(width, width < 600 ? 720 : 900);
      await tester.binding.setSurfaceSize(size);

      await tester.pumpWidget(
        _harness(
          size: size,
          child: const LoginScreen(),
        ),
      );
      await tester.pump();
      expect(find.byType(LoginScreen), findsOneWidget, reason: 'login at $width');
      if (width >= AppConstants.expandedBreakpoint) {
        expect(find.textContaining('TechRen'), findsWidgets, reason: 'brand panel at $width');
      } else {
        expect(find.textContaining('Username'), findsOneWidget, reason: 'stacked form at $width');
      }

      await tester.pumpWidget(
        _harness(
          size: size,
          child: ExamsPageHeader(
            showArchived: false,
            onToggleArchived: () {},
            onAddExam: () {},
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(ExamsPageHeader), findsOneWidget, reason: 'exam header at $width');

      await tester.pumpWidget(
        _harness(
          size: size,
          child: SingleChildScrollView(child: TypingStatGrid(dashboard: dash)),
        ),
      );
      await tester.pump();
      expect(find.byType(TypingStatGrid), findsOneWidget, reason: 'typing grid at $width');
    }

    await tester.binding.setSurfaceSize(null);
    expect(overflows, isEmpty, reason: overflows.join('\n---\n'));
  });
}
