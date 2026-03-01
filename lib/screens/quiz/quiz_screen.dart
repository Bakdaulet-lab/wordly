import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../constants/app_theme.dart';
import '../../constants/app_constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/quiz_provider.dart';
import '../../providers/word_list_provider.dart';
import '../../providers/achievement_provider.dart';
import '../../providers/profile_provider.dart';
import '../../models/achievement_model.dart';
import '../../di/service_locator.dart';
import '../../repositories/quiz_repository.dart';
import '../../services/tts_service.dart';
import '../../utils/debouncer.dart';
import '../../providers/theme_provider.dart';
import '../../utils/levenshtein_distance.dart';
import '../../widgets/typing_answer_field.dart';
import '../../widgets/confetti_overlay.dart';
import '../../services/logger_service.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  bool _initialized = false;
  bool _isAdvancing = false;
  final _answerDebouncer = Debouncer(delay: const Duration(milliseconds: 600));

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
    final userId = context.read<AuthProvider>().user?.id;
    // Defer to avoid notifyListeners during build phase
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<QuizProvider>().startQuiz(allWords, userId: userId);
    });
  }

  @override
  void dispose() {
    _answerDebouncer.dispose();
    super.dispose();
  }

  bool _typingAnswerCorrect = false;
  bool _typingAnswered = false;

  Future<void> _handleTypingAnswer(String answer) async {
    if (_isAdvancing || _typingAnswered) return;

    final quizProvider = context.read<QuizProvider>();
    final currentWord = quizProvider.currentWord;
    if (currentWord == null) return;

    final userId = context.read<AuthProvider>().user?.id;
    if (userId == null) return;

    HapticFeedback.lightImpact();

    final isCorrect = isTypingAnswerAccepted(
      answer,
      currentWord.russianTranslation,
    );

    setState(() {
      _typingAnswerCorrect = isCorrect;
      _typingAnswered = true;
    });

    await quizProvider.selectAnswer(
      isCorrect ? quizProvider.currentOptions.indexWhere((o) => o.isCorrect) : 0,
      userId,
      overrideCorrect: isCorrect,
    );

    _isAdvancing = true;
    await Future.delayed(
      const Duration(milliseconds: AppConstants.quizAutoAdvanceDelayMs + 400),
    );
    if (!mounted) return;

    _isAdvancing = false;
    setState(() => _typingAnswered = false);
    _advanceOrFinish(quizProvider, userId);
  }

  Future<void> _handleAnswer(int optionIndex) async {
    if (_isAdvancing) return;
    if (!_answerDebouncer.runImmediate(() {})) return; // debounce rapid taps

    final userId = context.read<AuthProvider>().user?.id;
    if (userId == null) return;

    final quizProvider = context.read<QuizProvider>();
    await quizProvider.selectAnswer(optionIndex, userId);

    // Differentiate haptic feedback based on answer correctness
    final option = quizProvider.currentOptions[optionIndex];
    if (option.isCorrect) {
      HapticFeedback.lightImpact();
    } else {
      HapticFeedback.heavyImpact();
    }

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
      unawaited(sl<QuizRepository>()
          .submitAnswer(userId: userId, wordId: wordId, isCorrect: false)
          .then((result) {
        result.when(
          success: (_) {},
          failure: (error) => AppLogger.warning('timeout submitAnswer failed: ${error.userMessage}', tag: 'QuizScreen'),
        );
      }),);
    }

    _advanceOrFinish(quizProvider, userId);
  }

  void _advanceOrFinish(QuizProvider quizProvider, String userId) {
    quizProvider.nextQuestion();

    if (quizProvider.isQuizComplete) {
      quizProvider.finishQuiz(userId).then((_) async {
        if (mounted) {
          await _checkAchievements(userId, quizProvider);
          if (mounted) context.go('/quiz-result');
        }
      });
    }
  }

  Future<void> _checkAchievements(String userId, QuizProvider quizProvider) async {
    final achievementProvider = context.read<AchievementProvider>();
    final profileProvider = context.read<ProfileProvider>();

    // Capture old level before refresh to detect level-up
    final oldLevel = profileProvider.level;

    // Await profile refresh to get latest XP (avoids stale data)
    await profileProvider.refreshProfile(userId);

    final newLevel = profileProvider.level;

    // Fire confetti on level-up
    if (newLevel > oldLevel && mounted) {
      ConfettiOverlay.maybeOf(context)?.play();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.arrow_upward_rounded, color: AppColors.xpGold, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Level Up!', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    Text('You reached Level $newLevel!', style: const TextStyle(color: Colors.white70)),
                  ],
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.xpGold,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }

    // Check XP-based achievements
    final a1 = await achievementProvider
        .checkAndUnlock(
          userId: userId,
          conditionType: 'total_xp',
          currentValue: profileProvider.totalXp,
        );
    _showAchievementSnackBar(a1);

    // Check perfect quiz achievement
    if (quizProvider.score == quizProvider.totalQuestions &&
        quizProvider.totalQuestions > 0) {
      final a2 = await achievementProvider
          .checkAndUnlock(
            userId: userId,
            conditionType: 'perfect_quiz',
            currentValue: 1,
          );
      _showAchievementSnackBar(a2);
    }

    // Check words_learned / words_reviewed achievements
    final a3 = await achievementProvider
        .checkAndUnlock(
          userId: userId,
          conditionType: 'words_learned',
          currentValue: quizProvider.totalQuestions,
        );
    _showAchievementSnackBar(a3);
  }

  void _showAchievementSnackBar(AchievementModel? achievement) {
    if (achievement == null || !mounted) return;
    // Fire confetti for achievement unlock
    ConfettiOverlay.maybeOf(context)?.play();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.emoji_events_rounded,
                color: AppColors.xpGold, size: 24,),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Achievement Unlocked!',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.white,),
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
    return ConfettiOverlay(
      child: Scaffold(
      backgroundColor: AppTheme.background(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: AppTheme.textPrimary(context)),
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
                    const Text(
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
                  Semantics(
                    label: 'Quiz progress: question ${quiz.currentIndex + 1} of ${quiz.totalQuestions}',
                    value: '${quiz.totalQuestions > 0 ? ((quiz.currentIndex + 1) * 100 ~/ quiz.totalQuestions) : 0}%',
                    child: Row(
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
                  ),
                  const SizedBox(height: 48),

                  // Current word
                  Semantics(
                    label: 'Translate the word: ${quiz.currentWord!.englishWord}',
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        vertical: 40,
                        horizontal: 24,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.card(context),
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
                          const Text(
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
                          const SizedBox(height: 8),
                          Semantics(
                            button: true,
                            label: 'Listen to pronunciation of ${quiz.currentWord!.englishWord}',
                            child: IconButton(
                              onPressed: () => TtsService().speak(quiz.currentWord!.englishWord),
                              icon: const Icon(Icons.volume_up_rounded),
                              color: AppColors.primary.withValues(alpha: 0.7),
                              iconSize: 24,
                              tooltip: 'Listen',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Option buttons or typing field depending on quiz mode
                  Expanded(
                    child: context.watch<ThemeProvider>().isTypingQuiz
                        ? _buildTypingMode(quiz)
                        : ListView.builder(
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
                    },),
                ],
              ),
            ),
          );
        },
      ),
    ),
    );
  }

  Widget _buildTypingMode(QuizProvider quiz) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: TypingAnswerField(
          hint: 'Type the Russian translation...',
          isAnswered: _typingAnswered || quiz.isAnswered,
          isCorrect: _typingAnswerCorrect,
          correctAnswer: quiz.currentWord?.russianTranslation,
          enabled: !_isAdvancing && !quiz.timedOut,
          onSubmitted: _handleTypingAnswer,
        ),
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

    return Semantics(
      label: timedOut
          ? 'Time is up'
          : 'Timer: $seconds seconds remaining',
      liveRegion: isLow,
      child: Container(
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
    Color backgroundColor = AppTheme.card(context);
    Color borderColor = AppTheme.textHint(context).withValues(alpha:0.2);
    Color textColor = AppTheme.textPrimary(context);

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

    final optionLetter = String.fromCharCode(65 + index);
    final semanticState = isAnswered
        ? (option.isCorrect
            ? ', correct answer'
            : (selectedIndex == index ? ', incorrect answer' : ''))
        : '';

    return Semantics(
      button: !isAnswered,
      label: 'Option $optionLetter: ${option.text}$semanticState',
      enabled: !isAnswered,
      child: Padding(
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
      ),
    );
  }
}
