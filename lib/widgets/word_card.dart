import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../models/word_model.dart';

class WordCard extends StatelessWidget {
  final WordModel word;
  final VoidCallback? onTap;

  const WordCard({super.key, required this.word, this.onTap});

  Color _difficultyColor(int level) {
    switch (level) {
      case 1:
        return AppColors.difficultyBeginner;
      case 2:
        return AppColors.difficultyEasy;
      case 3:
        return AppColors.difficultyMedium;
      case 4:
        return AppColors.difficultyHard;
      case 5:
        return AppColors.difficultyExpert;
      default:
        return AppColors.difficultyBeginner;
    }
  }

  String _difficultyLabel(int level) {
    switch (level) {
      case 1:
        return 'Beginner';
      case 2:
        return 'Easy';
      case 3:
        return 'Medium';
      case 4:
        return 'Hard';
      case 5:
        return 'Expert';
      default:
        return 'Beginner';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(word.englishWord, style: AppTextStyles.heading3),
                    const SizedBox(height: 4),
                    Text(word.russianTranslation, style: AppTextStyles.bodyMedium),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _difficultyColor(word.difficultyLevel).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _difficultyLabel(word.difficultyLevel),
                  style: AppTextStyles.caption.copyWith(
                    color: _difficultyColor(word.difficultyLevel),
                    fontWeight: FontWeight.w600,
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
