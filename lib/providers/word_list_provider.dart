import 'dart:async';

import '../models/word_model.dart';
import '../di/service_locator.dart';
import '../repositories/word_repository.dart';
import '../services/word_cache_service.dart';
import '../services/logger_service.dart';
import 'base_provider.dart';

/// Sort modes for the word catalogue list.
enum WordSortOption { defaultOrder, alphabetical, alphabeticalDesc, difficultyAsc, difficultyDesc }

/// Manages the word catalogue with filtering, sorting, and favourites.
class WordListProvider extends BaseProvider {
  final WordRepository _wordRepo = sl<WordRepository>();
  final WordCacheService _wordCache = sl<WordCacheService>();

  List<WordModel> _allWords = [];
  List<WordModel> _filteredWords = [];
  List<String> _categories = [];
  String? _selectedCategory;
  String _searchQuery = '';
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
  WordSortOption get sortOption => _sortOption;
  Set<int> get favoriteIds => _favoriteIds;
  bool get showFavoritesOnly => _showFavoritesOnly;
  bool get hasMore => _hasMore;
  bool get isLoadingMore => _isLoadingMore;

  bool isFavorite(int wordId) => _favoriteIds.contains(wordId);

  /// Load the first page of words using a **cache-first** strategy.
  ///
  /// 1. Return cached data immediately so the UI is never blank.
  /// 2. Fetch the latest page from Supabase in the background.
  /// 3. Update the UI if the remote data differs from the cache.
  Future<void> loadWords() async {
    setLoading(true);
    clearError();
    _currentOffset = 0;
    _hasMore = true;
    _allWords = [];

    // ── Step 1: Show cached data immediately ─────────────────────────
    final cachedWords = await _wordCache.getCachedWordsPaginated(
      limit: _pageSize,
      offset: 0,
    );
    final cachedCategories = await _wordCache.getCachedCategories();

    if (cachedWords.isNotEmpty) {
      _allWords = cachedWords;
      _currentOffset = cachedWords.length;
      _hasMore = cachedWords.length >= _pageSize;
      _categories = cachedCategories;
      _applyFilters();
      setLoading(false);
    }

    // Load favorites (always try)
    final favoritesResult = await _wordRepo.getFavorites();
    favoritesResult.when(
      success: (ids) => _favoriteIds = ids,
      failure: (error) => AppLogger.warning('getFavorites failed: ${error.userMessage}', tag: 'WordListProvider'),
    );

    // ── Step 2: Fetch from Supabase in background ────────────────────
    final wordsResult = await _wordRepo.fetchWords(limit: _pageSize, offset: 0);
    final categoriesResult = await _wordRepo.fetchCategories();

    wordsResult.when(
      success: (words) {
        _allWords = words;
        _currentOffset = words.length;
        _hasMore = words.length >= _pageSize;
        // Update cache with fresh data
        _wordCache.cacheWords(words);
        _wordCache.setLastFetchTime(DateTime.now());
      },
      failure: (error) {
        // Only show an error if there was no cached data
        if (_allWords.isEmpty) {
          setError(error.userMessage, notify: false);
        }
      },
    );
    categoriesResult.when(
      success: (cats) => _categories = cats,
      failure: (error) {
        if (_categories.isEmpty) {
          if (errorMessage == null) setError(error.userMessage, notify: false);
        }
      },
    );

    // ── Step 3: Update UI if data changed ────────────────────────────
    _applyFilters();
    setLoading(false);
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

  /// Full refresh (pull-to-refresh): always fetches from Supabase
  /// and updates the cache.
  Future<void> refreshWords() async {
    _currentOffset = 0;
    _hasMore = true;
    clearError();

    final wordsResult = await _wordRepo.fetchWords(limit: _pageSize, offset: 0);
    final categoriesResult = await _wordRepo.fetchCategories();
    final favoritesResult = await _wordRepo.getFavorites();

    favoritesResult.when(
      success: (ids) => _favoriteIds = ids,
      failure: (error) => AppLogger.warning('getFavorites refresh failed: ${error.userMessage}', tag: 'WordListProvider'),
    );

    wordsResult.when(
      success: (words) {
        _allWords = words;
        _currentOffset = words.length;
        _hasMore = words.length >= _pageSize;
        // Update cache with fresh data
        _wordCache.cacheWords(words);
        _wordCache.setLastFetchTime(DateTime.now());
      },
      failure: (error) => setError(error.userMessage, notify: false),
    );
    categoriesResult.when(
      success: (cats) => _categories = cats,
      failure: (error) {
        if (errorMessage == null) setError(error.userMessage, notify: false);
      },
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
      failure: (error) => AppLogger.warning('toggleFavorite failed: ${error.userMessage}', tag: 'WordListProvider'),
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
            a.englishWord.toLowerCase().compareTo(b.englishWord.toLowerCase()),);
      case WordSortOption.alphabeticalDesc:
        _filteredWords.sort((a, b) =>
            b.englishWord.toLowerCase().compareTo(a.englishWord.toLowerCase()),);
      case WordSortOption.difficultyAsc:
        _filteredWords.sort((a, b) =>
            a.difficultyLevel.compareTo(b.difficultyLevel),);
      case WordSortOption.difficultyDesc:
        _filteredWords.sort((a, b) =>
            b.difficultyLevel.compareTo(a.difficultyLevel),);
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
