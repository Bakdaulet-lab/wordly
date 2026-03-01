import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Simple localization system supporting English and Russian UI.
class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const List<Locale> supportedLocales = [
    Locale('en'),
    Locale('ru'),
  ];

  // ── Translated strings ───────────────────────────────────────────

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      // Navigation
      'dashboard': 'Dashboard',
      'words': 'Words',
      'quiz': 'Quiz',
      'leaderboard': 'Leaderboard',
      'profile': 'Profile',

      // General
      'appName': 'Wordly',
      'settings': 'Settings',
      'cancel': 'Cancel',
      'save': 'Save',
      'retry': 'Retry',
      'goHome': 'Go Home',
      'close': 'Close',
      'remove': 'Remove',
      'confirm': 'Confirm',
      'resetProgress': 'Reset Progress',
      'resetProgressConfirm': 'This will erase all your learning progress, XP, and streaks. This action cannot be undone.',
      'resetProgressSuccess': 'Progress has been reset.',
      'resetProgressFailed': 'Failed to reset progress.',
      'loadingMore': 'Loading more...',

      // Auth
      'login': 'Log In',
      'signup': 'Sign Up',
      'createAccount': 'Create Account',
      'email': 'Email',
      'password': 'Password',
      'displayName': 'Display Name',
      'forgotPassword': 'Forgot Password?',
      'noAccount': "Don't have an account? Sign Up",
      'hasAccount': 'Already have an account? Log In',
      'learnTagline': 'Learn English words the smart way',
      'startJourney': 'Start your vocabulary journey',
      'resetPassword': 'Reset Password',
      'resetPasswordDesc':
          "Enter your email and we'll send you a link to reset your password.",
      'sendLink': 'Send Link',
      'resetSent': 'Password reset link sent! Check your email.',
      'resetFailed': 'Failed to send reset link.',

      // Settings
      'appearance': 'Appearance',
      'notifications': 'Notifications',
      'dataSync': 'Data & Sync',
      'themeMode': 'Theme Mode',
      'system': 'System',
      'light': 'Light',
      'dark': 'Dark',
      'followDevice': 'Follow device theme',
      'alwaysLight': 'Always use light theme',
      'alwaysDark': 'Always use dark theme',
      'dailyReminder': 'Daily Study Reminder',
      'reminderAt': 'Reminder at',
      'reminderDesc': 'Get notified to practice every day',
      'reminderTime': 'Reminder Time',
      'online': 'Online',
      'offline': 'Offline',
      'syncNow': 'Sync Now',
      'allSynced': 'All data synced',
      'syncing': 'Syncing...',
      'syncError': 'Sync error',
      'offlineChanges': 'Offline — changes saved locally',
      'lastSynced': 'Last synced:',
      'speechRate': 'Speech Rate',
      'speechRateDesc': 'Adjust word pronunciation speed',
      'slow': 'Slow',
      'fast': 'Fast',
      'language': 'Language',
      'languageDesc': 'Choose UI language',
      'english': 'English',
      'russian': 'Русский',

      // Dashboard
      'todayProgress': "Today's Progress",
      'reviewed': 'Reviewed',
      'accuracy': 'Accuracy',
      'xpEarned': 'XP Earned',
      'dailyGoal': 'Daily Goal',
      'setDailyGoal': 'Set Daily XP Goal',
      'goalReached': 'Goal reached! Great work today.',
      'wordOfTheDay': 'Word of the Day',
      'weeklyXp': 'Weekly XP',
      'analyticsCharts': 'Analytics & Charts',
      'viewCharts': 'View detailed progress charts and trends',
      'wordsDueReview': 'Words Due for Review',
      'wordsDueCount': 'word(s) ready to review',
      'noDue': 'No words due right now. Great job!',

      // Quiz
      'vocabularyQuiz': 'Vocabulary Quiz',
      'quizDesc':
          'Test your knowledge with a quick quiz session.\nAnswer questions about word translations and earn XP!',
      'startQuiz': 'Start Quiz',
      'quizByDifficulty': 'Quiz by Difficulty',
      'chooseDifficulty': 'Choose Difficulty',
      'questionOf': 'Question {current} of {total}',
      'whatTranslation': 'What is the translation of:',
      'noWordsQuiz':
          'No words available for the quiz.\nPlease check the word library first.',
      'listen': 'Listen',

      // Quiz result
      'perfectScore': 'Perfect Score!',
      'greatJob': 'Great Job!',
      'keepPracticing': 'Keep Practicing!',
      'correctAnswers': 'Correct Answers',
      'wordsToReview': 'Words to Review',
      'practiceMistakes': 'Practice Mistakes',
      'playAgain': 'Play Again',
      'shareResults': 'Share Results',
      'shareText':
          'I scored {score}/{total} on Wordly and earned {xp} XP! {perfect}',

      // Words
      'wordLibrary': 'Word Library',
      'searchWords': 'Search words...',
      'noWordsFound': 'No words found',
      'sortWords': 'Sort words',
      'default_': 'Default',
      'aToZ': 'A → Z',
      'zToA': 'Z → A',
      'easiestFirst': 'Easiest first',
      'hardestFirst': 'Hardest first',
      'showAll': 'Show all words',
      'showFavorites': 'Show favorites only',
      'all': 'All',
      'wordDetails': 'Word Details',
      'example': 'Example',
      'difficulty': 'Difficulty',
      'category': 'Category',
      'wordNotFound': 'Word not found',

      // Review
      'review': 'Review',
      'allCaughtUp': 'All Caught Up!',
      'noDueReview':
          'No words are due for review right now.\nCome back later or try a quiz!',
      'reviewComplete': 'Review Complete!',
      'reviewedWords': 'You reviewed {count} word(s) successfully.',
      'doYouKnow': 'Do you know this word?',
      'didntKnow': "Didn't Know",
      'iKnewIt': 'I Knew It',

      // Achievements
      'achievements': 'Achievements',
      'noAchievements': 'No achievements available yet',
      'unlocked': 'unlocked',
      'achievementUnlocked': 'Achievement Unlocked!',

      // Profile
      'level': 'Level',
      'totalXp': 'Total XP',
      'currentStreak': 'Current Streak',
      'longestStreak': 'Longest Streak',
      'memberSince': 'Member since',
      'editName': 'Edit name',
      'editDisplayName': 'Edit Display Name',
      'nameUpdated': 'Name updated!',
      'nameUpdateFailed': 'Failed to update name.',
      'logOut': 'Log Out',
      'logOutConfirm': 'Are you sure you want to log out?',
      'day': 'day',
      'days': 'days',

      // Leaderboard
      'global': 'Global',
      'weekly': 'Weekly',
      'friends': 'Friends',
      'addFriend': 'Add Friend',
      'yourRank': 'Your Rank:',
      'noEntries': 'No entries yet',
      'startLearning': 'Start learning to appear on the leaderboard!',
      'friendRequests': 'Friend Requests',
      'friendsLeaderboard': 'Friends Leaderboard',
      'addFriendsPrompt': 'Add friends to compare progress!',
      'myFriends': 'My Friends',
      'noFriends': 'No friends yet',
      'removeFriend': 'Remove Friend',
      'removeFriendConfirm': 'Remove {name} from your friends?',
      'wantsFriends': 'Wants to be friends',
      'searchByName': 'Search by name...',
      'typeToSearch': 'Type a name to search',
      'noUsersFound': 'No users found',

      // Analytics
      'analytics': 'Analytics',
      'totalXpLabel': 'Total XP',
      'avgAccuracy': 'Avg Accuracy',
      'wordsReviewed': 'Words Reviewed',
      'activeDays': 'Active Days',
      'xpEarnedChart': 'XP Earned',
      'accuracyTrend': 'Accuracy Trend',
      'correctRatePerDay': 'Correct answer rate per day',
      'wordActivity': 'Word Activity',
      'reviewsNewPerDay': 'Reviews and new words per day',
      'answerBreakdown': 'Answer Breakdown',
      'noAnswers': 'No answers recorded yet',
      'completeQuizzes': 'Complete some quizzes to see your breakdown',
      'correct': 'Correct',
      'incorrect': 'Incorrect',
      'periodHighlights': 'Period Highlights',
      'avgDailyXp': 'Avg Daily XP',
      'bestDay': 'Best Day',
      'studyTime': 'Study Time',
      'wordsLearned': 'Words Learned',

      // Onboarding
      'skip': 'Skip',
      'next': 'Next',
      'getStarted': 'Get Started',
      'onboard1Title': 'Learn New Words',
      'onboard1Desc':
          'Browse a rich library of English words with Russian translations, example sentences, and difficulty levels.',
      'onboard2Title': 'Test Your Knowledge',
      'onboard2Desc':
          'Take quizzes to practice vocabulary. Choose difficulty levels or quiz on all words. Earn XP for every answer!',
      'onboard3Title': 'Spaced Repetition',
      'onboard3Desc':
          'Our smart review system brings back words at the perfect time so you remember them long-term.',
      'onboard4Title': 'Level Up & Earn Badges',
      'onboard4Desc':
          'Gain XP, level up, maintain streaks, and unlock achievements. Set daily goals and track your progress!',

      // Connectivity
      'syncErrorRetry': 'Sync error — tap to retry',
      'offlineSaved': 'Offline — changes saved locally',
      'failedConnect': 'Failed to connect to server',
      'checkInternet':
          'Please check your internet connection and restart the app.',

      // Share
      'sharingUnavailable': 'Sharing is not available on this device.',

      // Difficulty labels
      'beginner': 'Beginner',
      'easy': 'Easy',
      'medium': 'Medium',
      'hard': 'Hard',
      'expert': 'Expert',

      // Period labels
      'week': 'Week',
      'month': 'Month',
      'quarter': 'Quarter',
      'year': 'Year',
    },
    'ru': {
      // Navigation
      'dashboard': 'Главная',
      'words': 'Слова',
      'quiz': 'Квиз',
      'leaderboard': 'Рейтинг',
      'profile': 'Профиль',

      // General
      'appName': 'Wordly',
      'settings': 'Настройки',
      'cancel': 'Отмена',
      'save': 'Сохранить',
      'retry': 'Повторить',
      'goHome': 'На главную',
      'close': 'Закрыть',
      'remove': 'Удалить',
      'confirm': 'Подтвердить',
      'resetProgress': 'Сбросить прогресс',
      'resetProgressConfirm': 'Это удалит весь ваш прогресс обучения, XP и серии. Это действие нельзя отменить.',
      'resetProgressSuccess': 'Прогресс сброшен.',
      'resetProgressFailed': 'Не удалось сбросить прогресс.',
      'loadingMore': 'Загрузка...',

      // Auth
      'login': 'Войти',
      'signup': 'Регистрация',
      'createAccount': 'Создать аккаунт',
      'email': 'Эл. почта',
      'password': 'Пароль',
      'displayName': 'Имя',
      'forgotPassword': 'Забыли пароль?',
      'noAccount': 'Нет аккаунта? Зарегистрируйтесь',
      'hasAccount': 'Уже есть аккаунт? Войти',
      'learnTagline': 'Учи английские слова умным способом',
      'startJourney': 'Начни путь к новым знаниям',
      'resetPassword': 'Сброс пароля',
      'resetPasswordDesc':
          'Введите email и мы отправим ссылку для сброса пароля.',
      'sendLink': 'Отправить',
      'resetSent': 'Ссылка для сброса отправлена! Проверьте почту.',
      'resetFailed': 'Не удалось отправить ссылку.',

      // Settings
      'appearance': 'Оформление',
      'notifications': 'Уведомления',
      'dataSync': 'Данные и синхронизация',
      'themeMode': 'Тема оформления',
      'system': 'Системная',
      'light': 'Светлая',
      'dark': 'Тёмная',
      'followDevice': 'Следовать системной теме',
      'alwaysLight': 'Всегда светлая тема',
      'alwaysDark': 'Всегда тёмная тема',
      'dailyReminder': 'Ежедневное напоминание',
      'reminderAt': 'Напоминание в',
      'reminderDesc': 'Получайте уведомление для ежедневной практики',
      'reminderTime': 'Время напоминания',
      'online': 'Онлайн',
      'offline': 'Офлайн',
      'syncNow': 'Синхронизировать',
      'allSynced': 'Все данные синхронизированы',
      'syncing': 'Синхронизация...',
      'syncError': 'Ошибка синхронизации',
      'offlineChanges': 'Офлайн — изменения сохранены локально',
      'lastSynced': 'Последняя синхронизация:',
      'speechRate': 'Скорость речи',
      'speechRateDesc': 'Настройте скорость произношения слов',
      'slow': 'Медленно',
      'fast': 'Быстро',
      'language': 'Язык',
      'languageDesc': 'Выберите язык интерфейса',
      'english': 'English',
      'russian': 'Русский',

      // Dashboard
      'todayProgress': 'Прогресс за сегодня',
      'reviewed': 'Повторено',
      'accuracy': 'Точность',
      'xpEarned': 'XP получено',
      'dailyGoal': 'Цель на день',
      'setDailyGoal': 'Установить цель XP',
      'goalReached': 'Цель достигнута! Отличная работа.',
      'wordOfTheDay': 'Слово дня',
      'weeklyXp': 'XP за неделю',
      'analyticsCharts': 'Аналитика и графики',
      'viewCharts': 'Подробные графики и тенденции прогресса',
      'wordsDueReview': 'Слова для повторения',
      'wordsDueCount': 'слов(а) готовы к повторению',
      'noDue': 'Нет слов для повторения. Отлично!',

      // Quiz
      'vocabularyQuiz': 'Квиз по словарю',
      'quizDesc':
          'Проверьте свои знания в быстром квизе.\nОтвечайте на вопросы о переводах и зарабатывайте XP!',
      'startQuiz': 'Начать квиз',
      'quizByDifficulty': 'Квиз по сложности',
      'chooseDifficulty': 'Выберите сложность',
      'questionOf': 'Вопрос {current} из {total}',
      'whatTranslation': 'Как переводится:',
      'noWordsQuiz':
          'Нет слов для квиза.\nСначала загрузите библиотеку слов.',
      'listen': 'Прослушать',

      // Quiz result
      'perfectScore': 'Идеальный результат!',
      'greatJob': 'Отлично!',
      'keepPracticing': 'Продолжайте практику!',
      'correctAnswers': 'Правильных ответов',
      'wordsToReview': 'Слова для повторения',
      'practiceMistakes': 'Повторить ошибки',
      'playAgain': 'Играть снова',
      'shareResults': 'Поделиться',
      'shareText':
          'Мой результат в Wordly: {score}/{total}, заработано {xp} XP! {perfect}',

      // Words
      'wordLibrary': 'Библиотека слов',
      'searchWords': 'Поиск слов...',
      'noWordsFound': 'Слова не найдены',
      'sortWords': 'Сортировка',
      'default_': 'По умолчанию',
      'aToZ': 'А → Я',
      'zToA': 'Я → А',
      'easiestFirst': 'Сначала лёгкие',
      'hardestFirst': 'Сначала сложные',
      'showAll': 'Показать все слова',
      'showFavorites': 'Только избранные',
      'all': 'Все',
      'wordDetails': 'Подробности',
      'example': 'Пример',
      'difficulty': 'Сложность',
      'category': 'Категория',
      'wordNotFound': 'Слово не найдено',

      // Review
      'review': 'Повторение',
      'allCaughtUp': 'Всё повторено!',
      'noDueReview':
          'Сейчас нет слов для повторения.\nВозвращайтесь позже или попробуйте квиз!',
      'reviewComplete': 'Повторение завершено!',
      'reviewedWords': 'Вы повторили {count} слов(а) успешно.',
      'doYouKnow': 'Вы знаете это слово?',
      'didntKnow': 'Не знал(а)',
      'iKnewIt': 'Знал(а)',

      // Achievements
      'achievements': 'Достижения',
      'noAchievements': 'Достижений пока нет',
      'unlocked': 'получено',
      'achievementUnlocked': 'Достижение разблокировано!',

      // Profile
      'level': 'Уровень',
      'totalXp': 'Всего XP',
      'currentStreak': 'Текущая серия',
      'longestStreak': 'Лучшая серия',
      'memberSince': 'Участник с',
      'editName': 'Изменить имя',
      'editDisplayName': 'Изменить имя',
      'nameUpdated': 'Имя обновлено!',
      'nameUpdateFailed': 'Не удалось обновить имя.',
      'logOut': 'Выйти',
      'logOutConfirm': 'Вы уверены, что хотите выйти?',
      'day': 'день',
      'days': 'дней',

      // Leaderboard
      'global': 'Глобальный',
      'weekly': 'За неделю',
      'friends': 'Друзья',
      'addFriend': 'Добавить друга',
      'yourRank': 'Ваш ранг:',
      'noEntries': 'Пока нет записей',
      'startLearning': 'Начните учиться, чтобы попасть в рейтинг!',
      'friendRequests': 'Запросы в друзья',
      'friendsLeaderboard': 'Рейтинг друзей',
      'addFriendsPrompt': 'Добавьте друзей для сравнения!',
      'myFriends': 'Мои друзья',
      'noFriends': 'Друзей пока нет',
      'removeFriend': 'Удалить друга',
      'removeFriendConfirm': 'Удалить {name} из друзей?',
      'wantsFriends': 'Хочет дружить',
      'searchByName': 'Поиск по имени...',
      'typeToSearch': 'Введите имя для поиска',
      'noUsersFound': 'Пользователи не найдены',

      // Analytics
      'analytics': 'Аналитика',
      'totalXpLabel': 'Всего XP',
      'avgAccuracy': 'Ср. точность',
      'wordsReviewed': 'Слов повторено',
      'activeDays': 'Активных дней',
      'xpEarnedChart': 'Полученный XP',
      'accuracyTrend': 'Тренд точности',
      'correctRatePerDay': 'Процент правильных ответов по дням',
      'wordActivity': 'Активность по словам',
      'reviewsNewPerDay': 'Повторения и новые слова по дням',
      'answerBreakdown': 'Статистика ответов',
      'noAnswers': 'Ответов пока нет',
      'completeQuizzes': 'Пройдите квизы, чтобы увидеть статистику',
      'correct': 'Правильно',
      'incorrect': 'Неправильно',
      'periodHighlights': 'Итоги периода',
      'avgDailyXp': 'Ср. XP/день',
      'bestDay': 'Лучший день',
      'studyTime': 'Время учёбы',
      'wordsLearned': 'Слов выучено',

      // Onboarding
      'skip': 'Пропустить',
      'next': 'Далее',
      'getStarted': 'Начать',
      'onboard1Title': 'Учи новые слова',
      'onboard1Desc':
          'Изучайте библиотеку английских слов с русскими переводами, примерами предложений и уровнями сложности.',
      'onboard2Title': 'Проверяй знания',
      'onboard2Desc':
          'Проходите квизы для практики словарного запаса. Выбирайте уровни сложности и зарабатывайте XP!',
      'onboard3Title': 'Интервальное повторение',
      'onboard3Desc':
          'Умная система повторения возвращает слова в нужный момент для долговременного запоминания.',
      'onboard4Title': 'Повышай уровень',
      'onboard4Desc':
          'Получайте XP, повышайте уровень, поддерживайте серии и открывайте достижения!',

      // Connectivity
      'syncErrorRetry': 'Ошибка синхронизации — нажмите для повтора',
      'offlineSaved': 'Офлайн — изменения сохранены локально',
      'failedConnect': 'Не удалось подключиться к серверу',
      'checkInternet':
          'Проверьте подключение к интернету и перезапустите приложение.',

      // Share
      'sharingUnavailable': 'Функция «Поделиться» недоступна на этом устройстве.',

      // Difficulty labels
      'beginner': 'Начальный',
      'easy': 'Лёгкий',
      'medium': 'Средний',
      'hard': 'Сложный',
      'expert': 'Экспертный',

      // Period labels
      'week': 'Неделя',
      'month': 'Месяц',
      'quarter': 'Квартал',
      'year': 'Год',
    },
  };

  String translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ??
        _localizedValues['en']?[key] ??
        key;
  }

  // Convenience getters
  String get dashboard => translate('dashboard');
  String get words => translate('words');
  String get quiz => translate('quiz');
  String get leaderboard => translate('leaderboard');
  String get profile => translate('profile');
  String get settings => translate('settings');
  String get cancel => translate('cancel');
  String get save => translate('save');
  String get retry => translate('retry');
  String get goHome => translate('goHome');
  String get close => translate('close');
  String get login => translate('login');
  String get signup => translate('signup');
  String get startQuiz => translate('startQuiz');
  String get playAgain => translate('playAgain');
  String get shareResults => translate('shareResults');
  String get achievements => translate('achievements');
  String get analytics => translate('analytics');
  String get review => translate('review');
  String get wordLibrary => translate('wordLibrary');
  String get searchWords => translate('searchWords');
  String get speechRate => translate('speechRate');
  String get language => translate('language');
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      ['en', 'ru'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(AppLocalizations(locale));
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
