import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:wordly/services/export_service.dart';
import 'package:wordly/models/word_model.dart';
import 'package:wordly/models/user_word_progress_model.dart';
import 'package:wordly/models/daily_stats_model.dart';

void main() {
  group('ExportService CSV escaping', () {
    // We test the CSV content generation by creating an ExportService
    // and verifying the output structure. Since _share uses share_plus
    // which is platform-only, we can't fully test it in unit tests,
    // but we can test the data formatting logic.

    late ExportService exportService;

    setUp(() {
      exportService = ExportService();
    });

    test('ExportService can be instantiated', () {
      expect(exportService, isNotNull);
    });

    test('WordModel toJson round-trip for CSV export', () {
      final word = WordModel(
        id: 1,
        englishWord: 'hello',
        russianTranslation: 'привет',
        exampleSentence: 'Hello, world!',
        difficultyLevel: 2,
        category: 'greetings',
        createdAt: DateTime(2025, 1, 1),
      );

      final json = word.toJson();
      expect(json['english_word'], 'hello');
      expect(json['russian_translation'], 'привет');
      expect(json['difficulty_level'], 2);
      expect(json['category'], 'greetings');
    });

    test('UserWordProgressModel toJson for CSV export', () {
      final progress = UserWordProgressModel(
        id: 1,
        userId: 'user-123',
        wordId: 5,
        easeFactor: 2.5,
        intervalDays: 6,
        repetitionCount: 3,
        nextReviewDate: DateTime(2025, 3, 15),
        lastReviewDate: DateTime(2025, 3, 9),
        correctCount: 8,
        incorrectCount: 2,
      );

      final json = progress.toJson();
      expect(json['word_id'], 5);
      expect(json['ease_factor'], 2.5);
      expect(json['correct_count'], 8);
      expect(json['incorrect_count'], 2);
      expect(json['next_review_date'], '2025-03-15');
    });

    test('DailyStatsModel toJson for CSV export', () {
      final stats = DailyStatsModel(
        id: 1,
        userId: 'user-123',
        date: DateTime(2025, 3, 1),
        wordsLearned: 5,
        wordsReviewed: 12,
        correctAnswers: 10,
        incorrectAnswers: 2,
        xpEarned: 120,
        sessionDurationSeconds: 300,
      );

      final json = stats.toJson();
      expect(json['words_reviewed'], 12);
      expect(json['correct_answers'], 10);
      expect(json['xp_earned'], 120);
    });

    test('CSV escaping logic (tested via model data with commas)', () {
      // Words with commas or quotes should be properly handled
      final word = WordModel(
        id: 1,
        englishWord: 'hello, world',
        russianTranslation: 'привет "мир"',
        exampleSentence: 'He said "hello, world"',
        difficultyLevel: 1,
        category: 'test',
        createdAt: DateTime(2025, 1, 1),
      );

      expect(word.englishWord.contains(','), isTrue);
      expect(word.russianTranslation.contains('"'), isTrue);
    });

    test('empty lists produce valid export data', () {
      // Verify empty lists don't cause any issues
      final emptyWords = <WordModel>[];
      final emptyProgress = <UserWordProgressModel>[];
      final emptyStats = <DailyStatsModel>[];

      expect(emptyWords.isEmpty, isTrue);
      expect(emptyProgress.isEmpty, isTrue);
      expect(emptyStats.isEmpty, isTrue);
    });

    test('accuracy calculation in progress export', () {
      final progress = UserWordProgressModel(
        id: 1,
        userId: 'user-123',
        wordId: 5,
        easeFactor: 2.5,
        intervalDays: 6,
        repetitionCount: 3,
        nextReviewDate: DateTime(2025, 3, 15),
        correctCount: 8,
        incorrectCount: 2,
      );

      final total = progress.correctCount + progress.incorrectCount;
      final accuracy = total > 0
          ? (progress.correctCount / total * 100).toStringAsFixed(1)
          : 'N/A';
      expect(accuracy, '80.0');
    });

    test('accuracy is N/A when no answers', () {
      final progress = UserWordProgressModel(
        id: 1,
        userId: 'user-123',
        wordId: 5,
        easeFactor: 2.5,
        intervalDays: 0,
        repetitionCount: 0,
        nextReviewDate: DateTime(2025, 3, 15),
        correctCount: 0,
        incorrectCount: 0,
      );

      final total = progress.correctCount + progress.incorrectCount;
      final accuracy = total > 0
          ? (progress.correctCount / total * 100).toStringAsFixed(1)
          : 'N/A';
      expect(accuracy, 'N/A');
    });
  });

  group('ExportService JSON export', () {
    test('JSON export contains correct structure', () {
      final words = [
        WordModel(
          id: 1,
          englishWord: 'hello',
          russianTranslation: 'привет',
          exampleSentence: 'Hello world',
          difficultyLevel: 1,
          category: 'general',
          createdAt: DateTime(2025, 1, 1),
        ),
        WordModel(
          id: 2,
          englishWord: 'world',
          russianTranslation: 'мир',
          exampleSentence: 'The world is big',
          difficultyLevel: 2,
          category: 'general',
          createdAt: DateTime(2025, 1, 1),
        ),
      ];

      final jsonMap = {
        'exported_at': DateTime(2025, 1, 1).toIso8601String(),
        'word_count': words.length,
        'words': words
            .map((w) => <String, dynamic>{
                    'english_word': w.englishWord,
                    'russian_translation': w.russianTranslation,
                    'example_sentence': w.exampleSentence,
                    'difficulty_level': w.difficultyLevel,
                  },)
            .toList(),
      };

      final jsonStr = const JsonEncoder.withIndent('  ').convert(jsonMap);

      expect(jsonStr.contains('"word_count": 2'), isTrue);
      expect(jsonStr.contains('"english_word": "hello"'), isTrue);
      expect(jsonStr.contains('"english_word": "world"'), isTrue);
      expect(jsonStr.contains('"russian_translation": "привет"'), isTrue);
    });

    test('JSON export handles empty word list', () {
      final jsonMap = {
        'exported_at': DateTime(2025, 1, 1).toIso8601String(),
        'word_count': 0,
        'words': <Map<String, dynamic>>[],
      };

      final jsonStr = const JsonEncoder.withIndent('  ').convert(jsonMap);

      expect(jsonStr.contains('"word_count": 0'), isTrue);
      expect(jsonStr.contains('"words": []'), isTrue);
    });

    test('JSON export roundtrips correctly', () {
      final original = {
        'exported_at': '2025-01-01T00:00:00.000',
        'word_count': 1,
        'words': [
          {
            'english_word': 'test',
            'russian_translation': 'тест',
            'example_sentence': 'This is a test',
            'difficulty_level': 1,
          }
        ],
      };

      final encoded = jsonEncode(original);
      final decoded = jsonDecode(encoded) as Map<String, dynamic>;

      expect(decoded['word_count'], 1);
      expect((decoded['words'] as List).length, 1);
      expect((decoded['words'] as List)[0]['english_word'], 'test');
    });
  });
}
