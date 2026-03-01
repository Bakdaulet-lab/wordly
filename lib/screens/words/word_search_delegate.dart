import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../constants/app_theme.dart';
import '../../models/word_model.dart';

/// A [SearchDelegate] that filters words by English word, Russian translation,
/// or category from the full word list.
class WordSearchDelegate extends SearchDelegate<WordModel?> {
  final List<WordModel> allWords;
  final Set<int> favoriteIds;

  WordSearchDelegate({
    required this.allWords,
    this.favoriteIds = const {},
  }) : super(
          searchFieldLabel: 'Search words...',
          searchFieldStyle: AppTextStyles.bodyMedium,
        );

  @override
  ThemeData appBarTheme(BuildContext context) {
    final theme = Theme.of(context);
    return theme.copyWith(
      appBarTheme: theme.appBarTheme.copyWith(
        backgroundColor: AppTheme.surface(context),
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: AppTextStyles.bodyMedium.copyWith(
          color: AppTheme.textHint(context),
        ),
        border: InputBorder.none,
      ),
    );
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          tooltip: 'Clear',
          onPressed: () {
            query = '';
            showSuggestions(context);
          },
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      tooltip: 'Back',
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildList(context, _filter());
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildList(context, _filter());
  }

  List<WordModel> _filter() {
    if (query.isEmpty) return allWords;
    final q = query.toLowerCase().trim();
    return allWords.where((w) {
      return w.englishWord.toLowerCase().contains(q) ||
          w.russianTranslation.toLowerCase().contains(q) ||
          w.category.toLowerCase().contains(q);
    }).toList();
  }

  Widget _buildList(BuildContext context, List<WordModel> results) {
    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off_rounded, size: 48, color: AppColors.textHint),
            const SizedBox(height: 16),
            Text(
              query.isEmpty ? 'Type to search words' : 'No words found',
              style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textHint),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: results.length,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemBuilder: (context, index) {
        final word = results[index];
        final isFav = favoriteIds.contains(word.id);
        return _WordSearchTile(
          word: word,
          isFavorite: isFav,
          queryText: query,
          onTap: () {
            close(context, word);
            context.push('/words/${word.id}');
          },
        );
      },
    );
  }
}

class _WordSearchTile extends StatelessWidget {
  final WordModel word;
  final bool isFavorite;
  final String queryText;
  final VoidCallback onTap;

  const _WordSearchTile({
    required this.word,
    required this.isFavorite,
    required this.queryText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final diffColors = [
      Colors.transparent,
      AppColors.difficultyBeginner,
      AppColors.difficultyEasy,
      AppColors.difficultyMedium,
      AppColors.difficultyHard,
      AppColors.difficultyExpert,
    ];
    final safeLevel = word.difficultyLevel.clamp(1, 5);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: AppTheme.card(context),
      elevation: 0.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        title: Text(
          word.englishWord,
          style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          word.russianTranslation,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppTheme.textSecondary(context),
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: diffColors[safeLevel].withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                word.category,
                style: AppTextStyles.caption.copyWith(
                  color: diffColors[safeLevel],
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            ),
            if (isFavorite) ...[
              const SizedBox(width: 6),
              const Icon(Icons.favorite_rounded, color: AppColors.errorRed, size: 18),
            ],
          ],
        ),
      ),
    );
  }
}
