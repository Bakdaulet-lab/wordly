import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../models/word_model.dart';
import '../../providers/word_list_provider.dart';
import '../../services/tts_service.dart';

class WordDetailScreen extends StatelessWidget {
  final int wordId;

  const WordDetailScreen({super.key, required this.wordId});

  @override
  Widget build(BuildContext context) {
    return Consumer<WordListProvider>(
      builder: (context, wordListProvider, child) {
        final word = _findWord(wordListProvider);

        if (word == null) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                onPressed: () => context.pop(),
              ),
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.search_off_rounded,
                    size: 64,
                    color: AppColors.textHint,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Word not found',
                    style: AppTextStyles.heading3.copyWith(
                      color: AppColors.textHint,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
              onPressed: () => context.pop(),
            ),
            title: Text(
              'Word Details',
              style: AppTextStyles.heading3,
            ),
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // English word large display
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha:0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        word.englishWord,
                        style: AppTextStyles.heading1.copyWith(
                          color: Colors.white,
                          fontSize: 32,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      IconButton(
                        onPressed: () => TtsService().speak(word.englishWord),
                        icon: const Icon(Icons.volume_up_rounded),
                        color: Colors.white.withValues(alpha: 0.9),
                        iconSize: 28,
                        tooltip: 'Listen',
                      ),
                      Text(
                        word.russianTranslation,
                        style: AppTextStyles.heading3.copyWith(
                          color: Colors.white.withValues(alpha:0.85),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Example sentence
                if (word.exampleSentence != null &&
                    word.exampleSentence!.isNotEmpty) ...[
                  _buildDetailSection(
                    icon: Icons.format_quote_rounded,
                    title: 'Example',
                    child: Text(
                      word.exampleSentence!,
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Difficulty level
                _buildDetailSection(
                  icon: Icons.signal_cellular_alt_rounded,
                  title: 'Difficulty',
                  child: _buildDifficultyIndicator(word.difficultyLevel),
                ),
                const SizedBox(height: 16),

                // Category
                _buildDetailSection(
                  icon: Icons.category_rounded,
                  title: 'Category',
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha:0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      word.category,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  WordModel? _findWord(WordListProvider provider) {
    try {
      return provider.allWords.firstWhere((w) => w.id == wordId);
    } catch (_) {
      return null;
    }
  }

  Widget _buildDetailSection({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildDifficultyIndicator(int level) {
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

    return Row(
      children: List.generate(5, (index) {
        final filled = index < safeLevel;
        return Expanded(
          child: Container(
            height: 8,
            margin: EdgeInsets.only(right: index < 4 ? 4 : 0),
            decoration: BoxDecoration(
              color: filled
                  ? colors[safeLevel]
                  : AppColors.textHint.withValues(alpha:0.2),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        );
      })
        ..add(
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Text(
                labels[safeLevel],
                style: AppTextStyles.bodyMedium.copyWith(
                  color: colors[safeLevel],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
    );
  }
}
