import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../constants/app_theme.dart';
import '../../models/word_model.dart';
import '../../providers/quiz_provider.dart';

/// Shows all questions from a completed quiz grouped into mistakes and correct
/// answers. Displays the word, user's answer, correct answer, and example sentence.
class QuizReviewScreen extends StatelessWidget {
  const QuizReviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background(context),
      appBar: AppBar(
        title: const Text('Quiz Review'),
        backgroundColor: AppTheme.surface(context),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: Consumer<QuizProvider>(
        builder: (context, quiz, child) {
          final mistakes = quiz.mistakes;
          final quizWords = quiz.quizWords;
          final correctWords = quizWords
              .where((w) => !mistakes.any((m) => m.id == w.id))
              .toList();

          if (quizWords.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.quiz_rounded, size: 64, color: AppColors.textHint),
                  const SizedBox(height: 16),
                  Text(
                    'No quiz data available',
                    style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textHint),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => context.go('/home'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Go Home'),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Summary header
                _buildSummaryHeader(context, quiz.score, quiz.totalQuestions)
                    .animate()
                    .fadeIn(duration: 400.ms)
                    .slideY(begin: 0.05, end: 0, duration: 400.ms),
                const SizedBox(height: 24),

                // Mistakes section
                if (mistakes.isNotEmpty) ...[
                  _buildSectionTitle(
                    context,
                    'Mistakes',
                    Icons.close_rounded,
                    AppColors.errorRed,
                    mistakes.length,
                  ),
                  const SizedBox(height: 12),
                  ...mistakes.asMap().entries.map((entry) =>
                      _buildReviewCard(context, entry.value, false, entry.key),),
                  const SizedBox(height: 24),
                ],

                // Correct answers section
                if (correctWords.isNotEmpty) ...[
                  _buildSectionTitle(
                    context,
                    'Correct Answers',
                    Icons.check_circle_rounded,
                    AppColors.successGreen,
                    correctWords.length,
                  ),
                  const SizedBox(height: 12),
                  ...correctWords.asMap().entries.map((entry) =>
                      _buildReviewCard(
                        context,
                        entry.value,
                        true,
                        entry.key + mistakes.length,
                      ),),
                ],

                const SizedBox(height: 32),

                // Action buttons
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => context.go('/quiz'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Play Again', style: AppTextStyles.button),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => context.go('/home'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Go Home',
                      style: AppTextStyles.button.copyWith(color: AppColors.primary),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryHeader(BuildContext context, int score, int total) {
    final accuracy = total > 0 ? (score / total * 100).toInt() : 0;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primary(context),
            AppTheme.primary(context).withValues(alpha: 0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            '$score / $total',
            style: AppTextStyles.heading1.copyWith(
              color: Colors.white,
              fontSize: 36,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$accuracy% accuracy',
            style: AppTextStyles.bodyMedium.copyWith(
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    int count,
  ) {
    return Row(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 8),
        Text(
          '$title ($count)',
          style: AppTextStyles.heading3.copyWith(color: color),
        ),
      ],
    );
  }

  Widget _buildReviewCard(
    BuildContext context,
    WordModel word,
    bool isCorrect,
    int index,
  ) {
    final delay = Duration(milliseconds: 50 * (index % 10));
    final borderColor =
        isCorrect ? AppColors.successGreen : AppColors.errorRed;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: borderColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // English word + status icon
          Row(
            children: [
              Expanded(
                child: Text(
                  word.englishWord,
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary(context),
                  ),
                ),
              ),
              Icon(
                isCorrect
                    ? Icons.check_circle_rounded
                    : Icons.cancel_rounded,
                color: borderColor,
                size: 22,
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Correct answer
          Row(
            children: [
              Text(
                'Answer: ',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppTheme.textSecondary(context),
                ),
              ),
              Text(
                word.russianTranslation,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.successGreen,
                ),
              ),
            ],
          ),

          // Example sentence
          if (word.exampleSentence != null &&
              word.exampleSentence!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.surface(context),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.format_quote_rounded,
                    size: 16,
                    color: AppTheme.textHint(context),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      word.exampleSentence!,
                      style: AppTextStyles.bodySmall.copyWith(
                        fontStyle: FontStyle.italic,
                        color: AppTheme.textSecondary(context),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 300.ms, delay: delay)
        .slideY(begin: 0.05, end: 0, duration: 300.ms, delay: delay);
  }
}
