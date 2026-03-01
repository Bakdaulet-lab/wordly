import 'dart:async';
import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/logger_service.dart';
import 'connectivity_service.dart';
import 'local_database.dart';
import '../models/word_model.dart';
import '../models/profile_model.dart';
import '../models/daily_stats_model.dart';

/// Synchronisation service that bridges [LocalDatabase] ↔ Supabase.
///
/// On startup (or when the device comes back online) it:
/// 1. Pushes all pending mutations from the sync queue.
/// 2. Pulls latest data from Supabase into the local cache.
class SyncService {
  final LocalDatabase _localDb;
  final ConnectivityService _connectivity;
  final SupabaseClient _supabase;

  StreamSubscription<bool>? _connectivitySub;
  bool _isSyncing = false;

  final StreamController<SyncStatus> _statusController =
      StreamController<SyncStatus>.broadcast();
  Stream<SyncStatus> get statusStream => _statusController.stream;

  SyncService(this._localDb, this._connectivity, this._supabase);

  /// Start listening for connectivity changes and trigger sync.
  void start() {
    if (!_localDb.isAvailable) return; // No SQLite on web
    _connectivitySub = _connectivity.onlineStream.listen((isOnline) {
      if (isOnline) {
        syncNow();
      }
    });
  }

  /// Full sync cycle: push pending → pull latest.
  Future<void> syncNow() async {
    if (!_localDb.isAvailable) return; // No SQLite on web
    if (_isSyncing || !_connectivity.isOnline) return;
    _isSyncing = true;
    _statusController.add(SyncStatus.syncing);

    try {
      await _pushPending();
      await _pullAll();
      _statusController.add(SyncStatus.synced);
    } catch (e) {
      AppLogger.error('Sync error: $e', tag: 'SyncService', error: e);
      _statusController.add(SyncStatus.error);
    } finally {
      _isSyncing = false;
    }
  }

  // ── Push pending mutations ─────────────────────────────────────────

  Future<void> _pushPending() async {
    final items = await _localDb.getPendingSyncItems();
    for (final item in items) {
      try {
        final table = item['table_name'] as String;
        final op = item['operation'] as String;
        final payload =
            jsonDecode(item['payload'] as String) as Map<String, dynamic>;

        switch (op) {
          case 'upsert':
            await _supabase.from(table).upsert(payload);
          case 'insert':
            await _supabase.from(table).insert(payload);
          case 'update':
            final id = payload.remove('_pk_id');
            final pkField = payload.remove('_pk_field') ?? 'id';
            if (id != null) {
              await _supabase
                  .from(table)
                  .update(payload)
                  .eq(pkField as String, id);
            }
          case 'delete':
            final id = payload['id'];
            if (id != null) {
              await _supabase.from(table).delete().eq('id', id);
            }
        }

        await _localDb.removeSyncItem(item['id'] as int);
      } catch (e) {
        AppLogger.error('Push failed for item ${item['id']}: $e', tag: 'SyncService', error: e);
        final retryCount = item['retry_count'] as int? ?? 0;
        if (retryCount >= 5) {
          // Drop after 5 retries
          await _localDb.removeSyncItem(item['id'] as int);
        } else {
          await _localDb.incrementRetry(item['id'] as int);
        }
      }
    }
  }

  // ── Pull remote data into local cache ──────────────────────────────

  Future<void> _pullAll() async {
    await _pullWords();
    await _pullProfile();
    await _pullProgress();
    await _pullDailyStats();
    await _localDb.setSyncMeta(
        'last_sync', DateTime.now().toIso8601String(),);
  }

  Future<void> _pullWords() async {
    try {
      final response = await _supabase
          .from('words')
          .select()
          .order('english_word', ascending: true);
      final rows = (response as List)
          .map((j) => WordModel.fromJson(j))
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
    } catch (e) {
      AppLogger.error('Pull words failed: $e', tag: 'SyncService', error: e);
    }
  }

  Future<void> _pullProfile() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .limit(1);
      final list = response as List;
      if (list.isNotEmpty) {
        final profile = ProfileModel.fromJson(list.first);
        await _localDb.upsert('profiles', {
          'id': profile.id,
          'display_name': profile.displayName,
          'avatar_url': profile.avatarUrl,
          'level': profile.level,
          'total_xp': profile.totalXp,
          'current_streak': profile.currentStreak,
          'longest_streak': profile.longestStreak,
          'last_login_date':
              profile.lastLoginDate?.toIso8601String().split('T')[0],
          'created_at': profile.createdAt.toIso8601String(),
        });
      }
    } catch (e) {
      AppLogger.error('Pull profile failed: $e', tag: 'SyncService', error: e);
    }
  }

  Future<void> _pullProgress() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;
      final response = await _supabase
          .from('user_word_progress')
          .select()
          .eq('user_id', userId);
      final rows = (response as List).map((j) => <String, dynamic>{
            'id': j['id'],
            'user_id': j['user_id'],
            'word_id': j['word_id'],
            'ease_factor': j['ease_factor'],
            'interval_days': j['interval_days'],
            'repetition_count': j['repetition_count'],
            'next_review_date': j['next_review_date'],
            'last_review_date': j['last_review_date'],
            'correct_count': j['correct_count'],
            'incorrect_count': j['incorrect_count'],
          },).toList();
      await _localDb.upsertAll('user_word_progress', rows);
    } catch (e) {
      AppLogger.error('Pull progress failed: $e', tag: 'SyncService', error: e);
    }
  }

  Future<void> _pullDailyStats() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      // Pull last 60 days
      final sixtyDaysAgo =
          DateTime.now().subtract(const Duration(days: 60));
      final response = await _supabase
          .from('daily_stats')
          .select()
          .eq('user_id', userId)
          .gte('date', sixtyDaysAgo.toIso8601String().split('T')[0]);
      final rows = (response as List).map((j) {
        final model = DailyStatsModel.fromJson(j);
        return model.toJson()..['id'] = j['id'];
      }).toList();
      await _localDb.upsertAll('daily_stats', rows);
    } catch (e) {
      AppLogger.error('Pull daily_stats failed: $e', tag: 'SyncService', error: e);
    }
  }

  // ── Local cache readers (for offline) ──────────────────────────────

  Future<List<WordModel>> getCachedWords() async {
    final rows = await _localDb.query('words', orderBy: 'english_word ASC');
    return rows.map((r) => WordModel.fromJson(_toWordJson(r))).toList();
  }

  Future<ProfileModel?> getCachedProfile(String userId) async {
    final rows = await _localDb.query(
      'profiles',
      where: 'id = ?',
      whereArgs: [userId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return ProfileModel.fromJson(_toProfileJson(rows.first));
  }

  Future<List<Map<String, dynamic>>> getCachedDueWords(String userId) async {
    final today = DateTime.now().toIso8601String().split('T')[0];
    final rows = await _localDb.query(
      'user_word_progress',
      where: 'user_id = ? AND next_review_date <= ?',
      whereArgs: [userId, today],
      orderBy: 'next_review_date ASC',
      limit: 20,
    );

    // Join with words
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
          'words': _toWordJson(wordRows.first),
        });
      }
    }
    return result;
  }

  // ── JSON helpers (SQLite uses different types) ─────────────────────

  Map<String, dynamic> _toWordJson(Map<String, dynamic> row) => {
        'id': row['id'],
        'english_word': row['english_word'],
        'russian_translation': row['russian_translation'],
        'example_sentence': row['example_sentence'],
        'difficulty_level': row['difficulty_level'],
        'category': row['category'],
        'created_at': row['created_at'],
      };

  Map<String, dynamic> _toProfileJson(Map<String, dynamic> row) => {
        'id': row['id'],
        'display_name': row['display_name'],
        'avatar_url': row['avatar_url'],
        'level': row['level'],
        'total_xp': row['total_xp'],
        'current_streak': row['current_streak'],
        'longest_streak': row['longest_streak'],
        'last_login_date': row['last_login_date'],
        'created_at': row['created_at'],
      };

  /// Last sync timestamp, or null if never synced.
  Future<DateTime?> lastSyncTime() async {
    final raw = await _localDb.getSyncMeta('last_sync');
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }

  void dispose() {
    _connectivitySub?.cancel();
    _statusController.close();
  }
}

enum SyncStatus { synced, syncing, error, offline }
