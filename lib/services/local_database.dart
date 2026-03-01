import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import '../services/logger_service.dart';

/// Local SQLite database for offline-first caching.
///
/// Mirrors the Supabase schema for words, user_word_progress,
/// daily_stats, and keeps a sync_queue for pending changes.
///
/// On web and desktop (without sqflite_common_ffi), SQLite is not
/// available — all operations gracefully no-op.
class LocalDatabase {
  static const String _dbName = 'wordly_offline.db';
  static const int _dbVersion = 1;

  Database? _db;
  bool _initFailed = false;

  /// Whether the local database is available on this platform.
  ///
  /// sqflite works natively on Android and iOS only.
  /// Desktop platforms need sqflite_common_ffi; web has no support.
  bool get isAvailable {
    if (kIsWeb || _initFailed) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  Future<Database> get database async {
    if (!isAvailable) {
      throw UnsupportedError('LocalDatabase is not available on this platform');
    }
    if (_db != null) return _db!;
    try {
      _db = await _open();
      return _db!;
    } catch (e) {
      _initFailed = true;
      AppLogger.error('Failed to open database: $e', tag: 'LocalDatabase', error: e);
      rethrow;
    }
  }

  Future<Database> _open() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, _dbName);

    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // ── Words cache ──────────────────────────────────────────────────
    await db.execute('''
      CREATE TABLE words (
        id INTEGER PRIMARY KEY,
        english_word TEXT NOT NULL,
        russian_translation TEXT NOT NULL,
        example_sentence TEXT,
        difficulty_level INTEGER NOT NULL DEFAULT 1,
        category TEXT NOT NULL DEFAULT 'general',
        created_at TEXT NOT NULL
      )
    ''');

    // ── User word progress ───────────────────────────────────────────
    await db.execute('''
      CREATE TABLE user_word_progress (
        id INTEGER PRIMARY KEY,
        user_id TEXT NOT NULL,
        word_id INTEGER NOT NULL,
        ease_factor REAL NOT NULL DEFAULT 2.5,
        interval_days INTEGER NOT NULL DEFAULT 0,
        repetition_count INTEGER NOT NULL DEFAULT 0,
        next_review_date TEXT NOT NULL,
        last_review_date TEXT,
        correct_count INTEGER NOT NULL DEFAULT 0,
        incorrect_count INTEGER NOT NULL DEFAULT 0,
        UNIQUE(user_id, word_id)
      )
    ''');

    // ── Daily stats ──────────────────────────────────────────────────
    await db.execute('''
      CREATE TABLE daily_stats (
        id INTEGER PRIMARY KEY,
        user_id TEXT NOT NULL,
        date TEXT NOT NULL,
        words_learned INTEGER NOT NULL DEFAULT 0,
        words_reviewed INTEGER NOT NULL DEFAULT 0,
        correct_answers INTEGER NOT NULL DEFAULT 0,
        incorrect_answers INTEGER NOT NULL DEFAULT 0,
        xp_earned INTEGER NOT NULL DEFAULT 0,
        session_duration_seconds INTEGER NOT NULL DEFAULT 0,
        UNIQUE(user_id, date)
      )
    ''');

    // ── Profiles cache ───────────────────────────────────────────────
    await db.execute('''
      CREATE TABLE profiles (
        id TEXT PRIMARY KEY,
        display_name TEXT NOT NULL DEFAULT '',
        avatar_url TEXT,
        level INTEGER NOT NULL DEFAULT 1,
        total_xp INTEGER NOT NULL DEFAULT 0,
        current_streak INTEGER NOT NULL DEFAULT 0,
        longest_streak INTEGER NOT NULL DEFAULT 0,
        last_login_date TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    // ── Sync queue (pending mutations) ───────────────────────────────
    await db.execute('''
      CREATE TABLE sync_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        table_name TEXT NOT NULL,
        operation TEXT NOT NULL,
        payload TEXT NOT NULL,
        created_at TEXT NOT NULL,
        retry_count INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // ── Sync metadata ────────────────────────────────────────────────
    await db.execute('''
      CREATE TABLE sync_meta (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
  }

  // ── Generic CRUD ───────────────────────────────────────────────────

  Future<void> upsertAll(String table, List<Map<String, dynamic>> rows) async {
    final db = await database;
    final batch = db.batch();
    for (final row in rows) {
      batch.insert(table, row, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<void> upsert(String table, Map<String, dynamic> row) async {
    final db = await database;
    await db.insert(table, row, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> query(
    String table, {
    String? where,
    List<Object?>? whereArgs,
    String? orderBy,
    int? limit,
  }) async {
    final db = await database;
    return db.query(
      table,
      where: where,
      whereArgs: whereArgs,
      orderBy: orderBy,
      limit: limit,
    );
  }

  Future<void> delete(String table, {String? where, List<Object?>? whereArgs}) async {
    final db = await database;
    await db.delete(table, where: where, whereArgs: whereArgs);
  }

  // ── Sync queue ─────────────────────────────────────────────────────

  Future<void> addToSyncQueue({
    required String tableName,
    required String operation,
    required String payload,
  }) async {
    final db = await database;
    await db.insert('sync_queue', {
      'table_name': tableName,
      'operation': operation,
      'payload': payload,
      'created_at': DateTime.now().toIso8601String(),
      'retry_count': 0,
    });
  }

  Future<List<Map<String, dynamic>>> getPendingSyncItems() async {
    final db = await database;
    return db.query('sync_queue', orderBy: 'id ASC', limit: 50);
  }

  Future<void> removeSyncItem(int id) async {
    final db = await database;
    await db.delete('sync_queue', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> incrementRetry(int id) async {
    final db = await database;
    await db.rawUpdate(
      'UPDATE sync_queue SET retry_count = retry_count + 1 WHERE id = ?',
      [id],
    );
  }

  Future<int> pendingSyncCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as cnt FROM sync_queue');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // ── Sync metadata ─────────────────────────────────────────────────

  Future<void> setSyncMeta(String key, String value) async {
    final db = await database;
    await db.insert(
      'sync_meta',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> getSyncMeta(String key) async {
    final db = await database;
    final result = await db.query(
      'sync_meta',
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (result.isEmpty) return null;
    return result.first['value'] as String?;
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
