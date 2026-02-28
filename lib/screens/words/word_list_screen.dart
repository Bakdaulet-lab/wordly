import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../models/word_model.dart';
import '../../providers/word_list_provider.dart';

class WordListScreen extends StatefulWidget {
  const WordListScreen({super.key});

  @override
  State<WordListScreen> createState() => _WordListScreenState();
}

class _WordListScreenState extends State<WordListScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Text('Word Library', style: AppTextStyles.heading1),
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

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          context.read<WordListProvider>().setSearchQuery(value);
        },
        decoration: InputDecoration(
          hintText: 'Search words...',
          hintStyle: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textHint,
          ),
          prefixIcon: const Icon(Icons.search, color: AppColors.textHint),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: AppColors.textHint),
                  onPressed: () {
                    _searchController.clear();
                    context.read<WordListProvider>().setSearchQuery('');
                  },
                )
              : null,
          filled: true,
          fillColor: AppColors.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
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
                        color: isSelected ? Colors.white : AppColors.textPrimary,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (_) {
                      wordListProvider.setCategory(null);
                    },
                    backgroundColor: AppColors.surface,
                    selectedColor: AppColors.primary,
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
                      color: isSelected ? Colors.white : AppColors.textPrimary,
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
                  backgroundColor: AppColors.surface,
                  selectedColor: AppColors.primary,
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

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          itemCount: words.length,
          itemBuilder: (context, index) {
            return _buildWordCard(context, words[index]);
          },
        );
      },
    );
  }

  Widget _buildWordCard(BuildContext context, WordModel word) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: AppColors.cardBackground,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => context.go('/words/${word.id}'),
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
