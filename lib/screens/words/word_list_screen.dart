import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../constants/app_theme.dart';
import '../../models/word_model.dart';
import '../../providers/word_list_provider.dart';
import '../../utils/input_sanitizer.dart';

class WordListScreen extends StatefulWidget {
  const WordListScreen({super.key});

  @override
  State<WordListScreen> createState() => _WordListScreenState();
}

class _WordListScreenState extends State<WordListScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<WordListProvider>().loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Row(
              children: [
                const Text('Word Library', style: AppTextStyles.heading1),
                const Spacer(),
                _buildFavoritesToggle(),
                _buildSortButton(),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildSearchBar(),
          const SizedBox(height: 12),
          _buildCategoryChips(),
          const SizedBox(height: 12),
          Expanded(child: _buildWordList()),
        ],
      ),
    );
  }

  Widget _buildFavoritesToggle() {
    return Consumer<WordListProvider>(
      builder: (context, provider, child) {
        final isActive = provider.showFavoritesOnly;
        return IconButton(
          icon: Icon(
            isActive ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            color: isActive ? AppColors.errorRed : AppColors.textHint,
          ),
          tooltip: isActive ? 'Show all words' : 'Show favorites only',
          onPressed: () => provider.setShowFavoritesOnly(!isActive),
        );
      },
    );
  }

  Widget _buildSortButton() {
    return Consumer<WordListProvider>(
      builder: (context, provider, child) {
        return PopupMenuButton<WordSortOption>(
          icon: Icon(Icons.sort_rounded, color: AppTheme.textHint(context)),
          tooltip: 'Sort words',
          onSelected: (option) => provider.setSortOption(option),
          itemBuilder: (context) => [
            _sortMenuItem(WordSortOption.defaultOrder, 'Default', Icons.list_rounded, provider.sortOption),
            _sortMenuItem(WordSortOption.alphabetical, 'A \u2192 Z', Icons.sort_by_alpha_rounded, provider.sortOption),
            _sortMenuItem(WordSortOption.alphabeticalDesc, 'Z \u2192 A', Icons.sort_by_alpha_rounded, provider.sortOption),
            _sortMenuItem(WordSortOption.difficultyAsc, 'Easiest first', Icons.arrow_upward_rounded, provider.sortOption),
            _sortMenuItem(WordSortOption.difficultyDesc, 'Hardest first', Icons.arrow_downward_rounded, provider.sortOption),
          ],
        );
      },
    );
  }

  PopupMenuItem<WordSortOption> _sortMenuItem(
    WordSortOption option,
    String label,
    IconData icon,
    WordSortOption current,
  ) {
    final isSelected = current == option;
    return PopupMenuItem(
      value: option,
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: isSelected ? AppColors.primary : AppColors.textHint,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(
              color: isSelected ? AppColors.primary : AppColors.textPrimary,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          if (isSelected) ...[
            const Spacer(),
            const Icon(Icons.check_rounded, size: 18, color: AppColors.primary),
          ],
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ValueListenableBuilder<TextEditingValue>(
        valueListenable: _searchController,
        builder: (context, value, child) {
          return TextField(
            controller: _searchController,
            onChanged: (value) {
              final sanitized = InputSanitizer.sanitizeSearch(value);
              context.read<WordListProvider>().setSearchQuery(sanitized);
            },
            decoration: InputDecoration(
              hintText: 'Search words...',
              hintStyle: AppTextStyles.bodyMedium.copyWith(
                color: AppTheme.textHint(context),
              ),
              prefixIcon: Icon(Icons.search, color: AppTheme.textHint(context)),
              suffixIcon: value.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear, color: AppTheme.textHint(context)),
                      onPressed: () {
                        _searchController.clear();
                        context.read<WordListProvider>().setSearchQuery('');
                      },
                    )
                  : null,
              filled: true,
              fillColor: AppTheme.surface(context),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategoryChips() {
    return Consumer<WordListProvider>(
      builder: (context, wordListProvider, child) {
        final categories = wordListProvider.categories;
        final selectedCategory = wordListProvider.selectedCategory;

        return SizedBox(
          height: 40,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: categories.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                final isSelected = selectedCategory == null;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(
                      'All',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: isSelected ? Colors.white : AppTheme.textPrimary(context),
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (_) {
                      wordListProvider.setCategory(null);
                    },
                    backgroundColor: AppTheme.surface(context),
                    selectedColor: AppTheme.primary(context),
                    checkmarkColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                );
              }

              final category = categories[index - 1];
              final isSelected = selectedCategory == category;

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(
                    category,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: isSelected ? Colors.white : AppTheme.textPrimary(context),
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  selected: isSelected,
                  onSelected: (_) {
                    wordListProvider.setCategory(
                      isSelected ? null : category,
                    );
                  },
                  backgroundColor: AppTheme.surface(context),
                  selectedColor: AppTheme.primary(context),
                  checkmarkColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildWordList() {
    return Consumer<WordListProvider>(
      builder: (context, wordListProvider, child) {
        if (wordListProvider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        if (wordListProvider.errorMessage != null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 48,
                    color: AppColors.errorRed,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    wordListProvider.errorMessage!,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.errorRed,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => wordListProvider.loadWords(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        final words = wordListProvider.words;

        if (words.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.search_off_rounded,
                  size: 48,
                  color: AppColors.textHint,
                ),
                const SizedBox(height: 16),
                Text(
                  'No words found',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.textHint,
                  ),
                ),
              ],
            ),
          );
        }

        // Total items = words + optional loading indicator at the bottom
        final itemCount = words.length + (wordListProvider.hasMore ? 1 : 0);

        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () => wordListProvider.refreshWords(),
          child: ListView.builder(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            itemCount: itemCount,
            itemBuilder: (context, index) {
              // Loading / load-more indicator at the bottom
              if (index >= words.length) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: wordListProvider.isLoadingMore
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: AppTheme.primary(context).withValues(alpha: 0.6),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Loading more...',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppTheme.textHint(context),
                                ),
                              ),
                            ],
                          )
                        : Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: AppTheme.textHint(context),
                            size: 28,
                          ),
                  ),
                );
              }

              return _buildAnimatedWordCard(context, words[index], index);
            },
          ),
        );
      },
    );
  }

  Widget _buildAnimatedWordCard(BuildContext context, WordModel word, int index) {
    // Stagger delay capped at 8 items so late items don't wait too long
    final delay = Duration(milliseconds: 50 * (index % 8));

    return _buildWordCard(context, word)
        .animate()
        .fadeIn(duration: 350.ms, delay: delay, curve: Curves.easeOut)
        .slideY(begin: 0.08, end: 0, duration: 350.ms, delay: delay, curve: Curves.easeOut);
  }

  Widget _buildWordCard(BuildContext context, WordModel word) {
    final provider = context.read<WordListProvider>();
    final isFav = provider.isFavorite(word.id);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: AppTheme.card(context),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => context.push('/words/${word.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      word.englishWord,
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      word.russianTranslation,
                      style: AppTextStyles.bodyMedium,
                    ),
                  ],
                ),
              ),
              _buildDifficultyBadge(word.difficultyLevel),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => provider.toggleFavorite(word.id),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  transitionBuilder: (child, anim) =>
                      ScaleTransition(scale: anim, child: child),
                  child: Icon(
                    isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    key: ValueKey<bool>(isFav),
                    color: isFav ? AppColors.errorRed : AppColors.textHint,
                    size: 22,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDifficultyBadge(int level) {
    final labels = ['', 'Beginner', 'Easy', 'Medium', 'Hard', 'Expert'];
    final colors = [
      Colors.transparent,
      AppColors.difficultyBeginner,
      AppColors.difficultyEasy,
      AppColors.difficultyMedium,
      AppColors.difficultyHard,
      AppColors.difficultyExpert,
    ];

    final safeLevel = level.clamp(1, 5);
    final label = labels[safeLevel];
    final color = colors[safeLevel];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha:0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
