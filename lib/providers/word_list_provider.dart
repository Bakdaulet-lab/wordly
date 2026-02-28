import 'package:flutter/material.dart';
import '../models/word_model.dart';
import '../services/word_service.dart';

class WordListProvider extends ChangeNotifier {
  final WordService _wordService = WordService();

  List<WordModel> _allWords = [];
  List<WordModel> _filteredWords = [];
  List<String> _categories = [];
  String? _selectedCategory;
  String _searchQuery = '';
  bool _isLoading = false;
  String? _errorMessage;

  List<WordModel> get words => _filteredWords;
  List<WordModel> get allWords => _allWords;
  List<String> get categories => _categories;
  String? get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadWords() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _allWords = await _wordService.fetchAllWords();
      _categories = await _wordService.fetchCategories();
      _applyFilters();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  void setCategory(String? category) {
    _selectedCategory = category;
    _applyFilters();
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFilters();
    notifyListeners();
  }

  void _applyFilters() {
    _filteredWords = _allWords.where((word) {
      final matchesCategory = _selectedCategory == null ||
          word.category == _selectedCategory;
      final matchesSearch = _searchQuery.isEmpty ||
          word.englishWord.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          word.russianTranslation.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
  }
}
