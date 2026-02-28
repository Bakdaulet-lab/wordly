import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
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
              _buildProfileSummary(),
              const SizedBox(height: 24),
              Text('Today\'s Progress', style: AppTextStyles.heading3),
              const SizedBox(height: 12),
              _buildStatCards(),
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
                icon: Icons.menu_book_rounded,
                iconColor: AppColors.primary,
                label: 'Reviewed',
                value: '$wordsReviewed',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                icon: Icons.track_changes_rounded,
                iconColor: AppColors.successGreen,
                label: 'Accuracy',
                value: '${(accuracy * 100).toInt()}%',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
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
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Container(
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
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: dueCount > 0
                    ? AppColors.streakOrange.withValues(alpha:0.5)
                    : AppColors.textHint.withValues(alpha:0.2),
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
                      Text(
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
        ],
      ),
    );
  }
}
