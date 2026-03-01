import 'dart:convert';
import '../services/logger_service.dart';
import '../models/word_model.dart';
import '../models/user_word_progress_model.dart';
import '../models/daily_stats_model.dart';
import 'local_database.dart';
import 'connectivity_service.dart';

/// Offline-first cache service.
///
/// Provides cached reads from SQLite when the device is offline,
/// and writes pending mutations to the sync queue for later push.
///
/// On web, all cache operations are no-ops since SQLite is unavailable.
class OfflineCacheService {
  final LocalDatabase _localDb;
  final ConnectivityService _connectivity;

  OfflineCacheService(this._localDb, this._connectivity);

  bool get isOnline => _connectivity.isOnline;

  /// Whether local caching is available on this platform.
  bool get _canCache => _localDb.isAvailable;

  // ── Words cache ────────────────────────────────────────────────────

  /// Get all cached words from SQLite.
  Future<List<WordModel>> getCachedWords() async {
    if (!_canCache) return [];
    final rows = await _localDb.query('words', orderBy: 'english_word ASC');
    return rows.map((r) => WordModel.fromJson(_normalizeWordRow(r))).toList();
  }

  /// Get cached words with pagination.
  Future<List<WordModel>> getCachedWordsPaginated({
    required int limit,
    required int offset,
  }) async {
    if (!_canCache) return [];
    final db = await _localDb.database;
    final rows = await db.query(
      'words',
      orderBy: 'id ASC',
      limit: limit,
      offset: offset,
    );
    return rows.map((r) => WordModel.fromJson(_normalizeWordRow(r))).toList();
  }

  /// Get cached words by category.
  Future<List<WordModel>> getCachedWordsByCategory(String category) async {
    if (!_canCache) return [];
    final rows = await _localDb.query(
      'words',
      where: 'category = ?',
      whereArgs: [category],
      orderBy: 'english_word ASC',
    );
    return rows.map((r) => WordModel.fromJson(_normalizeWordRow(r))).toList();
  }

  /// Search cached words.
  Future<List<WordModel>> searchCachedWords(String query) async {
    if (!_canCache) return [];
    final db = await _localDb.database;
    final rows = await db.query(
      'words',
      where: 'english_word LIKE ?',
      whereArgs: ['%$query%'],
      orderBy: 'english_word ASC',
      limit: 50,
    );
    return rows.map((r) => WordModel.fromJson(_normalizeWordRow(r))).toList();
  }

  /// Get distinct categories from cached words.
  Future<List<String>> getCachedCategories() async {
    if (!_canCache) return [];
    final db = await _localDb.database;
    final rows = await db.rawQuery(
      'SELECT DISTINCT category FROM words ORDER BY category ASC',
    );
    return rows.map((r) => r['category'] as String).toList();
  }

  /// Cache a list of words to SQLite.
  Future<void> cacheWords(List<WordModel> words) async {
    if (!_canCache) return;
    final rows = words
        .map((w) => {
              'id': w.id,
              'english_word': w.englishWord,
              'russian_translation': w.russianTranslation,
              'example_sentence': w.exampleSentence,
              'difficulty_level': w.difficultyLevel,
              'category': w.category,
              'created_at': w.createdAt.toIso8601String(),
            },)
        .toList();
    await _localDb.upsertAll('words', rows);
  }

  /// Count cached words.
  Future<int> cachedWordCount() async {
    if (!_canCache) return 0;
    final db = await _localDb.database;
    final result = await db.rawQuery('SELECT COUNT(*) as cnt FROM words');
    return result.first['cnt'] as int? ?? 0;
  }

  // ── Progress cache ─────────────────────────────────────────────────

  /// Get cached review items (due words with word data joined).
  Future<List<Map<String, dynamic>>> getCachedDueWords(String userId) async {
    if (!_canCache) return [];
    final today = DateTime.now().toIso8601String().split('T')[0];
    final rows = await _localDb.query(
      'user_word_progress',
      where: 'user_id = ? AND next_review_date <= ?',
      whereArgs: [userId, today],
      orderBy: 'next_review_date ASC',
      limit: 20,
    );

    final result = <Map<String, dynamic>>[];
    for (final row in rows) {
      final wordId = row['word_id'];
      final wordRows = await _localDb.query(
        'words',
        where: 'id = ?',
        whereArgs: [wordId],
        limit: 1,
      );
      if (wordRows.isNotEmpty) {
        result.add({
          ...row,
          'words': _normalizeWordRow(wordRows.first),
        });
      }
    }
    return result;
  }

  /// Get cached progress for a specific word.
  Future<UserWordProgressModel?> getCachedProgress(
    String userId,
    int wordId,
  ) async {
    if (!_canCache) return null;
    final rows = await _localDb.query(
      'user_word_progress',
      where: 'user_id = ? AND word_id = ?',
      whereArgs: [userId, wordId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return UserWordProgressModel.fromJson(rows.first);
  }

  /// Count cached due words.
  Future<int> countCachedDueWords(String userId) async {
    if (!_canCache) return 0;
    final today = DateTime.now().toIso8601String().split('T')[0];
    final db = await _localDb.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as cnt FROM user_word_progress '
      'WHERE user_id = ? AND next_review_date <= ?',
      [userId, today],
    );
    return result.first['cnt'] as int? ?? 0;
  }

  /// Queue a progress update for sync when back online.
  Future<void> queueProgressUpdate({
    required String userId,
    required int wordId,
    required Map<String, dynamic> data,
  }) async {
    if (!_canCache) return;
    // Save locally immediately
    await _localDb.upsert('user_word_progress', {
      ...data,
      'user_id': userId,
      'word_id': wordId,
    });

    // Queue for remote sync
    await _localDb.addToSyncQueue(
      tableName: 'user_word_progress',
      operation: 'upsert',
      payload: jsonEncode({...data, 'user_id': userId, 'word_id': wordId}),
    );
    AppLogger.debug('Queued progress update for word $wordId', tag: 'OfflineCache');
  }

  // ── Daily stats cache ──────────────────────────────────────────────

  /// Get cached daily stats for a date range.
  Future<List<DailyStatsModel>> getCachedStats(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    if (!_canCache) return [];
    final start = startDate.toIso8601String().split('T')[0];
    final end = endDate.toIso8601String().split('T')[0];
    final rows = await _localDb.query(
      'daily_stats',
      where: 'user_id = ? AND date >= ? AND date <= ?',
      whereArgs: [userId, start, end],
      orderBy: 'date DESC',
    );
    return rows.map((r) => DailyStatsModel.fromJson(r)).toList();
  }

  /// Queue a stat increment for sync.
  Future<void> queueStatIncrement({
    required String userId,
    required String field,
    required int amount,
  }) async {
    if (!_canCache) return;
    await _localDb.addToSyncQueue(
      tableName: 'daily_stats',
      operation: 'upsert',
      payload: jsonEncode({
        'user_id': userId,
        'field': field,
        'amount': amount,
        'date': DateTime.now().toIso8601String().split('T')[0],
      }),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────

  Map<String, dynamic> _normalizeWordRow(Map<String, dynamic> row) => {
        'id': row['id'],
        'english_word': row['english_word'],
        'russian_translation': row['russian_translation'],
        'example_sentence': row['example_sentence'],
        'difficulty_level': row['difficulty_level'],
        'category': row['category'],
        'created_at': row['created_at'],
      };
}
