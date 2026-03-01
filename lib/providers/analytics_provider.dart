import '../models/daily_stats_model.dart';
import '../di/service_locator.dart';
import '../repositories/stats_repository.dart';
import 'base_provider.dart';

/// Time range for analytics charts.
enum AnalyticsPeriod {
  week(7, 'Last 7 Days'),
  twoWeeks(14, 'Last 14 Days'),
  month(30, 'Last 30 Days');

  final int days;
  final String label;
  const AnalyticsPeriod(this.days, this.label);
}

/// Aggregated analytics data point for charts.
class ChartDataPoint {
  final DateTime date;
  final double value;

  const ChartDataPoint(this.date, this.value);
}

/// Summary statistics computed from daily stats.
class AnalyticsSummary {
  final int totalXp;
  final int totalWordsLearned;
  final int totalWordsReviewed;
  final int totalCorrect;
  final int totalIncorrect;
  final int totalStudySeconds;
  final double averageAccuracy;
  final double averageDailyXp;
  final int bestDayXp;
  final DateTime? bestDayDate;
  final int activeDays;

  const AnalyticsSummary({
    required this.totalXp,
    required this.totalWordsLearned,
    required this.totalWordsReviewed,
    required this.totalCorrect,
    required this.totalIncorrect,
    required this.totalStudySeconds,
    required this.averageAccuracy,
    required this.averageDailyXp,
    required this.bestDayXp,
    this.bestDayDate,
    required this.activeDays,
  });

  static const empty = AnalyticsSummary(
    totalXp: 0,
    totalWordsLearned: 0,
    totalWordsReviewed: 0,
    totalCorrect: 0,
    totalIncorrect: 0,
    totalStudySeconds: 0,
    averageAccuracy: 0,
    averageDailyXp: 0,
    bestDayXp: 0,
    activeDays: 0,
  );
}

/// Provides aggregated analytics data for charts and summaries.
class AnalyticsProvider extends BaseProvider {
  final StatsRepository _statsRepo = sl<StatsRepository>();

  List<DailyStatsModel> _allStats = [];
  AnalyticsPeriod _selectedPeriod = AnalyticsPeriod.week;

  AnalyticsPeriod get selectedPeriod => _selectedPeriod;

  /// Filtered stats for the selected period.
  List<DailyStatsModel> get filteredStats {
    final cutoff =
        DateTime.now().subtract(Duration(days: _selectedPeriod.days));
    return _allStats
        .where((s) => s.date.isAfter(cutoff) || _isSameDay(s.date, cutoff))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  /// Summary computed from filtered stats.
  AnalyticsSummary get summary {
    final stats = filteredStats;
    if (stats.isEmpty) return AnalyticsSummary.empty;

    int totalXp = 0;
    int totalWordsLearned = 0;
    int totalWordsReviewed = 0;
    int totalCorrect = 0;
    int totalIncorrect = 0;
    int totalStudySeconds = 0;
    int bestDayXp = 0;
    DateTime? bestDayDate;
    int activeDays = 0;

    for (final s in stats) {
      totalXp += s.xpEarned;
      totalWordsLearned += s.wordsLearned;
      totalWordsReviewed += s.wordsReviewed;
      totalCorrect += s.correctAnswers;
      totalIncorrect += s.incorrectAnswers;
      totalStudySeconds += s.sessionDurationSeconds;

      if (s.xpEarned > 0 ||
          s.wordsLearned > 0 ||
          s.wordsReviewed > 0) {
        activeDays++;
      }

      if (s.xpEarned > bestDayXp) {
        bestDayXp = s.xpEarned;
        bestDayDate = s.date;
      }
    }

    final totalAnswers = totalCorrect + totalIncorrect;
    final avgAccuracy = totalAnswers > 0 ? totalCorrect / totalAnswers : 0.0;
    final avgDailyXp =
        _selectedPeriod.days > 0 ? totalXp / _selectedPeriod.days : 0.0;

    return AnalyticsSummary(
      totalXp: totalXp,
      totalWordsLearned: totalWordsLearned,
      totalWordsReviewed: totalWordsReviewed,
      totalCorrect: totalCorrect,
      totalIncorrect: totalIncorrect,
      totalStudySeconds: totalStudySeconds,
      averageAccuracy: avgAccuracy,
      averageDailyXp: avgDailyXp,
      bestDayXp: bestDayXp,
      bestDayDate: bestDayDate,
      activeDays: activeDays,
    );
  }

  /// XP data points for the selected period (one per day).
  List<ChartDataPoint> get xpChartData =>
      _buildDailyPoints((s) => s.xpEarned.toDouble());

  /// Accuracy data points for the selected period (0.0 – 1.0 per day).
  List<ChartDataPoint> get accuracyChartData => _buildDailyPoints((s) {
        final total = s.correctAnswers + s.incorrectAnswers;
        return total > 0 ? s.correctAnswers / total : 0.0;
      });

  /// Words reviewed per day.
  List<ChartDataPoint> get wordsReviewedChartData =>
      _buildDailyPoints((s) => s.wordsReviewed.toDouble());

  /// Words learned per day.
  List<ChartDataPoint> get wordsLearnedChartData =>
      _buildDailyPoints((s) => s.wordsLearned.toDouble());

  /// Study time in minutes per day.
  List<ChartDataPoint> get studyTimeChartData =>
      _buildDailyPoints((s) => s.sessionDurationSeconds / 60.0);

  /// Builds chart points filling in missing days with 0.
  List<ChartDataPoint> _buildDailyPoints(
      double Function(DailyStatsModel) extractor,) {
    final now = DateTime.now();
    final days = _selectedPeriod.days;
    final statsMap = <String, DailyStatsModel>{};
    for (final s in filteredStats) {
      statsMap[_dateKey(s.date)] = s;
    }

    final points = <ChartDataPoint>[];
    for (int i = days - 1; i >= 0; i--) {
      final day = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: i));
      final stat = statsMap[_dateKey(day)];
      final value = stat != null ? extractor(stat) : 0.0;
      points.add(ChartDataPoint(day, value));
    }
    return points;
  }

  /// Load analytics data from repository.
  Future<void> loadAnalytics(String userId) async {
    setLoading(true);
    clearError();

    final now = DateTime.now();
    final startDate = now.subtract(const Duration(days: 30));
    final result =
        await _statsRepo.getStatsForRange(userId, startDate, now);

    result.when(
      success: (stats) {
        _allStats = stats;
      },
      failure: (error) {
        setError(error.userMessage, notify: false);
      },
    );

    setLoading(false);
  }

  void setPeriod(AnalyticsPeriod period) {
    if (_selectedPeriod == period) return;
    _selectedPeriod = period;
    notifyListeners();
  }

  static String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
