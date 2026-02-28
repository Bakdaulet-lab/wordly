import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../models/achievement_model.dart';

class AchievementBadge extends StatelessWidget {
  final AchievementModel achievement;
  final bool isUnlocked;

  const AchievementBadge({
    super.key,
    required this.achievement,
    required this.isUnlocked,
  });

  IconData _getIcon(String iconName) {
    switch (iconName) {
      case 'star':
        return Icons.star_rounded;
      case 'book':
        return Icons.menu_book_rounded;
      case 'fire':
        return Icons.local_fire_department_rounded;
      case 'trophy':
        return Icons.emoji_events_rounded;
      case 'lightning':
        return Icons.bolt_rounded;
      case 'target':
        return Icons.track_changes_rounded;
      case 'rocket':
        return Icons.rocket_launch_rounded;
      case 'crown':
        return Icons.workspace_premium_rounded;
      case 'brain':
        return Icons.psychology_rounded;
      case 'heart':
        return Icons.favorite_rounded;
      default:
        return Icons.star_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = isUnlocked ? AppColors.xpGold : AppColors.textHint;

    return Semantics(
      label: '${achievement.name} achievement, ${isUnlocked ? 'unlocked' : 'locked'}. ${achievement.description}',
      child: Card(
      elevation: isUnlocked ? 3 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isUnlocked ? AppColors.xpGold.withValues(alpha: 0.5) : Colors.grey.shade200,
          width: isUnlocked ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  _getIcon(achievement.iconName),
                  size: 40,
                  color: color,
                ),
                if (!isUnlocked)
                  Icon(
                    Icons.lock,
                    size: 20,
                    color: Colors.grey.shade400,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              achievement.name,
              style: AppTextStyles.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
                color: isUnlocked ? AppColors.textPrimary : AppColors.textHint,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              achievement.description,
              style: AppTextStyles.caption.copyWith(
                color: isUnlocked ? AppColors.textSecondary : AppColors.textHint,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    ),
    );
  }
}
