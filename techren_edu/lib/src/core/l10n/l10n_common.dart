part of 'app_localizations.dart';

extension L10nCommon on AppLocalizations {
  String get save => t(en: 'Save', ru: 'Сохранить', uz: 'Saqlash');
  String get cancel => t(en: 'Cancel', ru: 'Отмена', uz: 'Bekor qilish');
  String get delete => t(en: 'Delete', ru: 'Удалить', uz: 'O\'chirish');
  String get edit => t(en: 'Edit', ru: 'Изменить', uz: 'Tahrirlash');
  String get add => t(en: 'Add', ru: 'Добавить', uz: 'Qo\'shish');
  String get create => t(en: 'Create', ru: 'Создать', uz: 'Yaratish');
  String get refresh => t(en: 'Refresh', ru: 'Обновить', uz: 'Yangilash');
  String get retry => t(en: 'Retry', ru: 'Повторить', uz: 'Qayta urinish');
  String get tryAgain => t(en: 'Try again', ru: 'Попробовать снова', uz: 'Qayta urinib ko\'ring');
  String get incorrectTryAgain =>
      t(en: 'Incorrect. Try again.', ru: 'Неверно. Попробуйте ещё раз.', uz: 'Noto\'g\'ri. Qayta urinib ko\'ring.');
  String chancesLeft(int n) => t(
        en: n == 1 ? '1 chance left' : '$n chances left',
        ru: n == 1 ? 'Осталась 1 попытка' : 'Осталось $n попыток',
        uz: n == 1 ? '1 imkoniyat qoldi' : '$n ta imkoniyat qoldi',
      );
  String get search => t(en: 'Search', ru: 'Поиск', uz: 'Qidirish');
  String get filter => t(en: 'Filter', ru: 'Фильтр', uz: 'Filtr');
  String get close => t(en: 'Close', ru: 'Закрыть', uz: 'Yopish');
  String get notes => t(en: 'Notes', ru: 'Заметки', uz: 'Izohlar');
  String get confirm => t(en: 'Confirm', ru: 'Подтвердить', uz: 'Tasdiqlash');
  String get back => t(en: 'Back', ru: 'Назад', uz: 'Orqaga');
  String get view => t(en: 'View', ru: 'Просмотр', uz: 'Ko\'rish');
  String get pay => t(en: 'Pay', ru: 'Оплатить', uz: 'To\'lash');
  String get record => t(en: 'Record', ru: 'Записать', uz: 'Yozish');
  String get reset => t(en: 'Reset', ru: 'Сбросить', uz: 'Tozalash');
  String get continueLabel => t(en: 'Continue', ru: 'Продолжить', uz: 'Davom etish');
  String get post => t(en: 'Post', ru: 'Опубликовать', uz: 'Joylashtirish');
  String get send => t(en: 'Send', ru: 'Отправить', uz: 'Yuborish');
  String get importLabel => t(en: 'Import', ru: 'Импорт', uz: 'Import');
  String get ok => t(en: 'OK', ru: 'ОК', uz: 'OK');
  String get name => t(en: 'Name', ru: 'Имя', uz: 'Ism');
  String get nameRequired => t(en: 'Name *', ru: 'Имя *', uz: 'Ism *');
  String get emailRequiredStar => t(en: 'Email *', ru: 'Email *', uz: 'Email *');
  String get passwordRequiredStar => t(en: 'Password *', ru: 'Пароль *', uz: 'Parol *');
  String get phone => t(en: 'Phone', ru: 'Телефон', uz: 'Telefon');
  String get branch => t(en: 'Branch', ru: 'Филиал', uz: 'Filial');
  String get branchRequired => t(en: 'Branch *', ru: 'Филиал *', uz: 'Filial *');
  String get role => t(en: 'Role', ru: 'Роль', uz: 'Rol');
  String get subject => t(en: 'Subject', ru: 'Предмет', uz: 'Fan');
  String get amount => t(en: 'Amount', ru: 'Сумма', uz: 'Summa');
  String get month => t(en: 'Month', ru: 'Месяц', uz: 'Oy');
  String get year => t(en: 'Year', ru: 'Год', uz: 'Yil');
  String get teacher => t(en: 'Teacher', ru: 'Учитель', uz: 'O\'qituvchi');
  String get group => t(en: 'Group', ru: 'Группа', uz: 'Guruh');
  String get status => t(en: 'Status', ru: 'Статус', uz: 'Holat');
  String get searchAndFilter => t(en: 'Search & Filter', ru: 'Поиск и фильтр', uz: 'Qidiruv va filtr');
  String get allStatus => t(en: 'All Status', ru: 'Все статусы', uz: 'Barcha holatlar');
  String get statusActiveLabel => t(en: 'Active', ru: 'Активен', uz: 'Faol');
  String get statusInactiveLabel => t(en: 'Inactive', ru: 'Неактивен', uz: 'Nofaol');
  String get statusGraduated => t(en: 'Graduated', ru: 'Выпускник', uz: 'Bitirgan');
  String get statusOnLeave => t(en: 'On leave', ru: 'В отпуске', uz: 'Ta\'tilda');
  String get total => t(en: 'Total', ru: 'Всего', uz: 'Jami');
  String get somethingWentWrong => t(en: 'Something went wrong', ru: 'Что-то пошло не так', uz: 'Xatolik yuz berdi');
  String get genderMale => t(en: 'Male', ru: 'Мужской', uz: 'Erkak');
  String get genderFemale => t(en: 'Female', ru: 'Женский', uz: 'Ayol');
  String get genderOther => t(en: 'Other', ru: 'Другое', uz: 'Boshqa');
  String get relationMother => t(en: 'Mother', ru: 'Мать', uz: 'Ona');
  String get relationFather => t(en: 'Father', ru: 'Отец', uz: 'Ota');
  String get relationGuardian => t(en: 'Guardian', ru: 'Опекун', uz: 'Vasiy');
  String get methodCash => t(en: 'Cash', ru: 'Наличные', uz: 'Naqd');
  String get methodCard => t(en: 'Card', ru: 'Карта', uz: 'Karta');
  String get methodBankTransfer => t(en: 'Bank transfer', ru: 'Банковский перевод', uz: 'Bank o\'tkazmasi');
  String get methodOther => t(en: 'Other', ru: 'Другое', uz: 'Boshqa');
  String get itemsStudents => t(en: 'students', ru: 'учеников', uz: 'o\'quvchi');
  String get itemsStaff => t(en: 'staff', ru: 'сотрудников', uz: 'xodim');
  String get itemsExams => t(en: 'exams', ru: 'экзаменов', uz: 'imtihon');
  String get itemsGroups => t(en: 'groups', ru: 'групп', uz: 'guruh');
  String get backToSubject => t(en: 'Back to subject', ru: 'К предмету', uz: 'Fanga qaytish');
  String get seeAll => t(en: 'See all', ru: 'Все', uz: 'Hammasi');
  String get unlimited => t(en: 'Unlimited', ru: 'Без лимита', uz: 'Cheksiz');

  String paginationAll(int total, String itemLabel) => t(
        en: 'All $total $itemLabel loaded',
        ru: 'Все $total $itemLabel загружены',
        uz: 'Barcha $total $itemLabel yuklandi',
      );

  String paginationShowing(int loaded, int total, String itemLabel) => t(
        en: 'Showing $loaded of $total $itemLabel',
        ru: 'Показано $loaded из $total $itemLabel',
        uz: '$total dan $loaded $itemLabel ko\'rsatilmoqda',
      );

  String get paginationLoadingMore => t(en: 'Loading more.', ru: 'Загрузка…', uz: 'Yana yuklanmoqda.');

  String monthShort(int month) {
    const en = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    const ru = ['янв', 'фев', 'мар', 'апр', 'май', 'июн', 'июл', 'авг', 'сен', 'окт', 'ноя', 'дек'];
    const uz = ['Yan', 'Fev', 'Mar', 'Apr', 'May', 'Iyun', 'Iyul', 'Avg', 'Sen', 'Okt', 'Noy', 'Dek'];
    final i = (month - 1).clamp(0, 11);
    switch (locale.languageCode) {
      case 'ru':
        return ru[i];
      case 'uz':
        return uz[i];
      default:
        return en[i];
    }
  }

  String get sendTestNotification =>
      t(en: 'Send test notification', ru: 'Отправить тестовое уведомление', uz: 'Sinov bildirishnomasini yuborish');
  String get testPushSent =>
      t(en: 'Test notification sent. Check the bell or the notification tray.', ru: 'Тестовое уведомление отправлено. Проверьте колокольчик или шторку уведомлений.', uz: 'Sinov bildirishnomasi yuborildi. Qo‘ng‘iroqcha yoki bildirishnomalar panelini tekshiring.');
  String get testPushNoToken =>
      t(en: 'Test saved to your inbox. Open the app on a phone to try OS push.', ru: 'Тест сохранён во входящих. Для системного пуша откройте приложение на телефоне.', uz: 'Sinov kiruvchi qutiga saqlandi. Tizim pushini sinash uchun telefonda oching.');
  String get testPushFirebaseOff =>
      t(en: 'Test saved to your inbox.', ru: 'Тест сохранён во входящих.', uz: 'Sinov kiruvchi qutiga saqlandi.');
  String get testPushFailed =>
      t(en: 'Could not send test notification.', ru: 'Не удалось отправить тестовое уведомление.', uz: 'Sinov bildirishnomasini yuborib bo‘lmadi.');
}
