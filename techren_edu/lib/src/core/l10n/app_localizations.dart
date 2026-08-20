import 'package:flutter/material.dart';

part 'l10n_chat.dart';
part 'l10n_common.dart';
part 'l10n_exams.dart';
part 'l10n_groups.dart';
part 'l10n_ielts.dart';
part 'l10n_payments.dart';
part 'l10n_people.dart';
part 'l10n_typing.dart';

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

  /// Public alias for feature l10n extensions.
  String t({required String en, required String ru, required String uz}) =>
      _t(en: en, ru: ru, uz: uz);

  // —— General ——
  String get appTitle => _t(en: 'TechRen EDU', ru: 'TechRen EDU', uz: 'TechRen EDU');
  String get academyName => _t(en: 'TechRen Academy', ru: 'TechRen Academy', uz: 'TechRen Academy');
  String get signIn => _t(en: 'Sign In', ru: 'Войти', uz: 'Kirish');
  String get signOut => _t(en: 'Sign out', ru: 'Выйти', uz: 'Chiqish');
  String get email => _t(en: 'Email', ru: 'Эл. почта', uz: 'Email');
  String get password => _t(en: 'Password', ru: 'Пароль', uz: 'Parol');
  String get usernameOrEmail => _t(en: 'Username or email', ru: 'Логин или email', uz: 'Login yoki email');
  String get usernameOrEmailHint => _t(
        en: 'Staff/student email, or parent username',
        ru: 'Email сотрудника/ученика или логин родителя',
        uz: 'Xodim/o\'quvchi email yoki ota-ona logini',
      );
  String get usernameOrEmailRequired => _t(
        en: 'Username or email is required',
        ru: 'Укажите логин или email',
        uz: 'Login yoki email kiritilishi shart',
      );
  String get emailRequired => _t(en: 'Email is required', ru: 'Укажите email', uz: 'Email kiritilishi shart');
  String get emailInvalid => _t(en: 'Enter a valid email', ru: 'Введите корректный email', uz: 'To\'g\'ri email kiriting');
  String get passwordRequired => _t(en: 'Password is required', ru: 'Укажите пароль', uz: 'Parol kiritilishi shart');
  String get showPassword => _t(en: 'Show password', ru: 'Показать пароль', uz: 'Parolni ko\'rsatish');
  String get hidePassword => _t(en: 'Hide password', ru: 'Скрыть пароль', uz: 'Parolni yashirish');
  String get sessionEnded => _t(en: 'Session ended', ru: 'Сессия завершена', uz: 'Sessiya tugadi');
  String get signInFailedTitle => _t(en: 'Sign-in failed', ru: 'Ошибка входа', uz: 'Kirish muvaffaqiyatsiz');
  String get signInFailed => _t(en: 'Unable to sign in. Please try again.', ru: 'Не удалось войти. Попробуйте снова.', uz: 'Kirish amalga oshmadi. Qayta urinib ko\'ring.');
  String get invalidCredentials => _t(
        en: 'Invalid username/email or password.',
        ru: 'Неверный логин/email или пароль.',
        uz: 'Login/email yoki parol noto\'g\'ri.',
      );
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
  String get roleParent => _t(en: 'Parent', ru: 'Родитель', uz: 'Ota-ona');
  String get roleStudent => _t(en: 'Student', ru: 'Ученик', uz: 'O\'quvchi');
  String get roleSales => _t(en: 'Sales', ru: 'Продажи', uz: 'Sotuv');
  String get roleReceptionist => _t(en: 'Receptionist', ru: 'Ресепционист', uz: 'Qabulxona');
  String roleNamed(String role) => _t(en: 'Role: $role', ru: 'Роль: $role', uz: 'Rol: $role');

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
  String get navNews => _t(en: 'News', ru: 'Новости', uz: 'Yangiliklar');
  String get navMessages => _t(en: 'Messages', ru: 'Сообщения', uz: 'Xabarlar');
  String get navLearning => _t(en: 'Learning', ru: 'Обучение', uz: 'O\'qitish');
  String get navWords => _t(en: 'Words', ru: 'Слова', uz: 'So\'zlar');
  String get navSentences => _t(en: 'Sentences', ru: 'Предложения', uz: 'Gaplar');
  String get navLearningCms => _t(en: 'Learning CMS', ru: 'CMS обучения', uz: 'O\'qitish CMS');
  String get navContentImport => _t(en: 'Content Import', ru: 'Импорт контента', uz: 'Kontent importi');
  String get navStudentProgress => _t(en: 'Student Progress', ru: 'Прогресс учеников', uz: 'O\'quvchi progressi');
  String get navCompetition => _t(en: 'Competition', ru: 'Соревнование', uz: 'Musobaqa');
  String get navCompetitionHub => _t(en: 'Competition Hub', ru: 'Центр соревнований', uz: 'Musobaqa markazi');
  String get navPeople => _t(en: 'People', ru: 'Люди', uz: 'Odamlar');
  String get navStudentsTeachers => _t(en: 'Students & Staff', ru: 'Ученики и сотрудники', uz: 'O\'quvchilar va xodimlar');
  String get navTeachers => _t(en: 'Teachers', ru: 'Учителя', uz: 'O\'qituvchilar');
  String get navStudents => _t(en: 'Students', ru: 'Ученики', uz: 'O\'quvchilar');
  String get navFinance => _t(en: 'Finance', ru: 'Финансы', uz: 'Moliya');
  String get navPaymentsExams => _t(en: 'Payments', ru: 'Платежи', uz: 'To\'lovlar');
  String get navRevenueReports => _t(en: 'Revenue Reports', ru: 'Отчёты по выручке', uz: 'Daromad hisobotlari');
  String get navStudentWallets => _t(en: 'Student Wallets', ru: 'Кошельки учеников', uz: 'O\'quvchi hamyonlari');
  String get navStaffFinance => _t(en: 'Staff Finance', ru: 'Финансы персонала', uz: 'Xodimlar moliyasi');
  String get navGroups => _t(en: 'Groups', ru: 'Группы', uz: 'Guruhlar');
  String get navRecycleBin => _t(en: 'Recycle Bin', ru: 'Корзина', uz: 'O\'chirilganlar');
  String get navMore => _t(en: 'More', ru: 'Ещё', uz: 'Yana');
  String get navClasses => _t(en: 'Classes', ru: 'Занятия', uz: 'Darslar');
  String get navOverview => _t(en: 'Overview', ru: 'Обзор', uz: 'Umumiy');
  String get navMyChildren => _t(en: 'My Children', ru: 'Мои дети', uz: 'Bolalarim');
  String get navMyClasses => _t(en: 'My Classes', ru: 'Мои занятия', uz: 'Mening darslarim');
  String get navSettings => _t(en: 'Settings', ru: 'Настройки', uz: 'Sozlamalar');
  String get navPlatformSettings => _t(en: 'Platform Settings', ru: 'Настройки платформы', uz: 'Platforma sozlamalari');
  String get navParentAlerts => _t(en: 'Parent Alerts', ru: 'Уведомления родителям', uz: 'Ota-ona xabarlari');
  String get navNotifications => _t(en: 'Notifications', ru: 'Уведомления', uz: 'Bildirishnomalar');

  // —— Student navigation ——
  String get navHome => _t(en: 'Home', ru: 'Главная', uz: 'Bosh sahifa');
  String get navLearn => _t(en: 'Learn', ru: 'Учёба', uz: 'O\'rganish');
  String get navSchedule => _t(en: 'Schedule', ru: 'Расписание', uz: 'Jadval');
  String get navProgress => _t(en: 'Progress', ru: 'Прогресс', uz: 'Taraqqiyot');
  String get navProfile => _t(en: 'Profile', ru: 'Профиль', uz: 'Profil');
  String get mySchedule => _t(en: 'My Schedule', ru: 'Моё расписание', uz: 'Mening jadvalim');
  String get navHomework => _t(en: 'Homework', ru: 'Домашка', uz: 'Uy vazifa');
  String get childSchedule => _t(en: 'Schedule', ru: 'Расписание', uz: 'Jadval');
  String get noLessonsThisWeek => _t(en: 'No lessons scheduled this week.', ru: 'На этой неделе уроков нет.', uz: 'Bu hafta darslar yo‘q.');
  String get homeworkAccuracy => _t(en: 'Accuracy', ru: 'Точность', uz: 'Aniqlik');
  String get homeworkAttempts => _t(en: 'Attempts', ru: 'Попытки', uz: 'Urinishlar');
  String get homeworkCorrect => _t(en: 'Correct', ru: 'Верно', uz: 'To‘g‘ri');
  String get noHomeworkYet => _t(en: 'No homework practice yet.', ru: 'Пока нет практики.', uz: 'Hali mashq yo‘q.');
  String get childScheduleHint => _t(en: 'This week\'s classes', ru: 'Уроки на этой неделе', uz: 'Bu hafta darslari');
  String get childHomeworkHint => _t(en: 'Practice progress', ru: 'Прогресс практики', uz: 'Mashq taraqqiyoti');
  String get parentMessagesHint => _t(en: 'Support and teacher chats', ru: 'Поддержка и чаты с учителями', uz: 'Yordam va o‘qituvchi chatlari');
  String get xpAchievements => _t(en: 'XP & Achievements', ru: 'XP и достижения', uz: 'XP va yutuqlar');
  String get teacherFeedback => _t(en: 'Teacher Feedback', ru: 'Отзывы учителя', uz: 'O\'qituvchi fikri');
  String get commentsAfterClass => _t(en: 'Comments after class', ru: 'Комментарии после урока', uz: 'Darsdan keyingi izohlar');
  String get myExams => _t(en: 'My Exams', ru: 'Мои экзамены', uz: 'Mening imtihonlarim');
  String get myPayments => _t(en: 'My Payments', ru: 'Мои платежи', uz: 'Mening to\'lovlarim');
  String get myWallet => _t(en: 'My Wallet', ru: 'Мой кошелёк', uz: 'Mening hamyonim');
  String get walletSubtitle => _t(en: 'Balance, top-up & history', ru: 'Баланс, пополнение и история', uz: 'Balans, to\'ldirish va tarix');
  String get competitionSubtitle => _t(en: 'Penalties & presentation scores', ru: 'Штрафы и оценки выступлений', uz: 'Jarimalar va taqdimot ballari');
  String get gamificationSubtitle => _t(en: 'Level, streak, leaderboard', ru: 'Уровень, серия, рейтинг', uz: 'Daraja, seriya, reyting');
  String get accountInactive => _t(
        en: 'Account locked — payment required. Open Payments or contact administration.',
        ru: 'Аккаунт заблокирован — требуется оплата. Откройте Платежи или обратитесь в администрацию.',
        uz: 'Hisob bloklangan — to\'lov talab qilinadi. To\'lovlar bo\'limiga o\'ting yoki ma\'muriyatga murojaat qiling.',
      );

  // —— Student home ——
  String get latestAnnouncements => _t(en: 'Latest announcements', ru: 'Последние объявления', uz: 'So\'nggi e\'lonlar');
  String get noPostsYet => _t(en: 'No posts yet. Check back soon.', ru: 'Пока нет записей. Загляните позже.', uz: 'Hozircha postlar yo\'q. Tez orada qaytib keling.');
  String get latestFeedback => _t(en: 'Latest feedback', ru: 'Последние отзывы', uz: 'So\'nggi fikrlar');
  String get viewAll => _t(en: 'View all', ru: 'Все', uz: 'Hammasi');
  String get accountStatus => _t(en: 'Account status', ru: 'Статус аккаунта', uz: 'Hisob holati');
  String get examReady => _t(en: 'Exam ready', ru: 'Готов к экзамену', uz: 'Imtihonga tayyor');
  String get yesLabel => _t(en: 'Yes', ru: 'Да', uz: 'Ha');
  String get noLabel => _t(en: 'No', ru: 'Нет', uz: 'Yo\'q');
  String get classLabel => _t(en: 'Class', ru: 'Класс', uz: 'Sinf');
  String get statusActive => _t(en: 'active', ru: 'активен', uz: 'faol');
  String get statusInactive => _t(en: 'inactive', ru: 'неактивен', uz: 'nofaol');
  String get homeworkScore => _t(en: 'Homework', ru: 'Домашка', uz: 'Uy vazifa');
  String get wordsScore => _t(en: 'Words', ru: 'Слова', uz: 'So\'zlar');
  String get sentenceScore => _t(en: 'Sentence', ru: 'Предложение', uz: 'Gap');
  String get behaviorScore => _t(en: 'Behavior', ru: 'Поведение', uz: 'Xulq');
  String get participationScore => _t(en: 'Participation', ru: 'Участие', uz: 'Faollik');
  String get notifications => _t(en: 'Notifications', ru: 'Уведомления', uz: 'Bildirishnomalar');
  String get noNotificationsYet => _t(en: 'No notifications yet', ru: 'Уведомлений пока нет', uz: 'Hali bildirishnomalar yo\'q');
  String get loadingDashboard => _t(en: 'Loading dashboard...', ru: 'Загрузка главной...', uz: 'Bosh sahifa yuklanmoqda...');
  String get loadingLabel => _t(en: 'Loading...', ru: 'Загрузка...', uz: 'Yuklanmoqda...');
  String get errorLabel => _t(en: 'Error', ru: 'Ошибка', uz: 'Xato');
  String get redirecting => _t(en: 'Redirecting...', ru: 'Перенаправление...', uz: 'Yo\'naltirilmoqda...');

  // —— Parent chrome ——
  String get parentPortal => _t(en: 'Parent Portal', ru: 'Портал родителя', uz: 'Ota-ona portali');
  String get parentPortalDisabled => _t(en: 'Parent portal disabled', ru: 'Портал родителя отключён', uz: 'Ota-ona portali o\'chirilgan');
  String get parentPortalDisabledMessage => _t(
        en: 'Ask your branch administrator to enable the parent portal in platform settings.',
        ru: 'Попросите администратора филиала включить портал родителя в настройках платформы.',
        uz: 'Filial administratoridan platforma sozlamalarida ota-ona portalini yoqishni so\'rang.',
      );
  String get noLinkedChildren => _t(en: 'No linked children', ru: 'Нет привязанных детей', uz: 'Bog\'langan bolalar yo\'q');
  String get noLinkedChildrenMessage => _t(
        en: 'No students are linked to this parent account yet. Contact your branch administrator.',
        ru: 'К этому аккаунту пока не привязаны ученики. Обратитесь к администратору филиала.',
        uz: 'Bu ota-ona hisobiga hali o\'quvchilar bog\'lanmagan. Filial administratoriga murojaat qiling.',
      );
  String get selectAChild => _t(en: 'Select a child', ru: 'Выберите ребёнка', uz: 'Bolani tanlang');
  String get selectAChildSubtitle => _t(
        en: 'View overview, feedback, attendance, and exams',
        ru: 'Обзор, отзывы, посещаемость и экзамены',
        uz: 'Umumiy ma\'lumot, fikrlar, davomat va imtihonlar',
      );
  String get openingChildProfile => _t(en: 'Opening child profile...', ru: 'Открытие профиля ребёнка...', uz: 'Bola profili ochilmoqda...');
  String get switchChild => _t(en: 'Switch child', ru: 'Сменить ребёнка', uz: 'Bolani almashtirish');
  String get allChildren => _t(en: 'All children', ru: 'Все дети', uz: 'Barcha bolalar');
  String get childLabel => _t(en: 'Child', ru: 'Ребёнок', uz: 'Bola');

  // —— Teacher profile shortcuts ——
  String get learningYourSubjects => _t(en: 'Your subjects, unlocks & content', ru: 'Предметы, разблокировки и контент', uz: 'Fanlar, ochilishlar va kontent');
  String get contentImportSubtitle => _t(en: 'DOCX, OCR & bulk import', ru: 'DOCX, OCR и массовый импорт', uz: 'DOCX, OCR va ommaviy import');
  String get studentProgressSubtitle => _t(en: 'Accuracy and practice stats', ru: 'Точность и статистика практики', uz: 'Aniqlik va mashq statistikasi');
  String get competitionRecordSubtitle => _t(en: 'Record penalties & presentations', ru: 'Штрафы и выступления', uz: 'Jarimalar va taqdimotlar');
  String get myEarnings => _t(en: 'My Earnings', ru: 'Мой доход', uz: 'Mening daromadim');
  String get myEarningsSubtitle => _t(en: 'View earnings and payouts', ru: 'Доходы и выплаты', uz: 'Daromad va to\'lovlar');

  // —— Session / API errors ——
  String get sessionExpired => _t(en: 'Your session expired. Please sign in again.', ru: 'Сессия истекла. Войдите снова.', uz: 'Sessiya muddati tugadi. Qayta kiring.');
  String get sessionIdle => _t(en: 'Signed out after being idle. Please sign in again.', ru: 'Выход из-за бездействия. Войдите снова.', uz: 'Harakatsizlik tufayli chiqarildi. Qayta kiring.');
  String get sessionTaskLeave => _t(
        en: 'Signed out because you left the app during a learning task.',
        ru: 'Выход, потому что вы покинули приложение во время задания.',
        uz: 'O\'qish vazifasi paytida ilovadan chiqqaningiz uchun tizimdan chiqarildi.',
      );
  String get errorForbidden => _t(en: 'You do not have permission to do that.', ru: 'Недостаточно прав для этого действия.', uz: 'Bu amal uchun ruxsat yo\'q.');
  String get errorUnauthorized => _t(en: 'Please sign in again.', ru: 'Войдите снова.', uz: 'Qayta kiring.');
  String get errorNotFound => _t(
        en: 'Cannot reach the TechRen API (404). Install the latest app update or check the server URL.',
        ru: 'Не удаётся связаться с API TechRen (404). Обновите приложение или проверьте адрес сервера.',
        uz: 'TechRen API ga ulanib bo\'lmadi (404). Ilovani yangilang yoki server manzilini tekshiring.',
      );
  String get errorServer => _t(en: 'Server error. Please try again in a moment.', ru: 'Ошибка сервера. Попробуйте чуть позже.', uz: 'Server xatosi. Birozdan so\'ng qayta urinib ko\'ring.');
  String get errorTimeout => _t(en: 'Connection timed out. Please try again.', ru: 'Время ожидания истекло. Попробуйте снова.', uz: 'Ulanish vaqti tugadi. Qayta urinib ko\'ring.');
  String get errorConnection => _t(en: 'Cannot reach the server. Check that the API is running.', ru: 'Сервер недоступен. Проверьте, что API запущен.', uz: 'Serverga ulanib bo\'lmadi. API ishlayotganini tekshiring.');
  String get errorNetwork => _t(en: 'Network error. Please try again.', ru: 'Ошибка сети. Попробуйте снова.', uz: 'Tarmoq xatosi. Qayta urinib ko\'ring.');
  String get errorValidation => _t(en: 'Please check the form and try again.', ru: 'Проверьте форму и попробуйте снова.', uz: 'Formani tekshirib, qayta urinib ko\'ring.');
  String get errorInactiveAccount => _t(en: 'Account is inactive.', ru: 'Аккаунт неактивен.', uz: 'Hisob nofaol.');
  String get errorParentPortalOff => _t(en: 'Parent portal is not enabled.', ru: 'Портал родителя не включён.', uz: 'Ota-ona portali yoqilmagan.');
  String get errorRateLimit => _t(en: 'Too many login attempts. Please wait a few minutes.', ru: 'Слишком много попыток входа. Подождите несколько минут.', uz: 'Kirish urinishlari ko\'p. Bir necha daqiqa kuting.');

  String navLabelForRoute(String route) {
    final path = route.split('?').first;
    if (path.endsWith('/parent/home') || path == '/parent/home') return navMyChildren;
    if (path.contains('/parent/child/')) {
      if (path.endsWith('/overview')) return navOverview;
      if (path.endsWith('/payments')) return navPaymentsExams;
      if (path.endsWith('/feedback')) return navFeedback;
      if (path.endsWith('/attendance')) return navAttendance;
      if (path.endsWith('/exams')) return navExams;
      if (path.endsWith('/schedule')) return childSchedule;
      if (path.endsWith('/homework')) return navHomework;
    }
    if (path.endsWith('/learn')) return navLearn;
    if (path.endsWith('/progress') && !path.contains('student-progress')) return navProgress;
    if (path.endsWith('/dashboard')) return navHome;
    if (path.endsWith('/branches')) return navBranches;
    if (path.contains('/people')) return navPeople;
    if (path.endsWith('/more')) return navMore;
    if (path.endsWith('/classes')) return navClasses;
    if (path.endsWith('/attendance')) return navAttendance;
    if (path.endsWith('/learning')) return navLearning;
    if (path.endsWith('/messages')) return navMessages;
    if (path.endsWith('/profile')) return navProfile;
    if (path.contains('/schedule')) return navSchedule;
    return '';
  }

  String? _resolvedErrorCode(String? code, String? fallback) {
    if (code != null && code.isNotEmpty) return code;
    const stored = {'SESSION_EXPIRED', 'SESSION_IDLE', 'TASK_LEAVE'};
    if (fallback != null && stored.contains(fallback)) return fallback;
    return null;
  }

  bool isSessionError({String? code, String? fallback}) {
    final resolved = _resolvedErrorCode(code, fallback);
    if (resolved == 'SESSION_EXPIRED' || resolved == 'SESSION_IDLE' || resolved == 'TASK_LEAVE') {
      return true;
    }
    final text = fallback ?? '';
    return text.startsWith('Signed out') || text.startsWith('Your session');
  }

  String messageForError({String? code, String? fallback, bool forLogin = false}) {
    switch (_resolvedErrorCode(code, fallback)) {
      case 'UNAUTHORIZED':
        return forLogin ? invalidCredentials : errorUnauthorized;
      case 'FORBIDDEN':
        return errorForbidden;
      case 'INACTIVE_ACCOUNT':
      case 'INACTIVE_STUDENT':
        return errorInactiveAccount;
      case 'NOT_FOUND':
        return errorNotFound;
      case 'SERVER':
      case 'SERVER_ERROR':
        return errorServer;
      case 'TIMEOUT':
        return errorTimeout;
      case 'CONNECTION':
        return errorConnection;
      case 'NETWORK':
        return errorNetwork;
      case 'VALIDATION_ERROR':
        return errorValidation;
      case 'SESSION_EXPIRED':
        return sessionExpired;
      case 'SESSION_IDLE':
        return sessionIdle;
      case 'TASK_LEAVE':
        return sessionTaskLeave;
      case 'NOT_ENABLED':
        return errorParentPortalOff;
      case 'RATE_LIMIT':
        return errorRateLimit;
    }
    final text = fallback ?? '';
    if (text.contains('left the app during a learning task')) return sessionTaskLeave;
    if (text.toLowerCase().contains('session expired')) return sessionExpired;
    if (text.contains('being idle')) return sessionIdle;
    if (text == 'Invalid email or password.' || text == 'Invalid username/email or password') {
      return invalidCredentials;
    }
    if (text.isNotEmpty) return text;
    return signInFailed;
  }

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
