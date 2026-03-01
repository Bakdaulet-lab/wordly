import '../models/daily_stats_model.dart';
import '../di/service_locator.dart';
import '../repositories/stats_repository.dart';
import '../services/daily_goal_service.dart';
import '../services/logger_service.dart';
import 'base_provider.dart';

/// Exposes daily statistics, streaks, and goal progress to the UI.
class StatsProvider extends BaseProvider {
  final StatsRepository _statsRepo = sl<StatsRepository>();

  DailyStatsModel? _todayStats;
  List<DailyStatsModel> _recentStats = [];
  int _currentStreak = 0;
  int _dailyXpGoal = DailyGoalService.defaultGoal;

  DailyStatsModel? get todayStats => _todayStats;
  List<DailyStatsModel> get recentStats => _recentStats;
  int get currentStreak => _currentStreak;
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
    setLoading(true);
    clearError();

    // Update streak
    final streakResult = await _statsRepo.updateStreak(userId);
    streakResult.when(
      success: (streak) => _currentStreak = streak,
      failure: (error) => AppLogger.warning('updateStreak failed: ${error.userMessage}', tag: 'StatsProvider'),
    );

    // Load today's stats and daily goal in parallel
    final todayResult = await _statsRepo.getOrCreateTodayStats(userId);
    final goalResult = await _statsRepo.getGoal();
    goalResult.when(
      success: (goal) => _dailyXpGoal = goal,
      failure: (error) => AppLogger.warning('getGoal failed: ${error.userMessage}', tag: 'StatsProvider'),
    );

    todayResult.when(
      success: (stats) => _todayStats = stats,
      failure: (error) => setError(error.userMessage, notify: false),
    );

    // Load last 30 days
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    final rangeResult =
        await _statsRepo.getStatsForRange(userId, thirtyDaysAgo, now);
    rangeResult.when(
      success: (stats) => _recentStats = stats,
      failure: (error) {
        if (errorMessage == null) setError(error.userMessage, notify: false);
      },
    );

    setLoading(false);
  }

  Future<void> refreshTodayStats(String userId) async {
    final result = await _statsRepo.getOrCreateTodayStats(userId);
    result.when(
      success: (stats) {
        _todayStats = stats;
        notifyListeners();
      },
      failure: (_) {}, // Silent fail for refresh
    );
  }

  Future<void> setDailyGoal(int goal) async {
    _dailyXpGoal = goal;
    final result = await _statsRepo.setGoal(goal);
    result.when(
      success: (_) {},
      failure: (error) => AppLogger.warning('setDailyGoal failed: ${error.userMessage}', tag: 'StatsProvider'),
    );
    notifyListeners();
  }
}
