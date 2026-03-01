import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wordly/models/word_model.dart';
import 'package:wordly/services/connectivity_service.dart';
import 'package:wordly/services/local_database.dart';
import 'package:wordly/services/offline_cache_service.dart';

// ── Mocks ────────────────────────────────────────────────────────────────

class MockLocalDatabase extends Mock implements LocalDatabase {}

class MockConnectivityService extends Mock implements ConnectivityService {}

// ── Helpers ──────────────────────────────────────────────────────────────

Map<String, dynamic> _wordRow({
  required int id,
  String englishWord = 'test',
  String russianTranslation = 'тест',
  String category = 'general',
  int difficultyLevel = 1,
}) =>
    {
      'id': id,
      'english_word': englishWord,
      'russian_translation': russianTranslation,
      'example_sentence': null,
      'difficulty_level': difficultyLevel,
      'category': category,
      'created_at': '2025-01-01T00:00:00.000',
    };

Map<String, dynamic> _progressRow({
  int id = 1,
  String userId = 'u1',
  int wordId = 1,
  String nextReviewDate = '2025-01-01',
}) =>
    {
      'id': id,
      'user_id': userId,
      'word_id': wordId,
      'ease_factor': 2.5,
      'interval_days': 0,
      'repetition_count': 0,
      'next_review_date': nextReviewDate,
      'last_review_date': null,
      'correct_count': 0,
      'incorrect_count': 0,
    };

Map<String, dynamic> _statsRow({
  int id = 1,
  String userId = 'u1',
  String date = '2025-06-01',
  int xpEarned = 50,
  int wordsReviewed = 5,
}) =>
    {
      'id': id,
      'user_id': userId,
      'date': date,
      'words_learned': 0,
      'words_reviewed': wordsReviewed,
      'correct_answers': 3,
      'incorrect_answers': 2,
      'xp_earned': xpEarned,
      'session_duration_seconds': 120,
    };

// ── Tests ────────────────────────────────────────────────────────────────

void main() {
  late MockLocalDatabase mockDb;
  late MockConnectivityService mockConn;
  late OfflineCacheService cache;

  setUp(() {
    mockDb = MockLocalDatabase();
    mockConn = MockConnectivityService();
    cache = OfflineCacheService(mockDb, mockConn);
  });

  // ────────────────────────────────────────────────────────────────────
  // _canCache guard: when isAvailable is false, all methods return empty/null
  // ────────────────────────────────────────────────────────────────────
  group('OfflineCacheService — platform unavailable (no-ops)', () {
    setUp(() {
      when(() => mockDb.isAvailable).thenReturn(false);
    });

    test('getCachedWords returns empty list', () async {
      expect(await cache.getCachedWords(), isEmpty);
    });

    test('getCachedWordsByCategory returns empty list', () async {
      expect(await cache.getCachedWordsByCategory('food'), isEmpty);
    });

    test('getCachedWordsPaginated returns empty list', () async {
      expect(
        await cache.getCachedWordsPaginated(limit: 10, offset: 0),
        isEmpty,
      );
    });

    test('searchCachedWords returns empty list', () async {
      expect(await cache.searchCachedWords('hello'), isEmpty);
    });

    test('getCachedCategories returns empty list', () async {
      expect(await cache.getCachedCategories(), isEmpty);
    });

    test('cachedWordCount returns 0', () async {
      expect(await cache.cachedWordCount(), 0);
    });

    test('getCachedDueWords returns empty list', () async {
      expect(await cache.getCachedDueWords('u1'), isEmpty);
    });

    test('getCachedProgress returns null', () async {
      expect(await cache.getCachedProgress('u1', 1), isNull);
    });

    test('countCachedDueWords returns 0', () async {
      expect(await cache.countCachedDueWords('u1'), 0);
    });

    test('getCachedStats returns empty list', () async {
      expect(
        await cache.getCachedStats(
          'u1',
          DateTime(2025, 1, 1),
          DateTime(2025, 12, 31),
        ),
        isEmpty,
      );
    });

    test('cacheWords is a no-op (no DB call)', () async {
      await cache.cacheWords([
        WordModel(
          id: 1,
          englishWord: 'hi',
          russianTranslation: 'привет',
          difficultyLevel: 1,
          category: 'basic',
          createdAt: DateTime(2025, 1, 1),
        ),
      ]);
      verifyNever(() => mockDb.upsertAll(any(), any()));
    });

    test('queueProgressUpdate is a no-op', () async {
      await cache.queueProgressUpdate(
        userId: 'u1',
        wordId: 1,
        data: {'ease_factor': 2.5},
      );
      verifyNever(() => mockDb.upsert(any(), any()));
    });

    test('queueStatIncrement is a no-op', () async {
      await cache.queueStatIncrement(
        userId: 'u1',
        field: 'xp_earned',
        amount: 10,
      );
      verifyNever(() => mockDb.addToSyncQueue(
            tableName: any(named: 'tableName'),
            operation: any(named: 'operation'),
            payload: any(named: 'payload'),
          ),);
    });
  });

  // ────────────────────────────────────────────────────────────────────
  // Normal operation — isAvailable is true, methods call LocalDatabase
  // ────────────────────────────────────────────────────────────────────
  group('OfflineCacheService — getCachedWords', () {
    setUp(() {
      when(() => mockDb.isAvailable).thenReturn(true);
    });

    test('returns parsed WordModels from DB rows', () async {
      when(() => mockDb.query('words', orderBy: 'english_word ASC'))
          .thenAnswer((_) async => [
                _wordRow(id: 1, englishWord: 'apple', russianTranslation: 'яблоко'),
                _wordRow(id: 2, englishWord: 'book', russianTranslation: 'книга'),
              ],);

      final words = await cache.getCachedWords();

      expect(words.length, 2);
      expect(words[0].englishWord, 'apple');
      expect(words[1].englishWord, 'book');
    });

    test('returns empty list when no rows', () async {
      when(() => mockDb.query('words', orderBy: 'english_word ASC'))
          .thenAnswer((_) async => []);

      expect(await cache.getCachedWords(), isEmpty);
    });
  });

  group('OfflineCacheService — getCachedWordsByCategory', () {
    setUp(() {
      when(() => mockDb.isAvailable).thenReturn(true);
    });

    test('passes correct where clause', () async {
      when(() => mockDb.query(
            'words',
            where: 'category = ?',
            whereArgs: ['food'],
            orderBy: 'english_word ASC',
          ),).thenAnswer((_) async => [
            _wordRow(id: 1, englishWord: 'apple', category: 'food'),
          ],);

      final words = await cache.getCachedWordsByCategory('food');

      expect(words.length, 1);
      expect(words[0].category, 'food');
    });
  });

  group('OfflineCacheService — getCachedDueWords', () {
    setUp(() {
      when(() => mockDb.isAvailable).thenReturn(true);
    });

    test('joins progress rows with word rows', () async {
      // Stub the progress query
      when(() => mockDb.query(
            'user_word_progress',
            where: any(named: 'where'),
            whereArgs: any(named: 'whereArgs'),
            orderBy: 'next_review_date ASC',
            limit: 20,
          ),).thenAnswer((_) async => [
            _progressRow(userId: 'u1', wordId: 5),
          ],);

      // Stub the word lookup
      when(() => mockDb.query(
            'words',
            where: 'id = ?',
            whereArgs: [5],
            limit: 1,
          ),).thenAnswer((_) async => [
            _wordRow(id: 5, englishWord: 'river'),
          ],);

      final due = await cache.getCachedDueWords('u1');

      expect(due.length, 1);
      expect(due.first['word_id'], 5);
      // The joined word data should be under the 'words' key
      expect(due.first['words'], isNotNull);
      expect(due.first['words']['english_word'], 'river');
    });

    test('skips progress rows with no matching word', () async {
      when(() => mockDb.query(
            'user_word_progress',
            where: any(named: 'where'),
            whereArgs: any(named: 'whereArgs'),
            orderBy: 'next_review_date ASC',
            limit: 20,
          ),).thenAnswer((_) async => [
            _progressRow(userId: 'u1', wordId: 99),
          ],);

      when(() => mockDb.query(
            'words',
            where: 'id = ?',
            whereArgs: [99],
            limit: 1,
          ),).thenAnswer((_) async => []);

      final due = await cache.getCachedDueWords('u1');
      expect(due, isEmpty);
    });
  });

  group('OfflineCacheService — getCachedProgress', () {
    setUp(() {
      when(() => mockDb.isAvailable).thenReturn(true);
    });

    test('returns UserWordProgressModel when found', () async {
      when(() => mockDb.query(
            'user_word_progress',
            where: 'user_id = ? AND word_id = ?',
            whereArgs: ['u1', 7],
            limit: 1,
          ),).thenAnswer((_) async => [_progressRow(userId: 'u1', wordId: 7)]);

      final progress = await cache.getCachedProgress('u1', 7);

      expect(progress, isNotNull);
      expect(progress!.wordId, 7);
    });

    test('returns null when no rows found', () async {
      when(() => mockDb.query(
            'user_word_progress',
            where: 'user_id = ? AND word_id = ?',
            whereArgs: ['u1', 42],
            limit: 1,
          ),).thenAnswer((_) async => []);

      expect(await cache.getCachedProgress('u1', 42), isNull);
    });
  });

  group('OfflineCacheService — getCachedStats', () {
    setUp(() {
      when(() => mockDb.isAvailable).thenReturn(true);
    });

    test('returns DailyStatsModel list for date range', () async {
      when(() => mockDb.query(
            'daily_stats',
            where: 'user_id = ? AND date >= ? AND date <= ?',
            whereArgs: ['u1', '2025-06-01', '2025-06-07'],
            orderBy: 'date DESC',
          ),).thenAnswer((_) async => [
            _statsRow(date: '2025-06-07', xpEarned: 80),
            _statsRow(id: 2, date: '2025-06-06', xpEarned: 60),
          ],);

      final stats = await cache.getCachedStats(
        'u1',
        DateTime(2025, 6, 1),
        DateTime(2025, 6, 7),
      );

      expect(stats.length, 2);
      expect(stats[0].xpEarned, 80);
      expect(stats[1].xpEarned, 60);
    });

    test('returns empty list for no data', () async {
      when(() => mockDb.query(
            'daily_stats',
            where: 'user_id = ? AND date >= ? AND date <= ?',
            whereArgs: any(named: 'whereArgs'),
            orderBy: 'date DESC',
          ),).thenAnswer((_) async => []);

      expect(
        await cache.getCachedStats('u1', DateTime(2025), DateTime(2025)),
        isEmpty,
      );
    });
  });

  group('OfflineCacheService — cacheWords', () {
    setUp(() {
      when(() => mockDb.isAvailable).thenReturn(true);
      when(() => mockDb.upsertAll(any(), any())).thenAnswer((_) async {});
    });

    test('converts WordModels to row maps and calls upsertAll', () async {
      final words = [
        WordModel(
          id: 1,
          englishWord: 'sun',
          russianTranslation: 'солнце',
          difficultyLevel: 1,
          category: 'nature',
          createdAt: DateTime(2025, 1, 15),
        ),
        WordModel(
          id: 2,
          englishWord: 'moon',
          russianTranslation: 'луна',
          difficultyLevel: 2,
          category: 'nature',
          createdAt: DateTime(2025, 1, 16),
        ),
      ];

      await cache.cacheWords(words);

      final captured =
          verify(() => mockDb.upsertAll('words', captureAny())).captured.single
              as List<Map<String, dynamic>>;

      expect(captured.length, 2);
      expect(captured[0]['english_word'], 'sun');
      expect(captured[0]['russian_translation'], 'солнце');
      expect(captured[1]['english_word'], 'moon');
      expect(captured[1]['id'], 2);
    });

    test('handles empty word list without error', () async {
      await cache.cacheWords([]);
      verify(() => mockDb.upsertAll('words', [])).called(1);
    });
  });

  group('OfflineCacheService — queueProgressUpdate', () {
    setUp(() {
      when(() => mockDb.isAvailable).thenReturn(true);
      when(() => mockDb.upsert(any(), any())).thenAnswer((_) async {});
      when(() => mockDb.addToSyncQueue(
            tableName: any(named: 'tableName'),
            operation: any(named: 'operation'),
            payload: any(named: 'payload'),
          ),).thenAnswer((_) async {});
    });

    test('saves locally via upsert and adds to sync queue', () async {
      await cache.queueProgressUpdate(
        userId: 'u1',
        wordId: 5,
        data: {'ease_factor': 2.6, 'interval_days': 3},
      );

      // Verify local upsert
      final upsertCall =
          verify(() => mockDb.upsert('user_word_progress', captureAny()))
              .captured
              .single as Map<String, dynamic>;
      expect(upsertCall['user_id'], 'u1');
      expect(upsertCall['word_id'], 5);
      expect(upsertCall['ease_factor'], 2.6);

      // Verify sync queue entry
      final syncCall = verify(() => mockDb.addToSyncQueue(
            tableName: 'user_word_progress',
            operation: 'upsert',
            payload: captureAny(named: 'payload'),
          ),).captured.single as String;

      final decoded = jsonDecode(syncCall) as Map<String, dynamic>;
      expect(decoded['user_id'], 'u1');
      expect(decoded['word_id'], 5);
      expect(decoded['ease_factor'], 2.6);
    });
  });

  group('OfflineCacheService — queueStatIncrement', () {
    setUp(() {
      when(() => mockDb.isAvailable).thenReturn(true);
      when(() => mockDb.addToSyncQueue(
            tableName: any(named: 'tableName'),
            operation: any(named: 'operation'),
            payload: any(named: 'payload'),
          ),).thenAnswer((_) async {});
    });

    test('adds stat increment to sync queue with correct payload', () async {
      await cache.queueStatIncrement(
        userId: 'u1',
        field: 'xp_earned',
        amount: 25,
      );

      final payload = verify(() => mockDb.addToSyncQueue(
            tableName: 'daily_stats',
            operation: 'upsert',
            payload: captureAny(named: 'payload'),
          ),).captured.single as String;

      final decoded = jsonDecode(payload) as Map<String, dynamic>;
      expect(decoded['user_id'], 'u1');
      expect(decoded['field'], 'xp_earned');
      expect(decoded['amount'], 25);
      expect(decoded['date'], isNotNull);
    });
  });

  group('OfflineCacheService — isOnline', () {
    test('delegates to ConnectivityService', () {
      when(() => mockConn.isOnline).thenReturn(true);
      expect(cache.isOnline, true);

      when(() => mockConn.isOnline).thenReturn(false);
      expect(cache.isOnline, false);
    });
  });
}
