import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../models/quiz_option_model.dart';

class QuizOptionButton extends StatelessWidget {
  final QuizOptionModel option;
  final int index;
  final int? selectedIndex;
  final bool isAnswered;
  final VoidCallback onTap;

  const QuizOptionButton({
    super.key,
    required this.option,
    required this.index,
    required this.selectedIndex,
    required this.isAnswered,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color backgroundColor = AppColors.surface;
    Color borderColor = Colors.grey.shade300;
    Color textColor = AppColors.textPrimary;
    IconData? trailingIcon;

    if (isAnswered) {
      if (option.isCorrect) {
        backgroundColor = AppColors.successGreen.withValues(alpha: 0.1);
        borderColor = AppColors.successGreen;
        textColor = AppColors.successGreen;
        trailingIcon = Icons.check_circle;
      } else if (index == selectedIndex && !option.isCorrect) {
        backgroundColor = AppColors.errorRed.withValues(alpha: 0.1);
        borderColor = AppColors.errorRed;
        textColor = AppColors.errorRed;
        trailingIcon = Icons.cancel;
      }
    }

    final optionLetter = String.fromCharCode(65 + index);
    final semanticState = isAnswered
        ? (option.isCorrect
            ? ', correct answer'
            : (index == selectedIndex ? ', incorrect answer' : ''))
        : '';

    return Semantics(
      button: !isAnswered,
      label: 'Option $optionLetter: ${option.text}$semanticState',
      enabled: !isAnswered,
      child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
      child: Material(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: isAnswered ? null : onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              border: Border.all(color: borderColor, width: 1.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: borderColor.withValues(alpha: 0.2),
                  ),
                  child: Center(
                    child: Text(
                      String.fromCharCode(65 + index), // A, B, C, D
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: textColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    option.text,
                    style: AppTextStyles.bodyLarge.copyWith(color: textColor),
                  ),
                ),
                if (trailingIcon != null)
                  Icon(trailingIcon, color: textColor, size: 24),
              ],
            ),
          ),
        ),
      ),
      ),
    );
  }
}
