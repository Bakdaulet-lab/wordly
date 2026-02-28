import 'dart:async';

import 'package:flutter/material.dart';
import '../models/word_model.dart';
import '../services/word_service.dart';
import '../services/favorites_service.dart';
import '../utils/error_helpers.dart';

enum WordSortOption { defaultOrder, alphabetical, alphabeticalDesc, difficultyAsc, difficultyDesc }

class WordListProvider extends ChangeNotifier {
  final WordService _wordService = WordService();
  final FavoritesService _favoritesService = FavoritesService();

  List<WordModel> _allWords = [];
  List<WordModel> _filteredWords = [];
  List<String> _categories = [];
  String? _selectedCategory;
  String _searchQuery = '';
  bool _isLoading = false;
  String? _errorMessage;
  WordSortOption _sortOption = WordSortOption.defaultOrder;
  Timer? _debounceTimer;
  Set<int> _favoriteIds = {};
  bool _showFavoritesOnly = false;

  List<WordModel> get words => _filteredWords;
  List<WordModel> get allWords => _allWords;
  List<String> get categories => _categories;
  String? get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  WordSortOption get sortOption => _sortOption;
  Set<int> get favoriteIds => _favoriteIds;
  bool get showFavoritesOnly => _showFavoritesOnly;

  bool isFavorite(int wordId) => _favoriteIds.contains(wordId);

  Future<void> loadWords() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _allWords = await _wordService.fetchAllWords();
      _categories = await _wordService.fetchCategories();
      _favoriteIds = await _favoritesService.getFavorites();
      _applyFilters();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = friendlyError(e);
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
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _applyFilters();
      notifyListeners();
    });
  }

  void setSortOption(WordSortOption option) {
    _sortOption = option;
    _applyFilters();
    notifyListeners();
  }

  Future<void> toggleFavorite(int wordId) async {
    await _favoritesService.toggleFavorite(wordId);
    if (_favoriteIds.contains(wordId)) {
      _favoriteIds.remove(wordId);
    } else {
      _favoriteIds.add(wordId);
    }
    _applyFilters();
    notifyListeners();
  }

  void setShowFavoritesOnly(bool value) {
    _showFavoritesOnly = value;
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
      final matchesFavorite = !_showFavoritesOnly ||
          _favoriteIds.contains(word.id);
      return matchesCategory && matchesSearch && matchesFavorite;
    }).toList();

    switch (_sortOption) {
      case WordSortOption.alphabetical:
        _filteredWords.sort((a, b) =>
            a.englishWord.toLowerCase().compareTo(b.englishWord.toLowerCase()));
      case WordSortOption.alphabeticalDesc:
        _filteredWords.sort((a, b) =>
            b.englishWord.toLowerCase().compareTo(a.englishWord.toLowerCase()));
      case WordSortOption.difficultyAsc:
        _filteredWords.sort((a, b) =>
            a.difficultyLevel.compareTo(b.difficultyLevel));
      case WordSortOption.difficultyDesc:
        _filteredWords.sort((a, b) =>
            b.difficultyLevel.compareTo(a.difficultyLevel));
      case WordSortOption.defaultOrder:
        break;
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}
