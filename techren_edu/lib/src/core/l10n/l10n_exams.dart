part of 'app_localizations.dart';

extension L10nExams on AppLocalizations {
  String get manageExams => t(en: 'Manage Exams', ru: 'Управление экзаменами', uz: 'Imtihonlarni boshqarish');
  String get addNewExam => t(en: 'Add New Exam', ru: 'Новый экзамен', uz: 'Yangi imtihon');
  String get activeExams => t(en: 'Active Exams', ru: 'Активные экзамены', uz: 'Faol imtihonlar');
  String get archived => t(en: 'Archived', ru: 'Архив', uz: 'Arxiv');
  String get noArchivedExams => t(en: 'No archived exams', ru: 'Нет архивных экзаменов', uz: 'Arxiv imtihonlar yo\'q');
  String get archivedExamsHint => t(en: 'Completed exams will appear here once archived.', ru: 'Завершённые экзамены появятся здесь после архивации.', uz: 'Tugatilgan imtihonlar arxivlangandan keyin shu yerda chiqadi.');
  String get noExamsForClasses => t(en: 'No exams found for your classes.', ru: 'Для ваших классов экзаменов нет.', uz: 'Sizning sinflaringiz uchun imtihonlar yo\'q.');
  String get startByCreatingExam => t(en: 'Start by creating your first exam', ru: 'Создайте первый экзамен', uz: 'Birinchi imtihonni yarating');
  String get examName => t(en: 'Exam name', ru: 'Название экзамена', uz: 'Imtihon nomi');
  String get totalMarks => t(en: 'Total marks', ru: 'Макс. баллов', uz: 'Jami ball');
  String get passingMarks => t(en: 'Passing marks', ru: 'Проходной балл', uz: 'O\'tish bali');
  String get createGroupFirst => t(en: 'Create a group first under Groups', ru: 'Сначала создайте группу в разделе Группы', uz: 'Avval Guruhlar bo\'limida guruh yarating');
  String get addStudentsBeforeExam => t(en: 'Add students to the group before creating the exam', ru: 'Добавьте учеников в группу перед созданием экзамена', uz: 'Imtihon yaratishdan oldin guruhga o\'quvchi qo\'shing');
  String get results => t(en: 'Results', ru: 'Результаты', uz: 'Natijalar');
  String get date => t(en: 'Date', ru: 'Дата', uz: 'Sana');
  String get marks => t(en: 'Marks', ru: 'Баллы', uz: 'Ballar');
  String marksToPass(int passing, int total) => t(
        en: '$passing/$total to pass',
        ru: '$passing/$total для сдачи',
        uz: 'O\'tish uchun $passing/$total',
      );
  String get noStudentsEnrolled => t(en: 'No students enrolled yet.', ru: 'Пока нет записанных учеников.', uz: 'Hali o\'quvchilar yo\'q.');
  String marksFor(String name) => t(en: 'Marks — $name', ru: 'Оценки — $name', uz: 'Ballar — $name');
  String get midTermExam => t(en: 'Mid-Term Exam', ru: 'Промежуточный экзамен', uz: 'Oraliq imtihon');
  String get groupHasNoStudents => t(
        en: 'This group has no students yet. Add students to the group first.',
        ru: 'В этой группе пока нет учеников. Сначала добавьте учеников.',
        uz: 'Bu guruhda hali o\'quvchilar yo\'q. Avval o\'quvchi qo\'shing.',
      );
  String get groupStudentsWillEnroll => t(
        en: 'Students in this group will be enrolled so you can enter marks right away.',
        ru: 'Ученики группы будут записаны, чтобы сразу выставить оценки.',
        uz: 'Guruh o\'quvchilari yoziladi — ballarni darhol kiritasiz.',
      );
  String groupWithStudents(String name, int count) => t(
        en: '$name ($count students)',
        ru: '$name ($count учеников)',
        uz: '$name ($count o\'quvchi)',
      );
}
