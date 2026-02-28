import 'package:flutter_test/flutter_test.dart';
import 'package:wordly/models/word_model.dart';
import 'package:wordly/models/profile_model.dart';
import 'package:wordly/models/daily_stats_model.dart';
import 'package:wordly/models/achievement_model.dart';
import 'package:wordly/models/user_achievement_model.dart';
import 'package:wordly/models/user_word_progress_model.dart';
import 'package:wordly/models/quiz_option_model.dart';

void main() {
  group('WordModel', () {
    test('fromJson creates model correctly', () {
      final json = {
        'id': 1,
        'english_word': 'hello',
        'russian_translation': 'привет',
        'example_sentence': 'Hello world',
        'difficulty_level': 2,
        'category': 'greetings',
        'created_at': '2025-01-01T00:00:00Z',
      };
      final model = WordModel.fromJson(json);
      expect(model.id, 1);
      expect(model.englishWord, 'hello');
      expect(model.russianTranslation, 'привет');
      expect(model.exampleSentence, 'Hello world');
      expect(model.difficultyLevel, 2);
      expect(model.category, 'greetings');
    });

    test('fromJson handles missing optional fields', () {
      final json = {
        'id': 2,
        'english_word': 'test',
        'russian_translation': 'тест',
        'created_at': '2025-01-01T00:00:00Z',
      };
      final model = WordModel.fromJson(json);
      expect(model.exampleSentence, isNull);
      expect(model.difficultyLevel, 1);
      expect(model.category, 'general');
    });

    test('toJson produces expected keys', () {
      final model = WordModel(
        id: 1,
        englishWord: 'test',
        russianTranslation: 'тест',
        difficultyLevel: 1,
        category: 'general',
        createdAt: DateTime(2025, 1, 1),
      );
      final json = model.toJson();
      expect(json.containsKey('english_word'), isTrue);
      expect(json.containsKey('russian_translation'), isTrue);
      expect(json['english_word'], 'test');
    });
  });

  group('ProfileModel', () {
    test('fromJson creates model and copyWith works', () {
      final json = {
        'id': 'user-1',
        'display_name': 'Alice',
        'level': 3,
        'total_xp': 500,
        'current_streak': 5,
        'longest_streak': 10,
        'created_at': '2025-01-01T00:00:00Z',
      };
      final profile = ProfileModel.fromJson(json);
      expect(profile.displayName, 'Alice');
      expect(profile.level, 3);

      final updated = profile.copyWith(displayName: 'Bob');
      expect(updated.displayName, 'Bob');
      expect(updated.level, 3); // unchanged
    });
  });

  group('DailyStatsModel', () {
    test('fromJson uses defaults for missing numeric fields', () {
      final json = {
        'id': 1,
        'user_id': 'u1',
        'date': '2025-06-15',
      };
      final stats = DailyStatsModel.fromJson(json);
      expect(stats.wordsLearned, 0);
      expect(stats.xpEarned, 0);
    });
  });

  group('AchievementModel', () {
    test('fromJson creates model', () {
      final json = {
        'id': 1,
        'name': 'First Word',
        'description': 'Learn your first word',
        'condition_type': 'words_learned',
        'condition_value': 1,
        'created_at': '2025-01-01T00:00:00Z',
      };
      final achievement = AchievementModel.fromJson(json);
      expect(achievement.name, 'First Word');
      expect(achievement.iconName, 'star'); // default
    });
  });

  group('UserAchievementModel', () {
    test('fromJson and toJson round-trip key fields', () {
      final json = {
        'id': 10,
        'user_id': 'u1',
        'achievement_id': 5,
        'unlocked_at': '2025-03-01T12:00:00Z',
      };
      final model = UserAchievementModel.fromJson(json);
      expect(model.achievementId, 5);
      final out = model.toJson();
      expect(out['achievement_id'], 5);
    });
  });

  group('UserWordProgressModel', () {
    test('fromJson parses all fields', () {
      final json = {
        'id': 1,
        'user_id': 'u1',
        'word_id': 42,
        'ease_factor': 2.5,
        'interval_days': 6,
        'repetition_count': 2,
        'next_review_date': '2025-06-20',
        'last_review_date': '2025-06-14',
        'correct_count': 3,
        'incorrect_count': 1,
      };
      final model = UserWordProgressModel.fromJson(json);
      expect(model.wordId, 42);
      expect(model.easeFactor, 2.5);
      expect(model.correctCount, 3);
    });
  });

  group('QuizOptionModel', () {
    test('constructs correctly', () {
      const option =
          QuizOptionModel(wordId: 1, text: 'привет', isCorrect: true);
      expect(option.isCorrect, isTrue);
      expect(option.text, 'привет');
    });
  });
}
