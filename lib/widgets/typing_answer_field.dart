import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../constants/app_theme.dart';

/// A text field widget for the typing quiz mode where users type translations.
class TypingAnswerField extends StatefulWidget {
  final String hint;
  final bool isAnswered;
  final bool? isCorrect;
  final String? correctAnswer;
  final ValueChanged<String> onSubmitted;
  final bool enabled;

  const TypingAnswerField({
    super.key,
    this.hint = 'Type the translation...',
    required this.isAnswered,
    this.isCorrect,
    this.correctAnswer,
    required this.onSubmitted,
    this.enabled = true,
  });

  @override
  State<TypingAnswerField> createState() => _TypingAnswerFieldState();
}

class _TypingAnswerFieldState extends State<TypingAnswerField> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Auto-focus when widget is first built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.enabled && !widget.isAnswered) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void didUpdateWidget(TypingAnswerField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset text when moving to a new question
    if (!widget.isAnswered && oldWidget.isAnswered) {
      _controller.clear();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (widget.enabled) _focusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    final text = _controller.text.trim();
    if (text.isEmpty || widget.isAnswered) return;
    widget.onSubmitted(text);
  }

  @override
  Widget build(BuildContext context) {
    Color borderColor = AppTheme.textHint(context).withValues(alpha: 0.3);
    Color bgColor = AppTheme.card(context);
    Widget? suffixIcon;

    if (widget.isAnswered) {
      if (widget.isCorrect == true) {
        borderColor = AppColors.successGreen;
        bgColor = AppColors.successGreen.withValues(alpha: 0.08);
        suffixIcon = const Icon(Icons.check_circle_rounded,
            color: AppColors.successGreen, size: 24,);
      } else {
        borderColor = AppColors.errorRed;
        bgColor = AppColors.errorRed.withValues(alpha: 0.08);
        suffixIcon = const Icon(Icons.cancel_rounded,
            color: AppColors.errorRed, size: 24,);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor, width: 2),
          ),
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            enabled: widget.enabled && !widget.isAnswered,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _handleSubmit(),
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppTheme.textPrimary(context),
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: AppTextStyles.bodyMedium.copyWith(
                color: AppTheme.textHint(context),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              suffixIcon: widget.isAnswered
                  ? suffixIcon
                  : IconButton(
                      icon: Icon(
                        Icons.send_rounded,
                        color: AppTheme.primary(context),
                      ),
                      onPressed: _handleSubmit,
                    ),
            ),
          ),
        ),

        // Show correct answer when wrong
        if (widget.isAnswered && widget.isCorrect == false && widget.correctAnswer != null) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.successGreen.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.successGreen.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.lightbulb_rounded,
                    color: AppColors.successGreen, size: 20,),
                const SizedBox(width: 8),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      text: 'Correct answer: ',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppTheme.textSecondary(context),
                      ),
                      children: [
                        TextSpan(
                          text: widget.correctAnswer,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.successGreen,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        // Submit button (visible when not answered)
        if (!widget.isAnswered) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _controller.text.trim().isNotEmpty ? _handleSubmit : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                disabledBackgroundColor: AppColors.textHint.withValues(alpha: 0.2),
              ),
              child: const Text('Check Answer', style: AppTextStyles.button),
            ),
          ),
        ],
      ],
    );
  }
}
