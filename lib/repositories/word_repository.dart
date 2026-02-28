import '../models/word_model.dart';
import '../services/word_service.dart';
import '../services/favorites_service.dart';
import '../utils/api_guard.dart';
import '../utils/result.dart';

/// Repository that combines word fetching and local favorites.
class WordRepository {
  final WordService _wordService;
  final FavoritesService _favoritesService;

  WordRepository(this._wordService, this._favoritesService);

  Future<Result<List<WordModel>>> fetchAllWords() {
    return apiGuard(() => _wordService.fetchAllWords());
  }

  Future<Result<List<WordModel>>> fetchByCategory(String category) {
    return apiGuard(() => _wordService.fetchByCategory(category));
  }

  Future<Result<List<WordModel>>> searchWords(String query) {
    return apiGuard(() => _wordService.searchWords(query));
  }

  Future<Result<List<String>>> fetchCategories() {
    return apiGuard(() => _wordService.fetchCategories());
  }

  Future<Set<int>> getFavorites() => _favoritesService.getFavorites();

  Future<void> toggleFavorite(int wordId) =>
      _favoritesService.toggleFavorite(wordId);

  Future<bool> isFavorite(int wordId) =>
      _favoritesService.isFavorite(wordId);
}
