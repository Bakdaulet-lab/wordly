import '../services/logger_service.dart';
import '../models/word_model.dart';
import 'local_database.dart';

/// Dedicated SQLite cache for the word catalogue.
///
/// Provides instant reads from the local database so the app
/// can display words immediately (cache-first). Background
/// fetches from Supabase can then update the cache.
class WordCacheService {
  final LocalDatabase _localDb;

  WordCacheService(this._localDb);

  /// Whether cache operations are available on this platform.
  bool get isAvailable => _localDb.isAvailable;

  // ── Reads ──────────────────────────────────────────────────────────

  /// Get all cached words, sorted alphabetically.
  Future<List<WordModel>> getCachedWords() async {
    if (!isAvailable) return [];
    try {
      final rows = await _localDb.query('words', orderBy: 'english_word ASC');
      return rows.map((r) => WordModel.fromJson(_normalize(r))).toList();
    } catch (e) {
      AppLogger.error('getCachedWords failed: $e', tag: 'WordCacheService', error: e);
      return [];
    }
  }

  /// Get a paginated slice of cached words.
  Future<List<WordModel>> getCachedWordsPaginated({
    required int limit,
    required int offset,
  }) async {
    if (!isAvailable) return [];
    try {
      final db = await _localDb.database;
      final rows = await db.query(
        'words',
        orderBy: 'id ASC',
        limit: limit,
        offset: offset,
      );
      return rows.map((r) => WordModel.fromJson(_normalize(r))).toList();
    } catch (e) {
      AppLogger.error('getCachedWordsPaginated failed: $e', tag: 'WordCacheService', error: e);
      return [];
    }
  }

  /// Get distinct categories from cached words.
  Future<List<String>> getCachedCategories() async {
    if (!isAvailable) return [];
    try {
      final db = await _localDb.database;
      final rows = await db.rawQuery(
        'SELECT DISTINCT category FROM words ORDER BY category ASC',
      );
      return rows.map((r) => r['category'] as String).toList();
    } catch (e) {
      AppLogger.error('getCachedCategories failed: $e', tag: 'WordCacheService', error: e);
      return [];
    }
  }

  /// Number of words currently in the cache.
  Future<int> cachedWordCount() async {
    if (!isAvailable) return 0;
    try {
      final db = await _localDb.database;
      final result = await db.rawQuery('SELECT COUNT(*) as cnt FROM words');
      return result.first['cnt'] as int? ?? 0;
    } catch (e) {
      AppLogger.error('cachedWordCount failed: $e', tag: 'WordCacheService', error: e);
      return 0;
    }
  }

  // ── Writes ─────────────────────────────────────────────────────────

  /// Store a list of words in the cache (upsert).
  Future<void> cacheWords(List<WordModel> words) async {
    if (!isAvailable || words.isEmpty) return;
    try {
      final rows = words
          .map(
            (w) => {
              'id': w.id,
              'english_word': w.englishWord,
              'russian_translation': w.russianTranslation,
              'example_sentence': w.exampleSentence,
              'difficulty_level': w.difficultyLevel,
              'category': w.category,
              'created_at': w.createdAt.toIso8601String(),
            },
          )
          .toList();
      await _localDb.upsertAll('words', rows);
      AppLogger.debug('Cached ${words.length} words', tag: 'WordCacheService');
    } catch (e) {
      AppLogger.error('cacheWords failed: $e', tag: 'WordCacheService', error: e);
    }
  }

  // ── Sync metadata ──────────────────────────────────────────────────

  /// Store the timestamp of the last successful remote fetch.
  Future<void> setLastFetchTime(DateTime time) async {
    if (!isAvailable) return;
    try {
      await _localDb.setSyncMeta(
        'words_last_fetch',
        time.toIso8601String(),
      );
    } catch (e) {
      AppLogger.error('setLastFetchTime failed: $e', tag: 'WordCacheService', error: e);
    }
  }

  /// Retrieve the last fetch timestamp, or null if never fetched.
  Future<DateTime?> getLastFetchTime() async {
    if (!isAvailable) return null;
    try {
      final raw = await _localDb.getSyncMeta('words_last_fetch');
      return raw != null ? DateTime.tryParse(raw) : null;
    } catch (e) {
      AppLogger.error('getLastFetchTime failed: $e', tag: 'WordCacheService', error: e);
      return null;
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────

  Map<String, dynamic> _normalize(Map<String, dynamic> row) => {
        'id': row['id'],
        'english_word': row['english_word'],
        'russian_translation': row['russian_translation'],
        'example_sentence': row['example_sentence'],
        'difficulty_level': row['difficulty_level'],
        'category': row['category'],
        'created_at': row['created_at'],
      };
}
