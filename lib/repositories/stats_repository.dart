import '../models/daily_stats_model.dart';
import '../services/stats_service.dart';
import '../services/daily_goal_service.dart';
import '../utils/api_guard.dart';
import '../utils/result.dart';

/// Repository for daily statistics + streak tracking.
class StatsRepository {
  final StatsService _statsService;
  final DailyGoalService _dailyGoalService;

  StatsRepository(this._statsService, this._dailyGoalService);

  Future<Result<DailyStatsModel>> getOrCreateTodayStats(String userId) {
    return apiGuard(() => _statsService.getOrCreateTodayStats(userId));
  }

  Future<Result<void>> incrementStat(
      String userId, String field, int amount,) {
    return apiGuard(
        () => _statsService.incrementStat(userId, field, amount),);
  }

  Future<Result<List<DailyStatsModel>>> getStatsForRange(
      String userId, DateTime startDate, DateTime endDate,) {
    return apiGuard(
        () => _statsService.getStatsForRange(userId, startDate, endDate),);
  }

  Future<Result<int>> updateStreak(String userId) {
    return apiGuard(() => _statsService.updateStreak(userId));
  }

  Future<Result<int>> getGoal() {
    return apiGuard(() => _dailyGoalService.getGoal());
  }

  Future<Result<void>> setGoal(int goal) {
    return apiGuard(() => _dailyGoalService.setGoal(goal));
  }
}
