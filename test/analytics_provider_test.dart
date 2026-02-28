import 'package:flutter_test/flutter_test.dart';
import 'package:wordly/providers/analytics_provider.dart';
import 'package:wordly/models/daily_stats_model.dart';

void main() {
  group('AnalyticsPeriod', () {
    test('week has 7 days', () {
      expect(AnalyticsPeriod.week.days, 7);
    });

    test('twoWeeks has 14 days', () {
      expect(AnalyticsPeriod.twoWeeks.days, 14);
    });

    test('month has 30 days', () {
      expect(AnalyticsPeriod.month.days, 30);
    });

    test('each period has a label', () {
      for (final p in AnalyticsPeriod.values) {
        expect(p.label, isNotEmpty);
      }
    });
  });

  group('ChartDataPoint', () {
    test('stores date and value', () {
      final date = DateTime(2026, 3, 1);
      final point = ChartDataPoint(date, 42.0);
      expect(point.date, DateTime(2026, 3, 1));
      expect(point.value, 42.0);
    });
  });

  group('AnalyticsSummary', () {
    test('empty summary has all zeros', () {
      const summary = AnalyticsSummary.empty;
      expect(summary.totalXp, 0);
      expect(summary.totalWordsLearned, 0);
      expect(summary.totalWordsReviewed, 0);
      expect(summary.totalCorrect, 0);
      expect(summary.totalIncorrect, 0);
      expect(summary.totalStudySeconds, 0);
      expect(summary.averageAccuracy, 0);
      expect(summary.averageDailyXp, 0);
      expect(summary.bestDayXp, 0);
      expect(summary.bestDayDate, isNull);
      expect(summary.activeDays, 0);
    });

    test('summary stores all values correctly', () {
      final summary = AnalyticsSummary(
        totalXp: 500,
        totalWordsLearned: 25,
        totalWordsReviewed: 80,
        totalCorrect: 60,
        totalIncorrect: 20,
        totalStudySeconds: 3600,
        averageAccuracy: 0.75,
        averageDailyXp: 71.4,
        bestDayXp: 120,
        bestDayDate: DateTime(2026, 2, 28),
        activeDays: 5,
      );

      expect(summary.totalXp, 500);
      expect(summary.totalWordsLearned, 25);
      expect(summary.totalWordsReviewed, 80);
      expect(summary.totalCorrect, 60);
      expect(summary.totalIncorrect, 20);
      expect(summary.totalStudySeconds, 3600);
      expect(summary.averageAccuracy, 0.75);
      expect(summary.averageDailyXp, 71.4);
      expect(summary.bestDayXp, 120);
      expect(summary.bestDayDate, DateTime(2026, 2, 28));
      expect(summary.activeDays, 5);
    });
  });

  group('AnalyticsPeriod labels', () {
    test('week label is descriptive', () {
      expect(AnalyticsPeriod.week.label, 'Last 7 Days');
    });

    test('twoWeeks label is descriptive', () {
      expect(AnalyticsPeriod.twoWeeks.label, 'Last 14 Days');
    });

    test('month label is descriptive', () {
      expect(AnalyticsPeriod.month.label, 'Last 30 Days');
    });
  });

  group('DailyStatsModel used by analytics', () {
    test('fromJson parses all fields for analytics', () {
      final json = {
        'id': 1,
        'user_id': 'user-123',
        'date': '2026-02-25',
        'words_learned': 5,
        'words_reviewed': 15,
        'correct_answers': 12,
        'incorrect_answers': 3,
        'xp_earned': 130,
        'session_duration_seconds': 600,
      };

      final model = DailyStatsModel.fromJson(json);
      expect(model.wordsLearned, 5);
      expect(model.wordsReviewed, 15);
      expect(model.correctAnswers, 12);
      expect(model.incorrectAnswers, 3);
      expect(model.xpEarned, 130);
      expect(model.sessionDurationSeconds, 600);
    });

    test('accuracy can be computed from daily stats fields', () {
      final json = {
        'id': 2,
        'user_id': 'user-123',
        'date': '2026-02-26',
        'words_learned': 3,
        'words_reviewed': 10,
        'correct_answers': 8,
        'incorrect_answers': 2,
        'xp_earned': 90,
        'session_duration_seconds': 300,
      };

      final model = DailyStatsModel.fromJson(json);
      final total = model.correctAnswers + model.incorrectAnswers;
      final accuracy = total > 0 ? model.correctAnswers / total : 0.0;
      expect(accuracy, 0.8);
    });

    test('zero answers yields zero accuracy', () {
      final json = {
        'id': 3,
        'user_id': 'user-123',
        'date': '2026-02-27',
        'words_learned': 0,
        'words_reviewed': 0,
        'correct_answers': 0,
        'incorrect_answers': 0,
        'xp_earned': 0,
        'session_duration_seconds': 0,
      };

      final model = DailyStatsModel.fromJson(json);
      final total = model.correctAnswers + model.incorrectAnswers;
      final accuracy = total > 0 ? model.correctAnswers / total : 0.0;
      expect(accuracy, 0.0);
    });
  });
}
