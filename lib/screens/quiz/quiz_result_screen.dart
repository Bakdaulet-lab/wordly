import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../providers/quiz_provider.dart';

class QuizResultScreen extends StatelessWidget {
  const QuizResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Consumer<QuizProvider>(
          builder: (context, quiz, child) {
            final score = quiz.score;
            final total = quiz.totalQuestions;
            final xpEarned = quiz.totalXpEarned;
            final mistakes = quiz.mistakes;
            final isPerfect = score == total && total > 0;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const SizedBox(height: 24),

                  // Result icon
                  Icon(
                    isPerfect
                        ? Icons.emoji_events_rounded
                        : score >= total / 2
                            ? Icons.celebration_rounded
                            : Icons.sentiment_neutral_rounded,
                    size: 80,
                    color: isPerfect
                        ? AppColors.xpGold
                        : score >= total / 2
                            ? AppColors.successGreen
                            : AppColors.streakOrange,
                  ),
                  const SizedBox(height: 16),

                  // Title
                  Text(
                    isPerfect
                        ? 'Perfect Score!'
                        : score >= total / 2
                            ? 'Great Job!'
                            : 'Keep Practicing!',
                    style: AppTextStyles.heading1.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Score display
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha:0.05),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          '$score/$total',
                          style: AppTextStyles.heading1.copyWith(
                            fontSize: 48,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Correct Answers',
                          style: AppTextStyles.bodyMedium,
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.xpGold.withValues(alpha:0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                color: AppColors.xpGold,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '+$xpEarned XP',
                                style: AppTextStyles.heading3.copyWith(
                                  color: AppColors.xpGold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Mistakes section
                  if (mistakes.isNotEmpty) ...[
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Words to Review',
                        style: AppTextStyles.heading3,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...mistakes.map((word) => Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.errorRed.withValues(alpha:0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.errorRed.withValues(alpha:0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.close_rounded,
                                color: AppColors.errorRed,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
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
                                    Text(
                                      word.russianTranslation,
                                      style: AppTextStyles.bodyMedium,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )),
                    const SizedBox(height: 24),
                  ],

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
                      child: const Text(
                        'Play Again',
                        style: AppTextStyles.button,
                      ),
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
                        style: AppTextStyles.button.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
