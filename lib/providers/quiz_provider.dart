import 'dart:async';

import 'package:flutter/material.dart';
import '../models/word_model.dart';
import '../models/quiz_option_model.dart';
import '../constants/app_constants.dart';
import '../services/quiz_service.dart';
import '../services/progress_service.dart';
import '../services/xp_service.dart';
import '../services/stats_service.dart';

class QuizProvider extends ChangeNotifier {
  final QuizService _quizService = QuizService();
  final ProgressService _progressService = ProgressService();
  final XpService _xpService = XpService();
  final StatsService _statsService = StatsService();

  List<WordModel> _quizWords = [];
  List<WordModel> _allWords = [];
  int _currentIndex = 0;
  int _score = 0;
  int _totalXpEarned = 0;
  List<QuizOptionModel> _currentOptions = [];
  int? _selectedOptionIndex;
  bool _isAnswered = false;
  bool _isLoading = false;
  List<WordModel> _mistakes = [];
  int _timeRemaining = AppConstants.quizTimerSeconds;
  Timer? _questionTimer;
  bool _timedOut = false;

  List<WordModel> get quizWords => _quizWords;
  int get currentIndex => _currentIndex;
  int get score => _score;
  int get totalXpEarned => _totalXpEarned;
  List<QuizOptionModel> get currentOptions => _currentOptions;
  int? get selectedOptionIndex => _selectedOptionIndex;
  bool get isAnswered => _isAnswered;
  bool get isLoading => _isLoading;
  List<WordModel> get mistakes => _mistakes;
  int get totalQuestions => _quizWords.length;
  bool get isQuizComplete => _currentIndex >= _quizWords.length;
  int get timeRemaining => _timeRemaining;
  bool get timedOut => _timedOut;

  WordModel? get currentWord =>
      _currentIndex < _quizWords.length ? _quizWords[_currentIndex] : null;

  void startQuiz(List<WordModel> allWords) {
    _allWords = allWords;
    _quizWords = _quizService.pickQuizWords(
      allWords,
      count: AppConstants.quizQuestionsPerSession,
    );
    _currentIndex = 0;
    _score = 0;
    _totalXpEarned = 0;
    _selectedOptionIndex = null;
    _isAnswered = false;
    _timedOut = false;
    _mistakes = [];
    _generateOptions();
    _startTimer();
    notifyListeners();
  }

  void _generateOptions() {
    if (currentWord != null) {
      _currentOptions = _quizService.generateOptions(
        correctWord: currentWord!,
        allWords: _allWords,
      );
    }
  }

  void _startTimer() {
    _questionTimer?.cancel();
    _timeRemaining = AppConstants.quizTimerSeconds;
    _timedOut = false;
    _questionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _timeRemaining--;
      if (_timeRemaining <= 0) {
        timer.cancel();
        if (!_isAnswered) {
          _timedOut = true;
          _isAnswered = true;
          _totalXpEarned += AppConstants.xpIncorrectAnswer;
          if (currentWord != null) {
            _mistakes.add(currentWord!);
          }
          notifyListeners();
        }
      } else {
        notifyListeners();
      }
    });
  }

  void _stopTimer() {
    _questionTimer?.cancel();
    _questionTimer = null;
  }

  Future<void> selectAnswer(int optionIndex, String userId) async {
    if (_isAnswered) return;

    _stopTimer();
    _selectedOptionIndex = optionIndex;
    _isAnswered = true;

    final option = _currentOptions[optionIndex];
    final isCorrect = option.isCorrect;
    final wordId = currentWord!.id;

    if (isCorrect) {
      _score++;
      _totalXpEarned += AppConstants.xpCorrectAnswer;
    } else {
      _totalXpEarned += AppConstants.xpIncorrectAnswer;
      _mistakes.add(currentWord!);
    }

    // Instant visual feedback — UI updates immediately
    notifyListeners();

    // Fire network calls in parallel in the background (non-blocking)
    final xp = isCorrect ? AppConstants.xpCorrectAnswer : AppConstants.xpIncorrectAnswer;
    final statField = isCorrect ? 'correct_answers' : 'incorrect_answers';
    final quality = isCorrect ? AppConstants.qualityCorrect : AppConstants.qualityWrong;

    unawaited(Future.wait([
      _xpService.awardXp(userId, xp),
      _statsService.incrementStat(userId, statField, 1),
      _progressService.updateProgress(
        userId: userId,
        wordId: wordId,
        quality: quality,
      ),
    ]).catchError((_) => <void>[]));
  }

  void nextQuestion() {
    _currentIndex++;
    _selectedOptionIndex = null;
    _isAnswered = false;
    _timedOut = false;

    if (!isQuizComplete) {
      _generateOptions();
      _startTimer();
    } else {
      _stopTimer();
    }
    notifyListeners();
  }

  Future<void> finishQuiz(String userId) async {
    final futures = <Future>[];

    // Bonus for perfect quiz
    if (_score == _quizWords.length && _quizWords.isNotEmpty) {
      final bonus = AppConstants.xpPerfectQuizBonus;
      _totalXpEarned += bonus;
      futures.add(_xpService.awardXp(userId, bonus));
    }

    futures.add(_statsService.incrementStat(userId, 'words_reviewed', _quizWords.length));
    futures.add(_statsService.incrementStat(userId, 'xp_earned', _totalXpEarned));

    await Future.wait(futures);
    notifyListeners();
  }

  void startQuizWithWords(List<WordModel> words, List<WordModel> allWords) {
    _allWords = allWords;
    _quizWords = List.from(words);
    _currentIndex = 0;
    _score = 0;
    _totalXpEarned = 0;
    _selectedOptionIndex = null;
    _isAnswered = false;
    _timedOut = false;
    _mistakes = [];
    _generateOptions();
    _startTimer();
    notifyListeners();
  }

  void reset() {
    _stopTimer();
    _quizWords = [];
    _currentIndex = 0;
    _score = 0;
    _totalXpEarned = 0;
    _currentOptions = [];
    _selectedOptionIndex = null;
    _isAnswered = false;
    _timedOut = false;
    _mistakes = [];
    _timeRemaining = AppConstants.quizTimerSeconds;
    notifyListeners();
  }

  @override
  void dispose() {
    _stopTimer();
    super.dispose();
  }
}
