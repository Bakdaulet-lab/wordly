import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/word_model.dart';
import '../utils/response_validator.dart';
import 'interfaces/i_word_service.dart';

/// Supabase data-access layer for the word catalogue.
class WordService implements IWordService {
  final SupabaseClient _client;

  WordService(this._client);

  @override
  Future<List<WordModel>> fetchAllWords() async {
    final response = await _client
        .from('words')
        .select()
        .order('english_word', ascending: true);
    final validated = ResponseValidator.validateAndMapList(
      response, WordModel.fromJson,
      context: 'fetchAllWords',
    );
    return validated.when(
      success: (words) => words,
      failure: (error) => throw error,
    );
  }

  /// Fetch a page of words with limit/offset for pagination.
  @override
  Future<List<WordModel>> fetchWords({required int limit, required int offset}) async {
    final response = await _client
        .from('words')
        .select()
        .order('id', ascending: true)
        .range(offset, offset + limit - 1);
    final validated = ResponseValidator.validateAndMapList(
      response, WordModel.fromJson,
      context: 'fetchWords',
    );
    return validated.when(
      success: (words) => words,
      failure: (error) => throw error,
    );
  }

  @override
  Future<List<WordModel>> fetchByCategory(String category) async {
    final response = await _client
        .from('words')
        .select()
        .eq('category', category)
        .order('english_word', ascending: true);
    final validated = ResponseValidator.validateAndMapList(
      response, WordModel.fromJson,
      context: 'fetchByCategory',
    );
    return validated.when(
      success: (words) => words,
      failure: (error) => throw error,
    );
  }

  @override
  Future<List<WordModel>> searchWords(String query) async {
    final response = await _client
        .from('words')
        .select()
        .ilike('english_word', '%$query%')
        .order('english_word', ascending: true)
        .limit(50);
    final validated = ResponseValidator.validateAndMapList(
      response, WordModel.fromJson,
      context: 'searchWords',
    );
    return validated.when(
      success: (words) => words,
      failure: (error) => throw error,
    );
  }

  @override
  Future<List<String>> fetchCategories() async {
    final response = await _client
        .from('words')
        .select('category')
        .order('category', ascending: true);
    final validated = ResponseValidator.validateList(
      response,
      context: 'fetchCategories',
    );
    return validated.when(
      success: (rows) {
        return rows
            .map((json) => json['category'] as String)
            .toSet()
            .toList();
      },
      failure: (error) => throw error,
    );
  }
}
