import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/app_text_styles.dart';

/// Top HUD bar for the Word Lifter game: rep counter, timer, XP.
class GameHudWidget extends StatelessWidget {
  final int currentRep;
  final int timerSeconds;
  final int timerDuration;
  final int totalXp;
  final int failedReps;
  final int maxFailedReps;

  const GameHudWidget({
    super.key,
    required this.currentRep,
    required this.timerSeconds,
    required this.timerDuration,
    required this.totalXp,
    required this.failedReps,
    required this.maxFailedReps,
  });

  @override
  Widget build(BuildContext context) {
    final timerFraction =
        timerDuration > 0 ? timerSeconds / timerDuration : 0.0;
    final timerColor = Color.lerp(
      AppColors.errorRed,
      AppColors.successGreen,
      timerFraction,
    )!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top row: rep, XP, lives
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Rep counter
              Row(
                children: [
                  const Icon(Icons.fitness_center, color: Colors.white70, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    'Rep $currentRep',
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              // XP display with animated counter
              TweenAnimationBuilder<int>(
                tween: IntTween(begin: 0, end: totalXp),
                duration: const Duration(milliseconds: 500),
                builder: (context, value, _) {
                  return Row(
                    children: [
                      const Icon(Icons.star_rounded,
                          color: AppColors.xpGold, size: 18,),
                      const SizedBox(width: 4),
                      Text(
                        '$value XP',
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: AppColors.xpGold,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  );
                },
              ),
              // Lives (failed reps remaining)
              Row(
                children: List.generate(maxFailedReps, (i) {
                  final lost = i < failedReps;
                  return Padding(
                    padding: const EdgeInsets.only(left: 2),
                    child: Icon(
                      lost ? Icons.heart_broken : Icons.favorite,
                      color: lost
                          ? Colors.grey.shade600
                          : AppColors.errorRed,
                      size: 18,
                    ),
                  );
                }),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Timer bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 900),
              curve: Curves.linear,
              height: 6,
              child: LinearProgressIndicator(
                value: timerFraction,
                backgroundColor: Colors.white12,
                valueColor: AlwaysStoppedAnimation(timerColor),
                minHeight: 6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
