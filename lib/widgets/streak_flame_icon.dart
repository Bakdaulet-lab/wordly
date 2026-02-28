import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';

class StreakFlameIcon extends StatelessWidget {
  final int streakCount;

  const StreakFlameIcon({super.key, required this.streakCount});

  bool get _isMilestone =>
      streakCount == 7 || streakCount == 30 || streakCount == 100;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: streakCount > 0
          ? 'Current streak: $streakCount day${streakCount == 1 ? '' : 's'}'
          : 'No active streak',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.local_fire_department_rounded,
            color: streakCount > 0 ? AppColors.streakOrange : AppColors.textHint,
            size: 28,
            semanticLabel: 'Streak flame icon',
          ),
          const SizedBox(width: 4),
          Text(
            '$streakCount',
            style: AppTextStyles.heading3.copyWith(
              color: streakCount > 0 ? AppColors.streakOrange : AppColors.textHint,
              fontWeight: _isMilestone ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
