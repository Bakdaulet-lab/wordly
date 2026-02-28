import 'dart:async';

import 'package:flutter/material.dart';
import '../models/word_model.dart';
import '../services/progress_service.dart';
import '../services/xp_service.dart';
import '../services/stats_service.dart';
import '../constants/app_constants.dart';

class ProgressProvider extends ChangeNotifier {
  final ProgressService _progressService = ProgressService();
  final XpService _xpService = XpService();
  final StatsService _statsService = StatsService();

  List<Map<String, dynamic>> _reviewItems = [];
  int _currentIndex = 0;
  int _dueCount = 0;
  bool _isLoading = false;
  String? _errorMessage;

  List<Map<String, dynamic>> get reviewItems => _reviewItems;
  int get currentIndex => _currentIndex;
  int get dueCount => _dueCount;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isReviewComplete => _currentIndex >= _reviewItems.length;

  WordModel? get currentWord {
    if (_currentIndex < _reviewItems.length) {
      final wordData = _reviewItems[_currentIndex]['words'];
      if (wordData != null) {
        return WordModel.fromJson(wordData);
      }
    }
    return null;
  }

  Future<void> loadDueWords(String userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _reviewItems = await _progressService.getWordsForReview(userId);
      _dueCount = _reviewItems.length;
      _currentIndex = 0;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshDueCount(String userId) async {
    try {
      _dueCount = await _progressService.countDueWords(userId);
      notifyListeners();
    } catch (e) {
      // Silent fail for count refresh
    }
  }

  Future<void> answerReview({
    required String userId,
    required bool knewIt,
  }) async {
    if (currentWord == null) return;

    final wordId = currentWord!.id;
    final quality = knewIt
        ? AppConstants.qualityCorrect
        : AppConstants.qualityWrong;
    final xp = knewIt
        ? AppConstants.xpCorrectAnswer
        : AppConstants.xpIncorrectAnswer;
    final statField = knewIt ? 'correct_answers' : 'incorrect_answers';

    // Advance UI immediately
    _currentIndex++;
    notifyListeners();

    // Fire all network calls in parallel in the background
    unawaited(Future.wait([
      _progressService.updateProgress(
        userId: userId,
        wordId: wordId,
        quality: quality,
      ),
      _xpService.awardXp(userId, xp),
      _statsService.incrementStat(userId, 'words_reviewed', 1),
      _statsService.incrementStat(userId, statField, 1),
      _statsService.incrementStat(userId, 'xp_earned', xp),
    ]));
  }

  void reset() {
    _reviewItems = [];
    _currentIndex = 0;
    notifyListeners();
  }
}
