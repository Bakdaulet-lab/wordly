import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../constants/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/progress_provider.dart';
import '../../utils/debouncer.dart';

class ReviewScreen extends StatefulWidget {
  const ReviewScreen({super.key});

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  bool _initialized = false;
  final _reviewDebouncer = Debouncer(delay: const Duration(milliseconds: 600));

  @override
  void dispose() {
    _reviewDebouncer.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _loadDueWords();
    }
  }

  Future<void> _loadDueWords() async {
    final userId = context.read<AuthProvider>().user?.id;
    if (userId == null) return;
    await context.read<ProgressProvider>().loadDueWords(userId);
  }

  Future<void> _handleAnswer(bool knewIt) async {
    if (!_reviewDebouncer.runImmediate(() {})) return;

    final userId = context.read<AuthProvider>().user?.id;
    if (userId == null) return;

    await context.read<ProgressProvider>().answerReview(
          userId: userId,
          knewIt: knewIt,
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: AppTheme.textPrimary(context)),
          onPressed: () => context.go('/home'),
        ),
        title: const Text('Review', style: AppTextStyles.heading3),
        centerTitle: true,
      ),
      body: Consumer<ProgressProvider>(
        builder: (context, progress, child) {
          if (progress.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (progress.errorMessage != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: AppColors.errorRed,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      progress.errorMessage!,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.errorRed,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _loadDueWords,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          // No words due
          if (progress.reviewItems.isEmpty) {
            return _buildEmptyState();
          }

          // All reviewed
          if (progress.isReviewComplete) {
            return _buildCompletionState();
          }

          // Review in progress
          return _buildReviewCard(progress);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle_outline_rounded,
              size: 80,
              color: AppColors.successGreen,
            ),
            const SizedBox(height: 24),
            Text(
              'All Caught Up!',
              style: AppTextStyles.heading2.copyWith(
                color: AppColors.successGreen,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'No words are due for review right now.\nCome back later or try a quiz!',
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => context.go('/home'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Go Home', style: AppTextStyles.button),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletionState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.celebration_rounded,
              size: 80,
              color: AppColors.xpGold,
            ),
            const SizedBox(height: 24),
            Text(
              'Review Complete!',
              style: AppTextStyles.heading1.copyWith(
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 12),
            Consumer<ProgressProvider>(
              builder: (context, progress, child) {
                return Text(
                  'You reviewed ${progress.dueCount} word${progress.dueCount == 1 ? '' : 's'} successfully.',
                  style: AppTextStyles.bodyMedium,
                  textAlign: TextAlign.center,
                );
              },
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => context.go('/home'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Go Home', style: AppTextStyles.button),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewCard(ProgressProvider progress) {
    final currentWord = progress.currentWord;
    final currentIndex = progress.currentIndex;
    final totalItems = progress.reviewItems.length;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Progress indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${currentIndex + 1} of $totalItems',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: totalItems > 0 ? (currentIndex + 1) / totalItems : 0,
                backgroundColor: AppColors.textHint.withValues(alpha:0.2),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.primary,
                ),
                minHeight: 6,
              ),
            ),

            // Word card centered
            Expanded(
              child: Center(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 48,
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
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Do you know this word?',
                        style: AppTextStyles.bodyMedium,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        currentWord?.englishWord ?? '',
                        style: AppTextStyles.heading1.copyWith(
                          fontSize: 36,
                          color: AppColors.primary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        currentWord?.russianTranslation ?? '',
                        style: AppTextStyles.heading3.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Answer buttons
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () => _handleAnswer(false),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.errorRed,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.close_rounded, size: 20),
                          SizedBox(width: 8),
                          Text(
                            "Didn't Know",
                            style: AppTextStyles.button,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () => _handleAnswer(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.successGreen,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_rounded, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'I Knew It',
                            style: AppTextStyles.button,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
