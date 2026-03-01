import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../constants/app_colors.dart';

/// A brief overlay shown on rep success or rep failure.
class RepResultOverlay extends StatelessWidget {
  final bool isSuccess;
  final int xpGained;
  final int newWeight;

  const RepResultOverlay({
    super.key,
    required this.isSuccess,
    this.xpGained = 0,
    this.newWeight = 0,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSuccess ? AppColors.xpGold : AppColors.errorRed;
    final icon = isSuccess
        ? Icons.emoji_events_rounded
        : Icons.trending_down_rounded;
    final title = isSuccess ? 'REP COMPLETE!' : 'DROPPED!';
    final subtitle = isSuccess
        ? '+$xpGained XP  •  Next: $newWeight kg'
        : 'Streak lost — keep going!';

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 40),
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 22),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.5),
              blurRadius: 24,
              spreadRadius: 4,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 48),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      )
          .animate()
          .scale(
            begin: const Offset(0.5, 0.5),
            end: const Offset(1.0, 1.0),
            duration: 400.ms,
            curve: Curves.elasticOut,
          )
          .fadeIn(duration: 200.ms),
    );
  }
}
