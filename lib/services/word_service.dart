import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/word_model.dart';

class WordService {
  final SupabaseClient _client;

  WordService(this._client);

  Future<List<WordModel>> fetchAllWords() async {
    final response = await _client
        .from('words')
        .select()
        .order('english_word', ascending: true);
    return (response as List)
        .map((json) => WordModel.fromJson(json))
        .toList();
  }

  Future<List<WordModel>> fetchByCategory(String category) async {
    final response = await _client
        .from('words')
        .select()
        .eq('category', category)
        .order('english_word', ascending: true);
    return (response as List)
        .map((json) => WordModel.fromJson(json))
        .toList();
  }

  Future<List<WordModel>> searchWords(String query) async {
    final response = await _client
        .from('words')
        .select()
        .ilike('english_word', '%$query%')
        .order('english_word', ascending: true)
        .limit(50);
    return (response as List)
        .map((json) => WordModel.fromJson(json))
        .toList();
  }

  Future<List<String>> fetchCategories() async {
    final response = await _client
        .from('words')
        .select('category')
        .order('category', ascending: true);
    final categories = (response as List)
        .map((json) => json['category'] as String)
        .toSet()
        .toList();
    return categories;
  }
}
