import 'dart:async';

import 'package:flutter/material.dart';
import '../models/word_model.dart';
import '../di/service_locator.dart';
import '../repositories/word_repository.dart';

/// Sort modes for the word catalogue list.
enum WordSortOption { defaultOrder, alphabetical, alphabeticalDesc, difficultyAsc, difficultyDesc }

/// Manages the word catalogue with filtering, sorting, and favourites.
class WordListProvider extends ChangeNotifier {
  final WordRepository _wordRepo = sl<WordRepository>();

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

  // Pagination state
  static const int _pageSize = 20;
  int _currentOffset = 0;
  bool _hasMore = true;
  bool _isLoadingMore = false;

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
  bool get hasMore => _hasMore;
  bool get isLoadingMore => _isLoadingMore;

  bool isFavorite(int wordId) => _favoriteIds.contains(wordId);

  /// Load the first page of words (resets pagination).
  Future<void> loadWords() async {
    _isLoading = true;
    _errorMessage = null;
    _currentOffset = 0;
    _hasMore = true;
    _allWords = [];
    notifyListeners();

    final wordsResult = await _wordRepo.fetchWords(limit: _pageSize, offset: 0);
    final categoriesResult = await _wordRepo.fetchCategories();
    final favoritesResult = await _wordRepo.getFavorites();

    favoritesResult.when(
      success: (ids) => _favoriteIds = ids,
      failure: (error) => debugPrint('getFavorites failed: ${error.userMessage}'),
    );

    wordsResult.when(
      success: (words) {
        _allWords = words;
        _currentOffset = words.length;
        _hasMore = words.length >= _pageSize;
      },
      failure: (error) => _errorMessage = error.userMessage,
    );
    categoriesResult.when(
      success: (cats) => _categories = cats,
      failure: (error) => _errorMessage ??= error.userMessage,
    );

    _applyFilters();
    _isLoading = false;
    notifyListeners();
  }

  /// Load the next page of words (infinite scroll).
  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasMore) return;

    _isLoadingMore = true;
    notifyListeners();

    final result = await _wordRepo.fetchWords(limit: _pageSize, offset: _currentOffset);
    result.when(
      success: (words) {
        _allWords.addAll(words);
        _currentOffset += words.length;
        _hasMore = words.length >= _pageSize;
        _applyFilters();
      },
      failure: (_) {
        // Silently ignore load-more failures; user can scroll again.
      },
    );

    _isLoadingMore = false;
    notifyListeners();
  }

  /// Full refresh (pull-to-refresh): reloads from scratch.
  Future<void> refreshWords() async {
    _currentOffset = 0;
    _hasMore = true;
    _errorMessage = null;

    final wordsResult = await _wordRepo.fetchWords(limit: _pageSize, offset: 0);
    final categoriesResult = await _wordRepo.fetchCategories();
    final favoritesResult = await _wordRepo.getFavorites();

    favoritesResult.when(
      success: (ids) => _favoriteIds = ids,
      failure: (error) => debugPrint('getFavorites refresh failed: ${error.userMessage}'),
    );

    wordsResult.when(
      success: (words) {
        _allWords = words;
        _currentOffset = words.length;
        _hasMore = words.length >= _pageSize;
      },
      failure: (error) => _errorMessage = error.userMessage,
    );
    categoriesResult.when(
      success: (cats) => _categories = cats,
      failure: (error) => _errorMessage ??= error.userMessage,
    );

    _applyFilters();
    notifyListeners();
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
    final result = await _wordRepo.toggleFavorite(wordId);
    result.when(
      success: (_) {
        if (_favoriteIds.contains(wordId)) {
          _favoriteIds.remove(wordId);
        } else {
          _favoriteIds.add(wordId);
        }
        _applyFilters();
        notifyListeners();
      },
      failure: (error) => debugPrint('toggleFavorite failed: ${error.userMessage}'),
    );
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
