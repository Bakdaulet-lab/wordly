import 'package:flutter/material.dart';
import '../models/daily_stats_model.dart';
import '../services/stats_service.dart';
import '../services/daily_goal_service.dart';
import '../utils/error_helpers.dart';

class StatsProvider extends ChangeNotifier {
  final StatsService _statsService = StatsService();
  final DailyGoalService _dailyGoalService = DailyGoalService();

  DailyStatsModel? _todayStats;
  List<DailyStatsModel> _recentStats = [];
  int _currentStreak = 0;
  bool _isLoading = false;
  String? _errorMessage;
  int _dailyXpGoal = DailyGoalService.defaultGoal;

  DailyStatsModel? get todayStats => _todayStats;
  List<DailyStatsModel> get recentStats => _recentStats;
  int get currentStreak => _currentStreak;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get dailyXpGoal => _dailyXpGoal;

  double get dailyGoalProgress {
    if (_dailyXpGoal <= 0) return 1.0;
    return (todayXpEarned / _dailyXpGoal).clamp(0.0, 1.0);
  }

  bool get dailyGoalReached => todayXpEarned >= _dailyXpGoal;

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

      // Load today's stats and daily goal in parallel
      final results = await Future.wait([
        _statsService.getOrCreateTodayStats(userId),
        _dailyGoalService.getGoal(),
      ]);
      _todayStats = results[0] as DailyStatsModel;
      _dailyXpGoal = results[1] as int;

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
      _errorMessage = friendlyError(e);
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

  Future<void> setDailyGoal(int goal) async {
    _dailyXpGoal = goal;
    await _dailyGoalService.setGoal(goal);
    notifyListeners();
  }
}
