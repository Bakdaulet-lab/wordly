import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';

class XpProgressBar extends StatelessWidget {
  final double progress; // 0.0 to 1.0
  final int currentXp;
  final int? xpToNextLevel;
  final int level;

  const XpProgressBar({
    super.key,
    required this.progress,
    required this.currentXp,
    this.xpToNextLevel,
    required this.level,
  });

  @override
  Widget build(BuildContext context) {
    final pct = (progress.clamp(0.0, 1.0) * 100).round();
    return Semantics(
      label: 'Experience progress: Level $level, $currentXp'
          '${xpToNextLevel != null ? ' of $xpToNextLevel' : ''} XP, $pct percent',
      value: '$pct%',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Level $level',
                style: AppTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (xpToNextLevel != null)
                Text(
                  '$currentXp / $xpToNextLevel XP',
                  style: AppTextStyles.caption,
                ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 10,
              backgroundColor: AppColors.xpGold.withValues(alpha: 0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.xpGold),
              semanticsLabel: 'XP progress',
              semanticsValue: '$pct%',
            ),
          ),
        ],
      ),
    );
  }
}
