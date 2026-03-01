import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../di/service_locator.dart';
import '../models/quiz_option_model.dart';
import '../models/word_lifter_phase.dart';
import '../models/word_model.dart';
import '../services/interfaces/i_quiz_service.dart';
import '../utils/xp_calculator.dart';

/// Manages all state for the Word Lifter gym mini-game.
///
/// Core loop:
///  1. Show an English word + 4 translations.
///  2. Correct answer → barbell lifts (streak +1).
///  3. 5 correct in a row → successful rep → weight goes up.
///  4. Wrong / timeout → barbell drops, streak resets, failed rep.
///  5. 3 failed reps → game over.
class WordLifterProvider extends ChangeNotifier {
  final IQuizService _quizService = sl<IQuizService>();
  final Random _random = Random();

  // ── Configuration ───────────────────────────────────────────────
  static const int _timerDuration = 8; // seconds per question
  static const int _streakForRep = 5; // correct answers needed for one rep
  static const int _maxFailedReps = 3; // game ends after this many fails
  static const int _weightIncrement = 10; // kg gained per successful rep
  static const int _startingWeight = 40; // starting barbell weight

  // ── Word pool ───────────────────────────────────────────────────
  List<WordModel> _allWords = [];
  List<WordModel> _remainingWords = [];

  // ── Current question ────────────────────────────────────────────
  WordModel? _currentWord;
  List<QuizOptionModel> _options = [];
  int? _selectedOptionIndex;
  bool _lastAnswerCorrect = false;

  // ── Streak & reps ──────────────────────────────────────────────
  int _correctStreak = 0;
  int _currentRep = 1;
  int _totalSuccessfulReps = 0;
  int _failedReps = 0;

  // ── Weight & barbell ───────────────────────────────────────────
  int _currentWeight = _startingWeight;

  /// 0.0 = floor, 1.0 = fully lifted. Each correct answer adds 1/_streakForRep.
  double _barbellPosition = 0.0;
  bool _isLifting = false;
  bool _isDropping = false;

  // ── Timer ──────────────────────────────────────────────────────
  int _timerSeconds = _timerDuration;
  Timer? _timer;

  // ── Scoring ────────────────────────────────────────────────────
  int _totalXpEarned = 0;
  int _questionsAnswered = 0;
  int _correctAnswers = 0;
  final List<WordModel> _mistakes = [];

  // ── Phase ──────────────────────────────────────────────────────
  WordLifterPhase _gamePhase = WordLifterPhase.ready;

  // ═══════════════════════════════════════════════════════════════
  // Getters
  // ═══════════════════════════════════════════════════════════════
  WordModel? get currentWord => _currentWord;
  List<QuizOptionModel> get options => List.unmodifiable(_options);
  int? get selectedOptionIndex => _selectedOptionIndex;
  bool get lastAnswerCorrect => _lastAnswerCorrect;

  int get correctStreak => _correctStreak;
  int get currentRep => _currentRep;
  int get totalSuccessfulReps => _totalSuccessfulReps;
  int get failedReps => _failedReps;
  int get maxFailedReps => _maxFailedReps;
  int get streakForRep => _streakForRep;

  int get currentWeight => _currentWeight;
  double get barbellPosition => _barbellPosition;
  bool get isLifting => _isLifting;
  bool get isDropping => _isDropping;

  int get timerSeconds => _timerSeconds;
  int get timerDuration => _timerDuration;

  int get totalXpEarned => _totalXpEarned;
  int get questionsAnswered => _questionsAnswered;
  int get correctAnswers => _correctAnswers;
  List<WordModel> get mistakes => List.unmodifiable(_mistakes);

  WordLifterPhase get gamePhase => _gamePhase;
  bool get isAnswered => _selectedOptionIndex != null;

  double get accuracy =>
      _questionsAnswered > 0 ? _correctAnswers / _questionsAnswered : 0.0;

  // ═══════════════════════════════════════════════════════════════
  // Game lifecycle
  // ═══════════════════════════════════════════════════════════════

  /// Initialise and start a new game session.
  void startGame(List<WordModel> allWords) {
    if (allWords.length < 4) return; // Need at least 4 for options

    _allWords = List.of(allWords);
    _remainingWords = List.of(allWords)..shuffle(_random);
    _correctStreak = 0;
    _currentRep = 1;
    _totalSuccessfulReps = 0;
    _failedReps = 0;
    _currentWeight = _startingWeight;
    _barbellPosition = 0.0;
    _isLifting = false;
    _isDropping = false;
    _totalXpEarned = 0;
    _questionsAnswered = 0;
    _correctAnswers = 0;
    _mistakes.clear();
    _selectedOptionIndex = null;
    _lastAnswerCorrect = false;

    _gamePhase = WordLifterPhase.playing;
    _loadNextQuestion();
    notifyListeners();
  }

  /// Submit the user's answer by option index.
  void submitAnswer(int index) {
    if (_gamePhase != WordLifterPhase.playing) return;
    if (_selectedOptionIndex != null) return; // already answered
    if (index < 0 || index >= _options.length) return;

    _cancelTimer();
    _selectedOptionIndex = index;
    _questionsAnswered++;

    final isCorrect = _options[index].isCorrect;
    _lastAnswerCorrect = isCorrect;

    if (isCorrect) {
      _correctAnswers++;
      _correctStreak++;
      _totalXpEarned += XpCalculator.xpForCorrectAnswer();

      // Lift the barbell proportionally
      _isLifting = true;
      _isDropping = false;
      _barbellPosition =
          (_correctStreak / _streakForRep).clamp(0.0, 1.0);

      notifyListeners();

      // Check for rep completion
      if (_correctStreak >= _streakForRep) {
        _scheduleRepSuccess();
      } else {
        _scheduleNextQuestion();
      }
    } else {
      _totalXpEarned += XpCalculator.xpForIncorrectAnswer();
      if (_currentWord != null && !_mistakes.contains(_currentWord)) {
        _mistakes.add(_currentWord!);
      }

      // Drop the barbell
      _isLifting = false;
      _isDropping = true;
      _barbellPosition = 0.0;
      _correctStreak = 0;

      notifyListeners();
      _scheduleRepFail();
    }
  }

  /// Called when the per-question timer runs out.
  void _onTimeout() {
    if (_gamePhase != WordLifterPhase.playing) return;
    if (_selectedOptionIndex != null) return;

    _questionsAnswered++;
    _selectedOptionIndex = -1; // sentinel: timed out
    _lastAnswerCorrect = false;

    if (_currentWord != null && !_mistakes.contains(_currentWord)) {
      _mistakes.add(_currentWord!);
    }

    _isLifting = false;
    _isDropping = true;
    _barbellPosition = 0.0;
    _correctStreak = 0;

    notifyListeners();
    _scheduleRepFail();
  }

  // ═══════════════════════════════════════════════════════════════
  // Internal helpers
  // ═══════════════════════════════════════════════════════════════

  void _loadNextQuestion() {
    if (_remainingWords.isEmpty) {
      _remainingWords = List.of(_allWords)..shuffle(_random);
    }
    _currentWord = _remainingWords.removeLast();
    _options = _quizService.generateOptions(
      correctWord: _currentWord!,
      allWords: _allWords,
    );
    _selectedOptionIndex = null;
    _lastAnswerCorrect = false;
    _startTimer();
  }

  void _startTimer() {
    _timerSeconds = _timerDuration;
    _cancelTimer();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _timerSeconds--;
      if (_timerSeconds <= 0) {
        timer.cancel();
        _onTimeout();
      } else {
        notifyListeners();
      }
    });
  }

  void _cancelTimer() {
    _timer?.cancel();
    _timer = null;
  }

  void _scheduleNextQuestion() {
    Future.delayed(const Duration(milliseconds: 800), () {
      if (_gamePhase != WordLifterPhase.playing) return;
      _isLifting = false;
      _loadNextQuestion();
      notifyListeners();
    });
  }

  void _scheduleRepSuccess() {
    _gamePhase = WordLifterPhase.repSuccess;
    _totalSuccessfulReps++;
    _totalXpEarned += 25; // bonus XP for completing a rep
    notifyListeners();

    Future.delayed(const Duration(milliseconds: 1800), () {
      if (_gamePhase != WordLifterPhase.repSuccess) return;

      _correctStreak = 0;
      _currentWeight += _weightIncrement;
      _barbellPosition = 0.0;
      _isLifting = false;
      _isDropping = false;
      _currentRep++;
      _gamePhase = WordLifterPhase.playing;

      _loadNextQuestion();
      notifyListeners();
    });
  }

  void _scheduleRepFail() {
    _gamePhase = WordLifterPhase.repFail;
    _failedReps++;
    notifyListeners();

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (_gamePhase != WordLifterPhase.repFail) return;

      _isDropping = false;

      if (_failedReps >= _maxFailedReps) {
        _gamePhase = WordLifterPhase.finished;
      } else {
        _gamePhase = WordLifterPhase.playing;
        _loadNextQuestion();
      }
      notifyListeners();
    });
  }

  /// Reset the provider so it can be reused for a new game.
  void reset() {
    _cancelTimer();
    _gamePhase = WordLifterPhase.ready;
    _allWords = [];
    _remainingWords = [];
    _currentWord = null;
    _options = [];
    _selectedOptionIndex = null;
    _correctStreak = 0;
    _currentRep = 1;
    _totalSuccessfulReps = 0;
    _failedReps = 0;
    _currentWeight = _startingWeight;
    _barbellPosition = 0.0;
    _isLifting = false;
    _isDropping = false;
    _timerSeconds = _timerDuration;
    _totalXpEarned = 0;
    _questionsAnswered = 0;
    _correctAnswers = 0;
    _mistakes.clear();
    _lastAnswerCorrect = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _cancelTimer();
    super.dispose();
  }
}
