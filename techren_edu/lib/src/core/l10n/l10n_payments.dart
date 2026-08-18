part of 'app_localizations.dart';

extension L10nPayments on AppLocalizations {
  String get recordPayment => t(en: 'Record Payment', ru: 'Записать платёж', uz: 'To\'lovni yozish');
  String get acceptPayment => t(en: 'Accept payment', ru: 'Принять платёж', uz: 'To\'lovni qabul qilish');
  String get noStudentsFound => t(en: 'No students found', ru: 'Ученики не найдены', uz: 'O\'quvchilar topilmadi');
  String get student => t(en: 'Student', ru: 'Ученик', uz: 'O\'quvchi');
  String get course => t(en: 'Course', ru: 'Курс', uz: 'Kurs');
  String get courseOrSubject => t(en: 'Course / subject', ru: 'Курс / предмет', uz: 'Kurs / fan');
  String get amountReceived => t(en: 'Amount received', ru: 'Полученная сумма', uz: 'Qabul qilingan summa');
  String get method => t(en: 'Method', ru: 'Способ', uz: 'Usul');
  String get refreshData => t(en: 'Refresh Data', ru: 'Обновить данные', uz: 'Ma\'lumotni yangilash');
  String get searchStudent => t(en: 'Search Student', ru: 'Поиск ученика', uz: 'O\'quvchi qidirish');
  String get nameOrId => t(en: 'Name or ID', ru: 'Имя или ID', uz: 'Ism yoki ID');
  String get couldNotLoadPayments => t(en: 'Could not load payments', ru: 'Не удалось загрузить платежи', uz: 'To\'lovlarni yuklab bo\'lmadi');
  String remainingLeft(String amount) => t(en: '$amount left', ru: 'осталось $amount', uz: '$amount qoldi');
  String get branchCollections => t(en: 'Branch collections', ru: 'Сборы по филиалам', uz: 'Filial yig\'imlari');
  String get needToCollect => t(en: 'Need to collect', ru: 'Нужно собрать', uz: 'Yig\'ish kerak');
  String get collected => t(en: 'Collected', ru: 'Собрано', uz: 'Yig\'ilgan');
  String get stillDue => t(en: 'Still due', ru: 'Осталось', uz: 'Qolgan');
  String get allBranches => t(en: 'All branches', ru: 'Все филиалы', uz: 'Barcha filiallar');
  String get branchCosts => t(en: 'Branch costs', ru: 'Расходы филиала', uz: 'Filial xarajatlari');
  String get addCost => t(en: 'Add cost', ru: 'Добавить расход', uz: 'Xarajat qo\'shish');
  String get costType => t(en: 'Cost type', ru: 'Тип расхода', uz: 'Xarajat turi');
  String get teacherPayment => t(en: 'Teacher payment', ru: 'Оплата учителю', uz: 'O\'qituvchi to\'lovi');
  String get rent => t(en: 'Rent', ru: 'Аренда', uz: 'Ijara');
  String get electricity => t(en: 'Electricity', ru: 'Электричество', uz: 'Elektr');
  String get repair => t(en: 'Repair', ru: 'Ремонт', uz: 'Ta\'mir');
  String get otherCost => t(en: 'Other', ru: 'Другое', uz: 'Boshqa');
  String get leftover => t(en: 'Left after costs', ru: 'Остаток после расходов', uz: 'Xarajatlardan keyin');
  String get costsThisMonth => t(en: 'Costs this month', ru: 'Расходы за месяц', uz: 'Bu oy xarajatlari');
  String get addCostHint => t(
        en: 'Add rent, electricity, teacher pay, repairs, and other spending here.',
        ru: 'Добавляйте аренду, электричество, зарплату учителям, ремонт и другие расходы здесь.',
        uz: 'Ijara, elektr, o\'qituvchi to\'lovi, ta\'mir va boshqa xarajatlarni shu yerga qo\'shing.',
      );
  String get collectionSplit => t(en: 'Collected vs still due', ru: 'Собрано и остаток', uz: 'Yig\'ilgan va qolgan');
  String couldNotRecordPayment(String error) => t(en: 'Could not record payment: $error', ru: 'Не удалось записать платёж: $error', uz: 'To\'lov yozilmadi: $error');
  String paymentRecordedFor(String name) => t(en: 'Payment recorded for $name', ru: 'Платёж записан для $name', uz: '$name uchun to\'lov yozildi');
  String get recordPaid => t(en: 'Record paid', ru: 'Записать оплату', uz: 'To\'langan deb yozish');
  String get noStudentsMatchFilters => t(
        en: 'No active students match this month’s filters.',
        ru: 'Нет активных учеников по фильтрам этого месяца.',
        uz: 'Bu oy filtrlari bo\'yicha faol o\'quvchilar yo\'q.',
      );
}
