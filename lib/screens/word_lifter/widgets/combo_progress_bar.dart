import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';

/// A row of 5 dots showing progress toward completing a rep.
///
/// [filledCount] (0–5) determines how many dots are lit green.
/// [isComplete] triggers a brief gold flash on all dots.
class ComboProgressBar extends StatelessWidget {
  final int filledCount;
  final int total;
  final bool isComplete;

  const ComboProgressBar({
    super.key,
    required this.filledCount,
    this.total = 5,
    this.isComplete = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(total, (i) {
        final isFilled = i < filledCount;
        final Color targetColor;
        if (isComplete) {
          targetColor = AppColors.xpGold;
        } else if (isFilled) {
          targetColor = AppColors.successGreen;
        } else {
          targetColor = Colors.grey.shade400;
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            width: isFilled || isComplete ? 18 : 14,
            height: isFilled || isComplete ? 18 : 14,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: targetColor,
              boxShadow: isFilled || isComplete
                  ? [
                      BoxShadow(
                        color: targetColor.withValues(alpha: 0.5),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: isFilled || isComplete
                ? const Icon(Icons.check, size: 10, color: Colors.white)
                : null,
          ),
        );
      }),
    );
  }
}
