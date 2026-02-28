import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../models/word_model.dart';

class WordCard extends StatefulWidget {
  final WordModel word;
  final VoidCallback? onTap;
  final bool isFavorite;
  final VoidCallback? onFavoriteToggle;
  final int animationIndex;

  const WordCard({
    super.key,
    required this.word,
    this.onTap,
    this.isFavorite = false,
    this.onFavoriteToggle,
    this.animationIndex = 0,
  });

  @override
  State<WordCard> createState() => _WordCardState();
}

class _WordCardState extends State<WordCard> {
  bool _pressed = false;

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
    final delay = Duration(milliseconds: 50 * (widget.animationIndex % 8));
    final diffLabel = _difficultyLabel(widget.word.difficultyLevel);
    final favLabel = widget.isFavorite ? ', favorited' : '';

    return Semantics(
      button: true,
      label: '${widget.word.englishWord}, ${widget.word.russianTranslation}. '
          'Difficulty: $diffLabel$favLabel',
      child: AnimatedScale(
      scale: _pressed ? 0.97 : 1.0,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeInOut,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          onTap: widget.onTap,
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) => setState(() => _pressed = false),
          onTapCancel: () => setState(() => _pressed = false),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.word.englishWord, style: AppTextStyles.heading3),
                      const SizedBox(height: 4),
                      Text(widget.word.russianTranslation, style: AppTextStyles.bodyMedium),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _difficultyColor(widget.word.difficultyLevel).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _difficultyLabel(widget.word.difficultyLevel),
                    style: AppTextStyles.caption.copyWith(
                      color: _difficultyColor(widget.word.difficultyLevel),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (widget.onFavoriteToggle != null) ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: widget.onFavoriteToggle,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                      child: Icon(
                        widget.isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        key: ValueKey(widget.isFavorite),
                        color: widget.isFavorite ? AppColors.errorRed : AppColors.textHint,
                        size: 22,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    ),
    )
        .animate()
        .fadeIn(duration: 350.ms, delay: delay, curve: Curves.easeOut)
        .slideY(begin: 0.08, end: 0, duration: 350.ms, delay: delay, curve: Curves.easeOut);
  }
}
