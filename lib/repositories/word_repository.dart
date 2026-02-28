import 'package:flutter/foundation.dart';
import '../models/word_model.dart';
import '../services/word_service.dart';
import '../services/favorites_service.dart';
import '../services/offline_cache_service.dart';
import '../di/service_locator.dart';
import '../utils/api_guard.dart';
import '../utils/result.dart';
import '../utils/retry.dart';

/// Repository that combines word fetching, local favorites, and offline cache.
class WordRepository {
  final WordService _wordService;
  final FavoritesService _favoritesService;

  WordRepository(this._wordService, this._favoritesService);

  OfflineCacheService get _cache => sl<OfflineCacheService>();

  /// Fetch all words — falls back to offline cache on network failure.
  Future<Result<List<WordModel>>> fetchAllWords() async {
    final result = await apiGuardWithRetry(() => _wordService.fetchAllWords());
    return result.when(
      success: (words) async {
        // Cache for offline use (non-critical, do not propagate errors)
        try {
          await _cache.cacheWords(words);
        } catch (e) {
          debugPrint('[WordRepo] Cache failed (non-fatal): $e');
        }
        return Result.success(words);
      },
      failure: (error) async {
        if (error.type == AppExceptionType.network ||
            error.type == AppExceptionType.timeout) {
          debugPrint('[WordRepo] Falling back to offline cache');
          final cached = await _cache.getCachedWords();
          if (cached.isNotEmpty) return Result.success(cached);
        }
        return Result.failure(error);
      },
    );
  }

  /// Fetch a page of words — falls back to offline cache on failure.
  Future<Result<List<WordModel>>> fetchWords({
    required int limit,
    required int offset,
  }) async {
    final result = await apiGuardWithRetry(
        () => _wordService.fetchWords(limit: limit, offset: offset),);
    return result.when(
      success: (words) async {
        try {
          await _cache.cacheWords(words);
        } catch (e) {
          debugPrint('[WordRepo] Cache failed (non-fatal): $e');
        }
        return Result.success(words);
      },
      failure: (error) async {
        if (error.type == AppExceptionType.network ||
            error.type == AppExceptionType.timeout) {
          final cached = await _cache.getCachedWordsPaginated(
              limit: limit, offset: offset,);
          if (cached.isNotEmpty) return Result.success(cached);
        }
        return Result.failure(error);
      },
    );
  }

  /// Fetch by category — falls back to offline cache.
  Future<Result<List<WordModel>>> fetchByCategory(String category) async {
    final result =
        await apiGuardWithRetry(() => _wordService.fetchByCategory(category));
    return result.when(
      success: (words) => Result.success(words),
      failure: (error) async {
        if (error.type == AppExceptionType.network ||
            error.type == AppExceptionType.timeout) {
          final cached = await _cache.getCachedWordsByCategory(category);
          if (cached.isNotEmpty) return Result.success(cached);
        }
        return Result.failure(error);
      },
    );
  }

  /// Search words — falls back to offline cache.
  Future<Result<List<WordModel>>> searchWords(String query) async {
    final result =
        await apiGuardWithRetry(() => _wordService.searchWords(query));
    return result.when(
      success: (words) => Result.success(words),
      failure: (error) async {
        if (error.type == AppExceptionType.network ||
            error.type == AppExceptionType.timeout) {
          final cached = await _cache.searchCachedWords(query);
          if (cached.isNotEmpty) return Result.success(cached);
        }
        return Result.failure(error);
      },
    );
  }

  /// Fetch categories — falls back to offline cache.
  Future<Result<List<String>>> fetchCategories() async {
    final result =
        await apiGuardWithRetry(() => _wordService.fetchCategories());
    return result.when(
      success: (cats) => Result.success(cats),
      failure: (error) async {
        if (error.type == AppExceptionType.network ||
            error.type == AppExceptionType.timeout) {
          final cached = await _cache.getCachedCategories();
          if (cached.isNotEmpty) return Result.success(cached);
        }
        return Result.failure(error);
      },
    );
  }

  Future<Result<Set<int>>> getFavorites() {
    return apiGuard(() => _favoritesService.getFavorites());
  }

  Future<Result<void>> toggleFavorite(int wordId) {
    return apiGuard(() => _favoritesService.toggleFavorite(wordId));
  }

  Future<Result<bool>> isFavorite(int wordId) {
    return apiGuard(() => _favoritesService.isFavorite(wordId));
  }
}
