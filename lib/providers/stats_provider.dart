import 'package:flutter/material.dart';
import '../models/daily_stats_model.dart';
import '../services/stats_service.dart';

class StatsProvider extends ChangeNotifier {
  final StatsService _statsService = StatsService();

  DailyStatsModel? _todayStats;
  List<DailyStatsModel> _recentStats = [];
  int _currentStreak = 0;
  bool _isLoading = false;
  String? _errorMessage;

  DailyStatsModel? get todayStats => _todayStats;
  List<DailyStatsModel> get recentStats => _recentStats;
  int get currentStreak => _currentStreak;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  int get todayWordsLearned => _todayStats?.wordsLearned ?? 0;
  int get todayWordsReviewed => _todayStats?.wordsReviewed ?? 0;
  int get todayCorrectAnswers => _todayStats?.correctAnswers ?? 0;
  int get todayIncorrectAnswers => _todayStats?.incorrectAnswers ?? 0;
  int get todayXpEarned => _todayStats?.xpEarned ?? 0;

  double get todayAccuracy {
    final total = todayCorrectAnswers + todayIncorrectAnswers;
    if (total == 0) return 0;
    return todayCorrectAnswers / total;
  }

  Future<void> loadStats(String userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Update streak
      await _statsService.updateStreak(userId);

      // Load today's stats
      _todayStats = await _statsService.getOrCreateTodayStats(userId);

      // Load last 30 days
      final now = DateTime.now();
      final thirtyDaysAgo = now.subtract(const Duration(days: 30));
      _recentStats = await _statsService.getStatsForRange(
        userId,
        thirtyDaysAgo,
        now,
      );

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshTodayStats(String userId) async {
    try {
      _todayStats = await _statsService.getOrCreateTodayStats(userId);
      notifyListeners();
    } catch (e) {
      // Silent fail for refresh
    }
  }
}
