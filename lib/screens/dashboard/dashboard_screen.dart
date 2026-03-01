import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../constants/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/word_list_provider.dart';
import '../../providers/stats_provider.dart';
import '../../providers/progress_provider.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          final userId = context.read<AuthProvider>().user?.id;
          if (userId == null) return;
          await Future.wait([
            context.read<ProfileProvider>().refreshProfile(userId),
            context.read<StatsProvider>().refreshTodayStats(userId),
            context.read<ProgressProvider>().refreshDueCount(userId),
          ]);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProfileSummary()
                  .animate()
                  .fadeIn(duration: 400.ms)
                  .slideY(begin: 0.05, end: 0, duration: 400.ms),
              const SizedBox(height: 24),
              const Text('Today\'s Progress', style: AppTextStyles.heading3),
              const SizedBox(height: 12),
              _buildStatCards(),
              const SizedBox(height: 16),
              _buildDailyGoalCard(context),
              const SizedBox(height: 24),
              _buildWordOfTheDay(context),
              const SizedBox(height: 24),
              _buildWeeklyChart(),
              const SizedBox(height: 24),
              _buildAnalyticsCard(context),
              const SizedBox(height: 24),
              _buildWordLifterCard(context),
              const SizedBox(height: 24),
              _buildReviewCard(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileSummary() {
    return Consumer<ProfileProvider>(
      builder: (context, profileProvider, child) {
        if (profileProvider.isLoading) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }

        if (profileProvider.errorMessage != null) {
          return _buildErrorCard(profileProvider.errorMessage!);
        }

        final displayName = profileProvider.displayName;
        final level = profileProvider.level;
        final xpProgress = profileProvider.xpProgress;
        final totalXp = profileProvider.totalXp;
        final xpForNext = profileProvider.xpForNextLevel;
        final streak = profileProvider.currentStreak;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.white.withValues(alpha:0.2),
                    child: Text(
                      displayName.isNotEmpty
                          ? displayName[0].toUpperCase()
                          : '?',
                      style: AppTextStyles.heading2.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName.isNotEmpty ? displayName : 'Learner',
                          style: AppTextStyles.heading3.copyWith(
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Level $level',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: Colors.white.withValues(alpha:0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (streak > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha:0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.local_fire_department_rounded,
                            color: AppColors.streakOrange,
                            size: 20,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$streak',
                            style: AppTextStyles.bodyLarge.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text(
                    'XP: $totalXp',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.white.withValues(alpha:0.8),
                    ),
                  ),
                  const Spacer(),
                  if (xpForNext != null)
                    Text(
                      'Next: $xpForNext XP',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.white.withValues(alpha:0.8),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: xpProgress,
                  backgroundColor: Colors.white.withValues(alpha:0.2),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.xpGold,
                  ),
                  minHeight: 8,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCards() {
    return Consumer<StatsProvider>(
      builder: (context, statsProvider, child) {
        if (statsProvider.isLoading) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }

        if (statsProvider.errorMessage != null) {
          return _buildErrorCard(statsProvider.errorMessage!);
        }

        final wordsReviewed = statsProvider.todayWordsReviewed;
        final accuracy = statsProvider.todayAccuracy;
        final xpEarned = statsProvider.todayXpEarned;

        return Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context: context,
                icon: Icons.menu_book_rounded,
                iconColor: AppColors.primary,
                label: 'Reviewed',
                value: '$wordsReviewed',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                context: context,
                icon: Icons.track_changes_rounded,
                iconColor: AppColors.successGreen,
                label: 'Accuracy',
                value: '${(accuracy * 100).toInt()}%',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                context: context,
                icon: Icons.star_rounded,
                iconColor: AppColors.xpGold,
                label: 'XP Earned',
                value: '$xpEarned',
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
color: AppTheme.card(context),
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
        children: [
          Icon(icon, color: iconColor, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTextStyles.heading2.copyWith(fontSize: 20),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTextStyles.caption,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsCard(BuildContext context) {
    return InkWell(
      onTap: () => context.push('/analytics'),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary.withValues(alpha: 0.1),
              AppColors.primaryLight.withValues(alpha: 0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.analytics_rounded,
                color: AppColors.primary,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Analytics & Charts', style: AppTextStyles.heading3),
                  SizedBox(height: 4),
                  Text(
                    'View detailed progress charts and trends',
                    style: AppTextStyles.bodyMedium,
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: AppColors.textHint,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWordLifterCard(BuildContext context) {
    return InkWell(
      onTap: () => context.push('/word-lifter'),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.streakOrange.withValues(alpha: 0.12),
              AppColors.xpGold.withValues(alpha: 0.06),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.streakOrange.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.streakOrange.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.fitness_center_rounded,
                color: AppColors.streakOrange,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Word Lifter 💪', style: AppTextStyles.heading3),
                  SizedBox(height: 4),
                  Text(
                    'Gym mini-game — lift weights by translating words!',
                    style: AppTextStyles.bodyMedium,
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: AppColors.textHint,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewCard(BuildContext context) {
    return Consumer<ProgressProvider>(
      builder: (context, progressProvider, child) {
        final dueCount = progressProvider.dueCount;

        return InkWell(
          onTap: dueCount > 0 ? () => context.go('/review') : null,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
            color: AppTheme.card(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: dueCount > 0
                  ? AppColors.streakOrange.withValues(alpha:0.5)
                  : AppTheme.textHint(context).withValues(alpha:0.2),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha:0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: dueCount > 0
                        ? AppColors.streakOrange.withValues(alpha:0.1)
                        : AppColors.textHint.withValues(alpha:0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.replay_rounded,
                    color: dueCount > 0
                        ? AppColors.streakOrange
                        : AppColors.textHint,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Words Due for Review',
                        style: AppTextStyles.heading3,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dueCount > 0
                            ? '$dueCount word${dueCount == 1 ? '' : 's'} ready to review'
                            : 'No words due right now. Great job!',
                        style: AppTextStyles.bodyMedium,
                      ),
                    ],
                  ),
                ),
                if (dueCount > 0)
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: AppColors.textHint,
                    size: 16,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDailyGoalCard(BuildContext context) {
    return Consumer<StatsProvider>(
      builder: (context, statsProvider, child) {
        final goal = statsProvider.dailyXpGoal;
        final earned = statsProvider.todayXpEarned;
        final progress = statsProvider.dailyGoalProgress;
        final reached = statsProvider.dailyGoalReached;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.card(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: reached
                  ? AppColors.successGreen.withValues(alpha: 0.4)
                  : AppTheme.textHint(context).withValues(alpha: 0.15),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
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
                  Icon(
                    reached
                        ? Icons.check_circle_rounded
                        : Icons.flag_rounded,
                    color: reached
                        ? AppColors.successGreen
                        : AppColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Daily Goal',
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => _showGoalPicker(context, statsProvider),
                    child: Text(
                      '$earned / $goal XP',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: AppColors.textHint.withValues(alpha: 0.15),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    reached ? AppColors.successGreen : AppColors.primary,
                  ),
                  minHeight: 8,
                ),
              ),
              if (reached)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Goal reached! Great work today.',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.successGreen,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _showGoalPicker(BuildContext context, StatsProvider statsProvider) {
    final goals = [30, 50, 75, 100, 150, 200];
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.card(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Set Daily XP Goal', style: AppTextStyles.heading3),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: goals.map((g) {
                    final isSelected = g == statsProvider.dailyXpGoal;
                    return ChoiceChip(
                      label: Text('$g XP'),
                      selected: isSelected,
                      onSelected: (_) {
                        statsProvider.setDailyGoal(g);
                        Navigator.pop(ctx);
                      },
                      selectedColor: AppColors.primary,
                      backgroundColor: AppColors.surface,
                      labelStyle: AppTextStyles.bodyMedium.copyWith(
                        color: isSelected ? Colors.white : AppColors.textPrimary,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWordOfTheDay(BuildContext context) {
    return Consumer<WordListProvider>(
      builder: (context, wordProvider, child) {
        final allWords = wordProvider.allWords;
        if (allWords.isEmpty) return const SizedBox.shrink();

        final now = DateTime.now();
        final daySeed = now.year * 10000 + now.month * 100 + now.day;
        final index = Random(daySeed).nextInt(allWords.length);
        final word = allWords[index];

        return InkWell(
          onTap: () => context.push('/words/${word.id}'),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.xpGold.withValues(alpha: 0.15),
                  AppColors.xpGold.withValues(alpha: 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.xpGold.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.xpGold.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    color: AppColors.xpGold,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Word of the Day',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.xpGold,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        word.englishWord,
                        style: AppTextStyles.heading3.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        word.russianTranslation,
                        style: AppTextStyles.bodyMedium,
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: AppColors.textHint,
                  size: 16,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWeeklyChart() {
    return Consumer<StatsProvider>(
      builder: (context, statsProvider, child) {
        final recentStats = statsProvider.recentStats;
        if (recentStats.isEmpty) return const SizedBox.shrink();

        // Get last 7 days of XP data
        final now = DateTime.now();
        final dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        final weekData = <int>[];

        for (int i = 6; i >= 0; i--) {
          final day = now.subtract(Duration(days: i));
          final stat = recentStats.where((s) =>
            s.date.year == day.year &&
            s.date.month == day.month &&
            s.date.day == day.day,
          ).toList();
          weekData.add(stat.isNotEmpty ? stat.first.xpEarned : 0);
        }

        final maxXp = weekData.reduce((a, b) => a > b ? a : b);
        const barMaxHeight = 80.0;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.card(context),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Weekly XP', style: AppTextStyles.heading3),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(7, (i) {
                  final xp = weekData[i];
                  final height =
                      maxXp > 0 ? (xp / maxXp) * barMaxHeight : 0.0;
                  final dayIndex =
                      (now.subtract(Duration(days: 6 - i)).weekday - 1) % 7;
                  final isToday = i == 6;

                  return Expanded(
                    child: Column(
                      children: [
                        Text(
                          '$xp',
                          style: AppTextStyles.caption.copyWith(
                            fontSize: 10,
                            color: isToday
                                ? AppColors.primary
                                : AppColors.textHint,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          height: height < 4 && xp > 0 ? 4 : height,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: isToday
                                ? AppColors.primary
                                : AppColors.primary.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          dayLabels[dayIndex],
                          style: AppTextStyles.caption.copyWith(
                            fontSize: 10,
                            color: isToday
                                ? AppColors.primary
                                : AppColors.textHint,
                            fontWeight: isToday
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildErrorCard(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.errorRed.withValues(alpha:0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.errorRed),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.errorRed,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Builder(
            builder: (context) => IconButton(
              onPressed: () {
                final userId = context.read<AuthProvider>().user?.id;
                if (userId == null) return;
                context.read<ProfileProvider>().refreshProfile(userId);
                context.read<StatsProvider>().refreshTodayStats(userId);
                context.read<ProgressProvider>().refreshDueCount(userId);
              },
              icon: const Icon(Icons.refresh_rounded, color: AppColors.errorRed, size: 20),
              tooltip: 'Retry',
              visualDensity: VisualDensity.compact,
            ),
          ),
        ],
      ),
    );
  }
}
