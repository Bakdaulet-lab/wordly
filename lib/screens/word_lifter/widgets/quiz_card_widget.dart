import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/app_text_styles.dart';
import '../../../models/quiz_option_model.dart';

/// Displays the current English word and 4 answer options.
class QuizCardWidget extends StatelessWidget {
  final String englishWord;
  final List<QuizOptionModel> options;
  final int? selectedIndex;
  final bool isAnswered;
  final ValueChanged<int> onOptionTap;

  const QuizCardWidget({
    super.key,
    required this.englishWord,
    required this.options,
    required this.selectedIndex,
    required this.isAnswered,
    required this.onOptionTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1E1E2C)
            : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // English word
          Text(
            englishWord,
            style: AppTextStyles.heading2.copyWith(
              color: AppColors.primary,
              letterSpacing: 1.2,
            ),
            textAlign: TextAlign.center,
          )
              .animate(key: ValueKey(englishWord))
              .fadeIn(duration: 300.ms)
              .scale(
                begin: const Offset(0.9, 0.9),
                end: const Offset(1.0, 1.0),
                duration: 300.ms,
                curve: Curves.easeOutBack,
              ),
          const SizedBox(height: 6),
          Text(
            'Choose the correct translation',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textHint,
            ),
          ),
          const SizedBox(height: 16),
          // Options
          ...List.generate(options.length, (i) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _OptionTile(
                option: options[i],
                index: i,
                selectedIndex: selectedIndex,
                isAnswered: isAnswered,
                onTap: () => onOptionTap(i),
              ),
            )
                .animate(key: ValueKey('$englishWord-opt-$i'))
                .fadeIn(
                  duration: 200.ms,
                  delay: Duration(milliseconds: 80 * i),
                )
                .slideX(
                  begin: 0.05,
                  end: 0,
                  duration: 200.ms,
                  delay: Duration(milliseconds: 80 * i),
                );
          }),
        ],
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final QuizOptionModel option;
  final int index;
  final int? selectedIndex;
  final bool isAnswered;
  final VoidCallback onTap;

  const _OptionTile({
    required this.option,
    required this.index,
    required this.selectedIndex,
    required this.isAnswered,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color borderColor;
    Color textColor;
    IconData? trailingIcon;

    if (isAnswered) {
      if (option.isCorrect) {
        bgColor = AppColors.successGreen.withValues(alpha: 0.12);
        borderColor = AppColors.successGreen;
        textColor = AppColors.successGreen;
        trailingIcon = Icons.check_circle_rounded;
      } else if (index == selectedIndex && !option.isCorrect) {
        bgColor = AppColors.errorRed.withValues(alpha: 0.12);
        borderColor = AppColors.errorRed;
        textColor = AppColors.errorRed;
        trailingIcon = Icons.cancel_rounded;
      } else {
        bgColor = Colors.transparent;
        borderColor = Colors.grey.shade300;
        textColor = Colors.grey.shade500;
        trailingIcon = null;
      }
    } else {
      bgColor = Colors.transparent;
      borderColor = Theme.of(context).brightness == Brightness.dark
          ? Colors.grey.shade700
          : Colors.grey.shade300;
      textColor = Theme.of(context).brightness == Brightness.dark
          ? Colors.white
          : AppColors.textPrimary;
      trailingIcon = null;
    }

    final label = String.fromCharCode(65 + index);

    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: isAnswered ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            border: Border.all(color: borderColor, width: 1.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: borderColor.withValues(alpha: 0.2),
                ),
                child: Center(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  option.text,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (trailingIcon != null)
                Icon(trailingIcon, color: textColor, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}
