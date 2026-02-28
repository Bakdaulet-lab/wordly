import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../constants/app_constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/quiz_provider.dart';
import '../../providers/word_list_provider.dart';
import '../../providers/achievement_provider.dart';
import '../../providers/profile_provider.dart';
import '../../models/achievement_model.dart';
import '../../services/xp_service.dart';
import '../../services/stats_service.dart';
import '../../services/progress_service.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  bool _initialized = false;
  bool _isAdvancing = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _startQuiz();
    }
  }

  void _startQuiz() {
    final allWords = context.read<WordListProvider>().allWords;
    if (allWords.isEmpty) {
      // Words not loaded yet, attempt to load them first
      return;
    }
    context.read<QuizProvider>().startQuiz(allWords);
  }

  Future<void> _handleAnswer(int optionIndex) async {
    if (_isAdvancing) return;

    final userId = context.read<AuthProvider>().user?.id;
    if (userId == null) return;

    final quizProvider = context.read<QuizProvider>();
    await quizProvider.selectAnswer(optionIndex, userId);

    // Prevent double-taps during the visual feedback delay
    _isAdvancing = true;

    await Future.delayed(
      const Duration(milliseconds: AppConstants.quizAutoAdvanceDelayMs),
    );

    if (!mounted) return;

    _isAdvancing = false;
    _advanceOrFinish(quizProvider, userId);
  }

  Future<void> _handleTimeout() async {
    if (_isAdvancing) return;
    _isAdvancing = true;

    // Brief pause to show "Time's Up!" state
    await Future.delayed(
      const Duration(milliseconds: AppConstants.quizAutoAdvanceDelayMs),
    );

    if (!mounted) return;

    _isAdvancing = false;
    final userId = context.read<AuthProvider>().user?.id;
    if (userId == null) return;

    final quizProvider = context.read<QuizProvider>();

    // Fire background network calls for the timed-out answer
    final wordId = quizProvider.currentWord?.id;
    if (wordId != null) {
      unawaited(Future.wait([
        XpService().awardXp(userId, AppConstants.xpIncorrectAnswer),
        StatsService().incrementStat(userId, 'incorrect_answers', 1),
        ProgressService().updateProgress(
          userId: userId,
          wordId: wordId,
          quality: AppConstants.qualityWrong,
        ),
      ]));
    }

    _advanceOrFinish(quizProvider, userId);
  }

  void _advanceOrFinish(QuizProvider quizProvider, String userId) {
    quizProvider.nextQuestion();

    if (quizProvider.isQuizComplete) {
      quizProvider.finishQuiz(userId).then((_) {
        if (mounted) {
          _checkAchievements(userId, quizProvider);
          context.go('/quiz-result');
        }
      });
    }
  }

  void _checkAchievements(String userId, QuizProvider quizProvider) {
    final achievementProvider = context.read<AchievementProvider>();
    final profileProvider = context.read<ProfileProvider>();

    // Refresh profile to get latest XP
    profileProvider.refreshProfile(userId);

    // Check XP-based achievements
    achievementProvider
        .checkAndUnlock(
          userId: userId,
          conditionType: 'total_xp',
          currentValue: profileProvider.totalXp + quizProvider.totalXpEarned,
        )
        .then((a) => _showAchievementSnackBar(a));

    // Check perfect quiz achievement
    if (quizProvider.score == quizProvider.totalQuestions &&
        quizProvider.totalQuestions > 0) {
      achievementProvider
          .checkAndUnlock(
            userId: userId,
            conditionType: 'perfect_quiz',
            currentValue: 1,
          )
          .then((a) => _showAchievementSnackBar(a));
    }

    // Check words_learned / words_reviewed achievements
    achievementProvider
        .checkAndUnlock(
          userId: userId,
          conditionType: 'words_learned',
          currentValue: quizProvider.totalQuestions,
        )
        .then((a) => _showAchievementSnackBar(a));
  }

  void _showAchievementSnackBar(AchievementModel? achievement) {
    if (achievement == null || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.emoji_events_rounded,
                color: AppColors.xpGold, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Achievement Unlocked!',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  Text(
                    achievement.name,
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.primary,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.textPrimary),
          onPressed: () => context.go('/home'),
        ),
        title: Consumer<QuizProvider>(
          builder: (context, quiz, child) {
            if (quiz.totalQuestions == 0) return const SizedBox.shrink();
            return Text(
              'Question ${quiz.currentIndex + 1} of ${quiz.totalQuestions}',
              style: AppTextStyles.heading3,
            );
          },
        ),
        centerTitle: true,
        actions: [
          Consumer<QuizProvider>(
            builder: (context, quiz, child) {
              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
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
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${quiz.score}',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.xpGold,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<QuizProvider>(
        builder: (context, quiz, child) {
          final allWords = context.read<WordListProvider>().allWords;

          if (allWords.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.warning_rounded,
                      size: 64,
                      color: AppColors.textHint,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No words available for the quiz.\nPlease check the word library first.',
                      style: AppTextStyles.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => context.go('/home'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Go Home'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (quiz.currentWord == null) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Progress bar + timer row
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: quiz.totalQuestions > 0
                                ? (quiz.currentIndex + 1) / quiz.totalQuestions
                                : 0,
                            backgroundColor: AppColors.textHint.withValues(alpha:0.2),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              AppColors.primary,
                            ),
                            minHeight: 6,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      _buildTimerBadge(quiz.timeRemaining, quiz.timedOut),
                    ],
                  ),
                  const SizedBox(height: 48),

                  // Current word
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 40,
                      horizontal: 24,
                    ),
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
                          'What is the translation of:',
                          style: AppTextStyles.bodyMedium,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          quiz.currentWord!.englishWord,
                          style: AppTextStyles.heading1.copyWith(
                            fontSize: 32,
                            color: AppColors.primary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Option buttons
                  Expanded(
                    child: ListView.builder(
                      itemCount: quiz.currentOptions.length,
                      itemBuilder: (context, index) {
                        final option = quiz.currentOptions[index];
                        return _buildOptionButton(
                          context,
                          option: option,
                          index: index,
                          isAnswered: quiz.isAnswered,
                          selectedIndex: quiz.selectedOptionIndex,
                          timedOut: quiz.timedOut,
                        );
                      },
                    ),
                  ),

                  // Handle timeout auto-advance
                  if (quiz.timedOut && !_isAdvancing)
                    Builder(builder: (context) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _handleTimeout();
                      });
                      return const SizedBox.shrink();
                    }),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTimerBadge(int seconds, bool timedOut) {
    final isLow = seconds <= 5;
    final color = timedOut
        ? AppColors.errorRed
        : isLow
            ? AppColors.streakOrange
            : AppColors.textSecondary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer_rounded, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            timedOut ? '0s' : '${seconds}s',
            style: AppTextStyles.bodySmall.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionButton(
    BuildContext context, {
    required dynamic option,
    required int index,
    required bool isAnswered,
    required int? selectedIndex,
    required bool timedOut,
  }) {
    Color backgroundColor = AppColors.cardBackground;
    Color borderColor = AppColors.textHint.withValues(alpha:0.2);
    Color textColor = AppColors.textPrimary;

    if (isAnswered) {
      if (option.isCorrect) {
        backgroundColor = AppColors.successGreen.withValues(alpha:0.1);
        borderColor = AppColors.successGreen;
        textColor = AppColors.successGreen;
      } else if (selectedIndex == index && !option.isCorrect) {
        backgroundColor = AppColors.errorRed.withValues(alpha:0.1);
        borderColor = AppColors.errorRed;
        textColor = AppColors.errorRed;
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: isAnswered ? null : () => _handleAnswer(index),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha:0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  option.text,
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (isAnswered && option.isCorrect)
                const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.successGreen,
                  size: 24,
                ),
              if (isAnswered && selectedIndex == index && !option.isCorrect)
                const Icon(
                  Icons.cancel_rounded,
                  color: AppColors.errorRed,
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
