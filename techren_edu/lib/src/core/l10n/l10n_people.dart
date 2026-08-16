part of 'app_localizations.dart';

extension L10nPeople on AppLocalizations {
  String get searchNameEmail => t(en: 'Name or email…', ru: 'Имя или email…', uz: 'Ism yoki email…');
  String get searchNameIdPhone => t(en: 'Name, ID, phone…', ru: 'Имя, ID, телефон…', uz: 'Ism, ID, telefon…');
  String get noStudents => t(en: 'No students', ru: 'Нет учеников', uz: 'O\'quvchilar yo\'q');
  String get noStudentsMessage => t(en: 'Add your first student to get started.', ru: 'Добавьте первого ученика.', uz: 'Birinchi o\'quvchini qo\'shing.');
  String get noStaff => t(en: 'No staff', ru: 'Нет сотрудников', uz: 'Xodimlar yo\'q');
  String get noStaffMessage => t(en: 'Add staff to manage your branch.', ru: 'Добавьте сотрудников для филиала.', uz: 'Filial uchun xodim qo\'shing.');
  String get addStudent => t(en: 'Add Student', ru: 'Добавить ученика', uz: 'O\'quvchi qo\'shish');
  String get addTeacher => t(en: 'Add Teacher', ru: 'Добавить учителя', uz: 'O\'qituvchi qo\'shish');
  String get staffDetails => t(en: 'Staff details', ru: 'Данные сотрудника', uz: 'Xodim ma\'lumotlari');
  String get subjectsRequired => t(en: 'Subjects *', ru: 'Предметы *', uz: 'Fanlar *');
  String get tapSubjectsToAssign => t(en: 'Tap subjects to assign (not comma-separated)', ru: 'Нажмите предметы для назначения', uz: 'Fanlarni belgilash uchun bosing');
  String get subjectsCommaSeparated => t(en: 'Subjects (comma separated)', ru: 'Предметы (через запятую)', uz: 'Fanlar (vergul bilan)');
  String get roleAndBranch => t(en: 'Role & branch', ru: 'Роль и филиал', uz: 'Rol va filial');
  String get department => t(en: 'Department', ru: 'Отдел', uz: 'Bo\'lim');
  String get nameEmailPasswordRequired => t(
        en: 'Name, email, and password (min 8 chars) are required',
        ru: 'Имя, email и пароль (мин. 8 символов) обязательны',
        uz: 'Ism, email va parol (kamida 8 belgi) shart',
      );
  String get selectAtLeastOneSubject => t(en: 'Select at least one subject', ru: 'Выберите хотя бы один предмет', uz: 'Kamida bitta fanni tanlang');
  String get selectABranch => t(en: 'Select a branch', ru: 'Выберите филиал', uz: 'Filialni tanlang');
  String teacherCreated(String name) => t(en: 'Teacher $name created', ru: 'Учитель $name создан', uz: 'O\'qituvchi $name yaratildi');
  String studentCreated(String name) => t(en: 'Student $name created', ru: 'Ученик $name создан', uz: 'O\'quvchi $name yaratildi');
  String get fullNameRequired => t(en: 'Full name *', ru: 'Полное имя *', uz: 'To\'liq ism *');
  String get nameActions => t(en: 'Name Actions', ru: 'Имя', uz: 'Ism');
  String get profile => t(en: 'Profile', ru: 'Профиль', uz: 'Profil');
  String get dateOfBirth => t(en: 'Date of Birth', ru: 'Дата рождения', uz: 'Tug\'ilgan sana');
  String get gender => t(en: 'Gender', ru: 'Пол', uz: 'Jins');
  String get bloodGroup => t(en: 'Blood Group', ru: 'Группа крови', uz: 'Qon guruhi');
  String get address => t(en: 'Address', ru: 'Адрес', uz: 'Manzil');
  String get medicalConditions => t(en: 'Medical Conditions', ru: 'Мед. сведения', uz: 'Tibbiy holat');
  String get noDataFound => t(en: 'No data found', ru: 'Нет данных', uz: 'Ma\'lumot yo\'q');
  String get studentCredentials => t(en: 'Student Credentials', ru: 'Учётные данные ученика', uz: 'O\'quvchi login');
  String get studentPasswordRequired => t(en: 'Student password *', ru: 'Пароль ученика *', uz: 'O\'quvchi paroli *');
  String get parentPortalLogin => t(en: 'Parent portal login', ru: 'Вход родителя', uz: 'Ota-ona portali');
  String get parentPortalLoginHint => t(
        en: 'Optional. Username + password for the parent app (not the student email).',
        ru: 'Необязательно. Логин и пароль для приложения родителя.',
        uz: 'Ixtiyoriy. Ota-ona ilovasi uchun login va parol.',
      );
  String get relation => t(en: 'Relation', ru: 'Кем приходится', uz: 'Qarindoshlik');
  String get parentName => t(en: 'Parent name', ru: 'Имя родителя', uz: 'Ota-ona ismi');
  String get parentPhone => t(en: 'Parent phone', ru: 'Телефон родителя', uz: 'Ota-ona telefoni');
  String get parentUsername => t(en: 'Parent username', ru: 'Логин родителя', uz: 'Ota-ona logini');
  String get parentUsernameHint => t(en: 'Memorable login for parent portal', ru: 'Удобный логин для портала родителя', uz: 'Ota-ona portali uchun login');
  String get parentPassword => t(en: 'Parent password', ru: 'Пароль родителя', uz: 'Ota-ona paroli');
  String get parentRelation => t(en: 'Parent relation', ru: 'Кем приходится', uz: 'Qarindoshlik');
  String get subjectsAmount => t(en: 'Subjects Amount', ru: 'Суммы по предметам', uz: 'Fan summalari');
  String get addSubject => t(en: '+ Add Subject', ru: '+ Предмет', uz: '+ Fan qo\'shish');
  String get coursePriceMonthly => t(en: 'Course price (monthly)', ru: 'Цена курса (в месяц)', uz: 'Kurs narxi (oylik)');
  String get studentMonthlyFee => t(en: 'Student monthly fee', ru: 'Ежемесячная плата ученика', uz: 'O\'quvchi oylik to\'lovi');
  String get enterValidCoursePrice => t(en: 'Enter a valid course price', ru: 'Укажите корректную цену курса', uz: 'To\'g\'ri kurs narxini kiriting');
  String get phoneOptional => t(en: 'Phone (optional)', ru: 'Телефон (необязательно)', uz: 'Telefon (ixtiyoriy)');
  String get parentNameOptional => t(en: 'Parent name (optional)', ru: 'Имя родителя (необязательно)', uz: 'Ota-ona ismi (ixtiyoriy)');
  String get parentPhoneOptional => t(en: 'Parent phone (optional)', ru: 'Телефон родителя (необязательно)', uz: 'Ota-ona telefoni (ixtiyoriy)');
  String phoneLabel(String phone) => t(en: 'Phone: $phone', ru: 'Телефон: $phone', uz: 'Telefon: $phone');
  String parentLabel(String name) => t(en: 'Parent: $name', ru: 'Родитель: $name', uz: 'Ota-ona: $name');
  String get ieltsPrepAccess => t(en: 'IELTS Preparation access', ru: 'Доступ к IELTS', uz: 'IELTS tayyorgarlik ruxsati');
  String get photoReadFailed => t(en: 'Could not read the selected image. Try another file.', ru: 'Не удалось прочитать изображение. Выберите другой файл.', uz: 'Rasmni o\'qib bo\'lmadi. Boshqa fayl tanlang.');
  String get profilePhotoUpdated => t(en: 'Profile photo updated', ru: 'Фото профиля обновлено', uz: 'Profil rasmi yangilandi');
  String uploadFailed(String error) => t(en: 'Upload failed: $error', ru: 'Ошибка загрузки: $error', uz: 'Yuklash xatosi: $error');
  String get goBackArrow => t(en: '← Back', ru: '← Назад', uz: '← Orqaga');
}
