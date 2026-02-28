import '../../models/word_model.dart';

/// Contract for vocabulary word data access.
abstract class IWordService {
  /// Fetch all words ordered alphabetically.
  Future<List<WordModel>> fetchAllWords();

  /// Fetch a paginated slice of words.
  Future<List<WordModel>> fetchWords({required int limit, required int offset});

  /// Fetch words filtered by [category].
  Future<List<WordModel>> fetchByCategory(String category);

  /// Full-text search on english_word.
  Future<List<WordModel>> searchWords(String query);

  /// Fetch distinct category names.
  Future<List<String>> fetchCategories();
}
