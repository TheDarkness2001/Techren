part of 'app_localizations.dart';

extension L10nGroups on AppLocalizations {
  String get createGroup => t(en: 'Create group', ru: 'Создать группу', uz: 'Guruh yaratish');
  String get editGroup => t(en: 'Edit group', ru: 'Изменить группу', uz: 'Guruhni tahrirlash');
  String get searchGroupsHint => t(en: 'Search groups by name or subject', ru: 'Поиск групп по имени или предмету', uz: 'Guruhni ism yoki fan bo\'yicha qidirish');
  String get noGroups => t(en: 'No groups', ru: 'Нет групп', uz: 'Guruhlar yo\'q');
  String get noGroupsMessage => t(en: 'Create a group with the + button.', ru: 'Создайте группу кнопкой +.', uz: '+ tugmasi bilan guruh yarating.');
  String get subjectName => t(en: 'Subject name', ru: 'Название предмета', uz: 'Fan nomi');
  String get coursePriceMonthlyRequired => t(en: 'Course price (monthly) *', ru: 'Цена курса (в месяц) *', uz: 'Kurs narxi (oylik) *');
  String get coursePriceHint => t(en: 'Used for dues & expected revenue', ru: 'Для взносов и ожидаемой выручки', uz: 'To\'lovlar va kutilgan daromad uchun');
  String get groupName => t(en: 'Group name', ru: 'Название группы', uz: 'Guruh nomi');
  String get startTime => t(en: 'Start (HH:mm)', ru: 'Начало (ЧЧ:мм)', uz: 'Boshlanish (SS:dd)');
  String get endTime => t(en: 'End (HH:mm)', ru: 'Конец (ЧЧ:мм)', uz: 'Tugash (SS:dd)');
  String get noAvailableStudents => t(
        en: 'No available students. Only active students who are not already in a group can be added.',
        ru: 'Нет доступных учеников. Можно добавить только активных учеников без группы.',
        uz: 'Mavjud o\'quvchilar yo\'q. Faqat guruhda bo\'lmagan faol o\'quvchilar qo\'shiladi.',
      );
  String get createTeacherFirst => t(en: 'Create a teacher first in People.', ru: 'Сначала создайте учителя в разделе Люди.', uz: 'Avval Odamlar bo\'limida o\'qituvchi yarating.');
  String get noTeachersAvailable => t(en: 'No teachers available.', ru: 'Нет доступных учителей.', uz: 'O\'qituvchilar yo\'q.');
  String get enterPriceGreaterThanZero => t(en: 'Enter a course price greater than 0', ru: 'Укажите цену курса больше 0', uz: 'Kurs narxi 0 dan katta bo\'lishi kerak');
  String couldNotLoadPeople(String error) => t(en: 'Could not load people: $error', ru: 'Не удалось загрузить людей: $error', uz: 'Odamlarni yuklab bo\'lmadi: $error');
  String couldNotCreateGroup(String error) => t(en: 'Could not create group: $error', ru: 'Не удалось создать группу: $error', uz: 'Guruh yaratilmadi: $error');
  String couldNotUpdateGroup(String error) => t(en: 'Could not update group: $error', ru: 'Не удалось обновить группу: $error', uz: 'Guruh yangilanmadi: $error');
}
