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
    _mistakes = [];
    _generateOptions();
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

  Future<void> selectAnswer(int optionIndex, String userId) async {
    if (_isAnswered) return;

    _selectedOptionIndex = optionIndex;
    _isAnswered = true;

    final option = _currentOptions[optionIndex];
    final isCorrect = option.isCorrect;

    if (isCorrect) {
      _score++;
      final xp = AppConstants.xpCorrectAnswer;
      _totalXpEarned += xp;
      await _xpService.awardXp(userId, xp);
      await _statsService.incrementStat(userId, 'correct_answers', 1);
    } else {
      final xp = AppConstants.xpIncorrectAnswer;
      _totalXpEarned += xp;
      await _xpService.awardXp(userId, xp);
      await _statsService.incrementStat(userId, 'incorrect_answers', 1);
      _mistakes.add(currentWord!);
    }

    // Update spaced repetition progress
    final quality = isCorrect
        ? AppConstants.qualityCorrect
        : AppConstants.qualityWrong;
    await _progressService.updateProgress(
      userId: userId,
      wordId: currentWord!.id,
      quality: quality,
    );

    notifyListeners();
  }

  void nextQuestion() {
    _currentIndex++;
    _selectedOptionIndex = null;
    _isAnswered = false;

    if (!isQuizComplete) {
      _generateOptions();
    }
    notifyListeners();
  }

  Future<void> finishQuiz(String userId) async {
    // Bonus for perfect quiz
    if (_score == _quizWords.length && _quizWords.isNotEmpty) {
      final bonus = AppConstants.xpPerfectQuizBonus;
      _totalXpEarned += bonus;
      await _xpService.awardXp(userId, bonus);
    }

    await _statsService.incrementStat(userId, 'words_reviewed', _quizWords.length);
    await _statsService.incrementStat(userId, 'xp_earned', _totalXpEarned);
    notifyListeners();
  }

  void reset() {
    _quizWords = [];
    _currentIndex = 0;
    _score = 0;
    _totalXpEarned = 0;
    _currentOptions = [];
    _selectedOptionIndex = null;
    _isAnswered = false;
    _mistakes = [];
    notifyListeners();
  }
}
