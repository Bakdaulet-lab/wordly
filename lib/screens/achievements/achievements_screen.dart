import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../constants/app_text_styles.dart';
import '../../constants/app_theme.dart';
import '../../models/achievement_model.dart';
import '../../providers/achievement_provider.dart';
import '../../providers/auth_provider.dart';

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Achievements', style: AppTextStyles.heading2),
        centerTitle: true,
      ),
      body: Consumer<AchievementProvider>(
        builder: (context, achievementProvider, child) {
          if (achievementProvider.isLoading) {
            return Center(
              child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary),
            );
          }

          if (achievementProvider.errorMessage != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      achievementProvider.errorMessage!,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Theme.of(context).colorScheme.error,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        final userId = context.read<AuthProvider>().user?.id;
                        if (userId != null) {
                          achievementProvider.loadAchievements(userId);
                        }
                      },
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text('Retry'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final achievements = achievementProvider.allAchievements;

          if (achievements.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.emoji_events_outlined,
                    size: 64,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No achievements available yet',
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                ],
              ),
            );
          }

          final unlockedCount = achievementProvider.unlockedIds.length;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                child: Text(
                  '$unlockedCount of ${achievements.length} unlocked',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: achievements.length,
                  itemBuilder: (context, index) {
                    final achievement = achievements[index];
                    final isUnlocked =
                        achievementProvider.isUnlocked(achievement.id);
                    return _buildAchievementCard(context, achievement, isUnlocked)
                        .animate()
                        .fadeIn(
                          duration: 350.ms,
                          delay: Duration(milliseconds: 50 * (index % 8)),
                        )
                        .scale(
                          begin: const Offset(0.95, 0.95),
                          end: const Offset(1.0, 1.0),
                          duration: 350.ms,
                          delay: Duration(milliseconds: 50 * (index % 8)),
                        );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAchievementCard(BuildContext context, AchievementModel achievement, bool isUnlocked) {
    final iconData = _getIconData(achievement.iconName);

    return Semantics(
      label: '${achievement.name} achievement, '
          '${isUnlocked ? 'unlocked' : 'locked'}. '
          '${achievement.description}',
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isUnlocked
              ? AppTheme.card(context)
              : AppTheme.card(context).withValues(alpha:0.7),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isUnlocked
                ? AppTheme.xpGold.withValues(alpha:0.5)
                : Theme.of(context).colorScheme.outline.withValues(alpha:0.15),
            width: isUnlocked ? 2 : 1,
          ),
          boxShadow: isUnlocked
              ? [
                  BoxShadow(
                    color: AppTheme.xpGold.withValues(alpha:0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha:0.03),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: isUnlocked
                        ? AppTheme.xpGold.withValues(alpha:0.15)
                        : Theme.of(context).colorScheme.outline.withValues(alpha:0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    iconData,
                    size: 28,
                    color: isUnlocked ? AppTheme.xpGold : Theme.of(context).colorScheme.outline,
                  ),
                ),
                if (!isUnlocked)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.outline.withValues(alpha:0.8),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.lock_rounded,
                        size: 12,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              achievement.name,
              style: AppTextStyles.bodyLarge.copyWith(
                fontWeight: FontWeight.w600,
                color: isUnlocked ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.outline,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              achievement.description,
              style: AppTextStyles.caption.copyWith(
                color: isUnlocked ? Theme.of(context).colorScheme.onSurfaceVariant : Theme.of(context).colorScheme.outline,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'star':
        return Icons.star_rounded;
      case 'fire':
        return Icons.local_fire_department_rounded;
      case 'trophy':
        return Icons.emoji_events_rounded;
      case 'book':
        return Icons.menu_book_rounded;
      case 'brain':
        return Icons.psychology_rounded;
      case 'target':
        return Icons.track_changes_rounded;
      case 'lightning':
        return Icons.bolt_rounded;
      case 'rocket':
        return Icons.rocket_launch_rounded;
      case 'crown':
        return Icons.workspace_premium_rounded;
      case 'medal':
        return Icons.military_tech_rounded;
      case 'heart':
        return Icons.favorite_rounded;
      case 'diamond':
        return Icons.diamond_rounded;
      default:
        return Icons.emoji_events_rounded;
    }
  }
}
