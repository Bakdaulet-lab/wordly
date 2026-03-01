import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/app_text_styles.dart';

/// Shown when the game is finished (3 failed reps).
class GameOverCard extends StatelessWidget {
  final int totalReps;
  final int maxWeight;
  final int totalXp;
  final int correctAnswers;
  final int totalQuestions;
  final VoidCallback onPlayAgain;
  final VoidCallback onGoHome;

  const GameOverCard({
    super.key,
    required this.totalReps,
    required this.maxWeight,
    required this.totalXp,
    required this.correctAnswers,
    required this.totalQuestions,
    required this.onPlayAgain,
    required this.onGoHome,
  });

  @override
  Widget build(BuildContext context) {
    final accuracy =
        totalQuestions > 0 ? (correctAnswers / totalQuestions * 100) : 0;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF1E1E2C)
                : Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 30,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Trophy
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.xpGold.withValues(alpha: 0.15),
                ),
                child: const Icon(
                  Icons.emoji_events_rounded,
                  color: AppColors.xpGold,
                  size: 56,
                ),
              )
                  .animate()
                  .scale(
                    begin: const Offset(0.0, 0.0),
                    end: const Offset(1.0, 1.0),
                    duration: 600.ms,
                    curve: Curves.elasticOut,
                  ),
              const SizedBox(height: 16),
              Text(
                'Workout Complete!',
                style: AppTextStyles.heading1.copyWith(fontSize: 24),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Stats grid
              Row(
                children: [
                  _StatTile(
                    icon: Icons.fitness_center,
                    value: '$totalReps',
                    label: 'Reps',
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 12),
                  _StatTile(
                    icon: Icons.monitor_weight_outlined,
                    value: '$maxWeight kg',
                    label: 'Max Weight',
                    color: AppColors.streakOrange,
                  ),
                ],
              )
                  .animate()
                  .fadeIn(duration: 400.ms, delay: 200.ms)
                  .slideY(begin: 0.1, end: 0, duration: 400.ms, delay: 200.ms),
              const SizedBox(height: 12),
              Row(
                children: [
                  _StatTile(
                    icon: Icons.star_rounded,
                    value: '$totalXp',
                    label: 'XP Earned',
                    color: AppColors.xpGold,
                  ),
                  const SizedBox(width: 12),
                  _StatTile(
                    icon: Icons.gps_fixed,
                    value: '${accuracy.toStringAsFixed(0)}%',
                    label: 'Accuracy',
                    color: AppColors.successGreen,
                  ),
                ],
              )
                  .animate()
                  .fadeIn(duration: 400.ms, delay: 350.ms)
                  .slideY(begin: 0.1, end: 0, duration: 400.ms, delay: 350.ms),
              const SizedBox(height: 28),

              // Buttons
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onPlayAgain,
                  icon: const Icon(Icons.replay_rounded),
                  label: const Text('Play Again'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: onGoHome,
                  child: Text(
                    'Back to Home',
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatTile({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppTextStyles.caption,
            ),
          ],
        ),
      ),
    );
  }
}
