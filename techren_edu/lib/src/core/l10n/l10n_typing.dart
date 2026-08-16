part of 'app_localizations.dart';

extension L10nTyping on AppLocalizations {
  String get typingSpeedChallenge => t(en: 'Typing Speed Challenge', ru: 'Челлендж скорости печати', uz: 'Yozish tezligi musobaqasi');
  String get couldNotLoadTyping => t(en: 'Could not load typing dashboard', ru: 'Не удалось загрузить панель печати', uz: 'Yozish panelini yuklab bo\'lmadi');
  String get practice => t(en: 'Practice', ru: 'Практика', uz: 'Mashq');
  String get tryPractice => t(en: 'Try practice', ru: 'Попробовать', uz: 'Mashq qilish');
  String get continuePractice => t(en: 'Continue practice', ru: 'Продолжить практику', uz: 'Mashqni davom ettirish');
  String get dailyDone => t(en: 'Daily done', ru: 'Дневное выполнено', uz: 'Kunlik bajarildi');
  String get dailyChallenge => t(en: 'Daily challenge', ru: 'Дневной челлендж', uz: 'Kunlik vazifa');
  String get leaderboard => t(en: 'Leaderboard', ru: 'Рейтинг', uz: 'Reyting');
  String get startTyping => t(en: 'Start typing', ru: 'Начать печать', uz: 'Yozishni boshlash');
  String get mode => t(en: 'Mode', ru: 'Режим', uz: 'Rejim');
  String get difficulty => t(en: 'Difficulty', ru: 'Сложность', uz: 'Qiyinlik');
  String get timer => t(en: 'Timer', ru: 'Таймер', uz: 'Taymer');
  String get englishWords => t(en: 'English words', ru: 'Английские слова', uz: 'Ingliz so\'zlari');
  String get uzbekWords => t(en: 'Uzbek words', ru: 'Узбекские слова', uz: 'O\'zbek so\'zlari');
  String get programmingWords => t(en: 'Programming words', ru: 'Слова программирования', uz: 'Dasturlash so\'zlari');
  String get codeTyping => t(en: 'Code typing', ru: 'Печать кода', uz: 'Kod yozish');
  String get easy => t(en: 'easy', ru: 'лёгкий', uz: 'oson');
  String get medium => t(en: 'medium', ru: 'средний', uz: 'o\'rta');
  String get hard => t(en: 'hard', ru: 'сложный', uz: 'qiyin');
  String get expert => t(en: 'expert', ru: 'эксперт', uz: 'ekspert');
  String get minAccuracy => t(en: 'Min accuracy', ru: 'Мин. точность', uz: 'Min aniqlik');
  String get period => t(en: 'Period', ru: 'Период', uz: 'Davr');
  String get allTime => t(en: 'All time', ru: 'За всё время', uz: 'Barcha vaqt');
  String get weekly => t(en: 'Weekly', ru: 'За неделю', uz: 'Haftalik');
  String get noScoresYet => t(en: 'No scores yet', ru: 'Пока нет результатов', uz: 'Hali natijalar yo\'q');
  String get xpBreakdown => t(en: 'XP breakdown', ru: 'Разбор XP', uz: 'XP tahlili');
  String get couldNotStart => t(en: 'Could not start', ru: 'Не удалось начать', uz: 'Boshlab bo\'lmadi');
  String typingLevelLine({required int level, required int tests, required String wpm}) => t(
        en: 'Level $level · $tests tests · $wpm WPM',
        ru: 'Уровень $level · $tests тестов · $wpm WPM',
        uz: 'Daraja $level · $tests test · $wpm WPM',
      );

  String typingDifficulty(String value) {
    switch (value) {
      case 'easy':
        return easy;
      case 'medium':
        return medium;
      case 'hard':
        return hard;
      case 'expert':
        return expert;
      default:
        return value;
    }
  }
}
