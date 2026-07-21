import 'package:flutter/material.dart';

/// App UI strings for English, Russian, and Uzbek.
class AppLocalizations {
  const AppLocalizations(this.locale);

  final Locale locale;

  static const supportedLocales = [
    Locale('en'),
    Locale('ru'),
    Locale('uz'),
  ];

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  static AppLocalizations of(BuildContext context) {
    final value = Localizations.of<AppLocalizations>(context, AppLocalizations);
    assert(value != null, 'AppLocalizations not found in context');
    return value!;
  }

  static AppLocalizations fromLocale(Locale locale) => AppLocalizations(locale);

  String _t({required String en, required String ru, required String uz}) {
    switch (locale.languageCode) {
      case 'ru':
        return ru;
      case 'uz':
        return uz;
      default:
        return en;
    }
  }

  // —— General ——
  String get appTitle => _t(en: 'TechRen EDU', ru: 'TechRen EDU', uz: 'TechRen EDU');
  String get academyName => _t(en: 'TechRen Academy', ru: 'TechRen Academy', uz: 'TechRen Academy');
  String get signIn => _t(en: 'Sign In', ru: 'Войти', uz: 'Kirish');
  String get signOut => _t(en: 'Sign out', ru: 'Выйти', uz: 'Chiqish');
  String get email => _t(en: 'Email', ru: 'Эл. почта', uz: 'Email');
  String get password => _t(en: 'Password', ru: 'Пароль', uz: 'Parol');
  String get emailRequired => _t(en: 'Email is required', ru: 'Укажите email', uz: 'Email kiritilishi shart');
  String get emailInvalid => _t(en: 'Enter a valid email', ru: 'Введите корректный email', uz: 'To\'g\'ri email kiriting');
  String get passwordRequired => _t(en: 'Password is required', ru: 'Укажите пароль', uz: 'Parol kiritilishi shart');
  String get signInFailed => _t(en: 'Unable to sign in. Please try again.', ru: 'Не удалось войти. Попробуйте снова.', uz: 'Kirish amalga oshmadi. Qayta urinib ko\'ring.');
  String get openNavigation => _t(en: 'Open navigation', ru: 'Открыть навигацию', uz: 'Navigatsiyani ochish');
  String get primaryNavigation => _t(en: 'Primary navigation', ru: 'Основная навигация', uz: 'Asosiy navigatsiya');
  String get mainNavigation => _t(en: 'Main navigation', ru: 'Главная навигация', uz: 'Asosiy menyu');
  String get staffWorkspace => _t(en: 'Staff workspace', ru: 'Рабочее пространство', uz: 'Xodimlar paneli');

  // —— Appearance ——
  String get appearance => _t(en: 'Appearance', ru: 'Оформление', uz: 'Ko\'rinish');
  String get language => _t(en: 'Language', ru: 'Язык', uz: 'Til');
  String get themeLight => _t(en: 'Light', ru: 'Светлая', uz: 'Yorug\'');
  String get themeDark => _t(en: 'Dark', ru: 'Тёмная', uz: 'Qorong\'u');
  String get themeSystem => _t(en: 'System', ru: 'Системная', uz: 'Tizim');

  // —— Roles ——
  String get roleFounder => _t(en: 'Founder', ru: 'Основатель', uz: 'Asoschi');
  String get roleAdmin => _t(en: 'Admin', ru: 'Админ', uz: 'Admin');
  String get roleManager => _t(en: 'Manager', ru: 'Менеджер', uz: 'Menejer');
  String get roleTeacher => _t(en: 'Teacher', ru: 'Учитель', uz: 'O\'qituvchi');
  String get roleStaff => _t(en: 'Staff', ru: 'Сотрудник', uz: 'Xodim');

  // —— Login brand panel ——
  String get loginTagline => _t(
        en: 'Enterprise education management for modern academies — scheduling, learning, finance, and progress in one platform.',
        ru: 'Корпоративное управление образованием — расписание, обучение, финансы и прогресс в одной платформе.',
        uz: 'Zamonaviy akademiyalar uchun ta\'lim boshqaruvi — jadval, o\'qish, moliya va progress bitta platformada.',
      );
  String get loginFeatureScheduling => _t(en: 'Smart scheduling & attendance', ru: 'Умное расписание и посещаемость', uz: 'Aqlli jadval va davomat');
  String get loginFeatureLearning => _t(en: 'Words, sentences, listening & video modules', ru: 'Слова, предложения, аудирование и видео', uz: 'So\'zlar, gaplar, tinglash va video modullar');
  String get loginFeatureProgress => _t(en: 'Real-time progress and revenue insights', ru: 'Прогресс и выручка в реальном времени', uz: 'Real vaqtda progress va daromad');

  // —— Staff navigation ——
  String get navDashboard => _t(en: 'Dashboard', ru: 'Панель', uz: 'Bosh sahifa');
  String get navBranches => _t(en: 'Branches', ru: 'Филиалы', uz: 'Filiallar');
  String get navTimetable => _t(en: 'Timetable', ru: 'Расписание', uz: 'Jadval');
  String get navAttendance => _t(en: 'Attendance', ru: 'Посещаемость', uz: 'Davomat');
  String get navStudentAttendance => _t(en: 'Student Attendance', ru: 'Посещаемость учеников', uz: 'O\'quvchi davomati');
  String get navTeacherAttendance => _t(en: 'Teacher Attendance', ru: 'Посещаемость учителей', uz: 'O\'qituvchi davomati');
  String get navExams => _t(en: 'Exams', ru: 'Экзамены', uz: 'Imtihonlar');
  String get navFeedback => _t(en: 'Feedback', ru: 'Отзывы', uz: 'Fikr-mulohaza');
  String get navLearning => _t(en: 'Learning', ru: 'Обучение', uz: 'O\'qitish');
  String get navWords => _t(en: 'Words', ru: 'Слова', uz: 'So\'zlar');
  String get navSentences => _t(en: 'Sentences', ru: 'Предложения', uz: 'Gaplar');
  String get navLearningCms => _t(en: 'Learning CMS', ru: 'CMS обучения', uz: 'O\'qitish CMS');
  String get navContentImport => _t(en: 'Content Import', ru: 'Импорт контента', uz: 'Kontent importi');
  String get navStudentProgress => _t(en: 'Student Progress', ru: 'Прогресс учеников', uz: 'O\'quvchi progressi');
  String get navCompetition => _t(en: 'Competition', ru: 'Соревнование', uz: 'Musobaqa');
  String get navCompetitionHub => _t(en: 'Competition Hub', ru: 'Центр соревнований', uz: 'Musobaqa markazi');
  String get navPeople => _t(en: 'People', ru: 'Люди', uz: 'Odamlar');
  String get navStudentsTeachers => _t(en: 'Students & Teachers', ru: 'Ученики и учителя', uz: 'O\'quvchilar va o\'qituvchilar');
  String get navFinance => _t(en: 'Finance', ru: 'Финансы', uz: 'Moliya');
  String get navPaymentsExams => _t(en: 'Payments', ru: 'Платежи', uz: 'To\'lovlar');
  String get navRevenueReports => _t(en: 'Revenue Reports', ru: 'Отчёты по выручке', uz: 'Daromad hisobotlari');
  String get navStudentWallets => _t(en: 'Student Wallets', ru: 'Кошельки учеников', uz: 'O\'quvchi hamyonlari');
  String get navStaffFinance => _t(en: 'Staff Finance', ru: 'Финансы персонала', uz: 'Xodimlar moliyasi');
  String get navGroups => _t(en: 'Groups', ru: 'Группы', uz: 'Guruhlar');
  String get navRecycleBin => _t(en: 'Recycle Bin', ru: 'Корзина', uz: 'Chiqindilar qutisi');
  String get navSettings => _t(en: 'Settings', ru: 'Настройки', uz: 'Sozlamalar');
  String get navPlatformSettings => _t(en: 'Platform Settings', ru: 'Настройки платформы', uz: 'Platforma sozlamalari');
  String get navParentAlerts => _t(en: 'Parent Alerts', ru: 'Уведомления родителям', uz: 'Ota-ona xabarlari');
  String get navNotifications => _t(en: 'Notifications', ru: 'Уведомления', uz: 'Bildirishnomalar');

  // —— Student navigation ——
  String get navHome => _t(en: 'Home', ru: 'Главная', uz: 'Bosh sahifa');
  String get navLearn => _t(en: 'Learn', ru: 'Учиться', uz: 'O\'rganish');
  String get navSchedule => _t(en: 'Schedule', ru: 'Расписание', uz: 'Jadval');
  String get navProgress => _t(en: 'Progress', ru: 'Прогресс', uz: 'Progress');
  String get navProfile => _t(en: 'Profile', ru: 'Профиль', uz: 'Profil');
  String get mySchedule => _t(en: 'My Schedule', ru: 'Моё расписание', uz: 'Mening jadvalim');
  String get xpAchievements => _t(en: 'XP & Achievements', ru: 'XP и достижения', uz: 'XP va yutuqlar');
  String get teacherFeedback => _t(en: 'Teacher Feedback', ru: 'Отзывы учителя', uz: 'O\'qituvchi fikri');
  String get commentsAfterClass => _t(en: 'Comments after class', ru: 'Комментарии после урока', uz: 'Darsdan keyingi izohlar');
  String get myExams => _t(en: 'My Exams', ru: 'Мои экзамены', uz: 'Mening imtihonlarim');
  String get myPayments => _t(en: 'My Payments', ru: 'Мои платежи', uz: 'Mening to\'lovlarim');
  String get myWallet => _t(en: 'My Wallet', ru: 'Мой кошелёк', uz: 'Mening hamyonim');
  String get walletSubtitle => _t(en: 'Balance, top-up & history', ru: 'Баланс, пополнение и история', uz: 'Balans, to\'ldirish va tarix');
  String get competitionSubtitle => _t(en: 'Penalties & presentation scores', ru: 'Штрафы и оценки выступлений', uz: 'Jarimalar va taqdimot ballari');
  String get gamificationSubtitle => _t(en: 'Level, streak, leaderboard', ru: 'Уровень, серия, рейтинг', uz: 'Daraja, seriya, reyting');
  String get accountInactive => _t(en: 'Account inactive. Contact administration.', ru: 'Аккаунт неактивен. Обратитесь в администрацию.', uz: 'Hisob faol emas. Ma\'muriyatga murojaat qiling.');

  String roleLabelFor({required bool isFounder, required bool isAdmin, required bool isManager, required bool isTeacher}) {
    if (isFounder) return roleFounder;
    if (isAdmin) return roleAdmin;
    if (isManager) return roleManager;
    if (isTeacher) return roleTeacher;
    return roleStaff;
  }
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'ru', 'uz'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async => AppLocalizations(locale);

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) => false;
}

extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
