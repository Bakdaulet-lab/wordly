import 'dart:async';

import 'package:flutter/material.dart';
import '../models/word_model.dart';
import '../di/service_locator.dart';
import '../repositories/progress_repository.dart';

class ProgressProvider extends ChangeNotifier {
  final ProgressRepository _progressRepo = sl<ProgressRepository>();

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

    final result = await _progressRepo.getWordsForReview(userId);

    _isLoading = false;

    result.when(
      success: (items) {
        _reviewItems = items;
        _dueCount = items.length;
        _currentIndex = 0;
        notifyListeners();
      },
      failure: (error) {
        _errorMessage = error.userMessage;
        notifyListeners();
      },
    );
  }

  Future<void> refreshDueCount(String userId) async {
    final result = await _progressRepo.countDueWords(userId);
    result.when(
      success: (count) {
        _dueCount = count;
        notifyListeners();
      },
      failure: (_) {}, // Silent fail for count refresh
    );
  }

  Future<void> answerReview({
    required String userId,
    required bool knewIt,
  }) async {
    if (currentWord == null) return;

    final wordId = currentWord!.id;

    // Advance UI immediately
    _currentIndex++;
    notifyListeners();

    // Fire network calls in the background (non-blocking)
    unawaited(_progressRepo
        .answerReview(userId: userId, wordId: wordId, knewIt: knewIt)
        .then((_) {}));
  }

  void reset() {
    _reviewItems = [];
    _currentIndex = 0;
    notifyListeners();
  }
}
