import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../constants/app_theme.dart';
import '../l10n/app_localizations.dart';

/// Shows a reusable confirmation dialog before destructive actions.
///
/// Returns `true` if the user confirmed, `false` or `null` otherwise.
///
/// [title] – dialog title text.
/// [message] – description of the action being confirmed.
/// [confirmLabel] – text on the confirm button (defaults to localized 'confirm').
/// [cancelLabel] – text on the cancel button (defaults to localized 'cancel').
/// [isDestructive] – when `true` the confirm button uses [AppColors.errorRed].
/// [icon] – optional icon displayed above the title.
Future<bool?> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String? confirmLabel,
  String? cancelLabel,
  bool isDestructive = true,
  IconData? icon,
}) {
  final l = AppLocalizations.of(context);
  return showDialog<bool>(
    context: context,
    builder: (dialogContext) => _ConfirmDialog(
      title: title,
      message: message,
      confirmLabel: confirmLabel ?? l.translate('confirm'),
      cancelLabel: cancelLabel ?? l.cancel,
      isDestructive: isDestructive,
      icon: icon,
    ),
  );
}

class _ConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final bool isDestructive;
  final IconData? icon;

  const _ConfirmDialog({
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.cancelLabel,
    required this.isDestructive,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final confirmColor =
        isDestructive ? AppColors.errorRed : AppTheme.primary(context);

    return AlertDialog(
      backgroundColor: AppTheme.card(context),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      icon: icon != null
          ? Icon(icon, size: 40, color: confirmColor)
          : null,
      title: Text(
        title,
        style: AppTextStyles.heading3.copyWith(
          color: AppTheme.textPrimary(context),
        ),
      ),
      content: Text(
        message,
        style: AppTextStyles.bodyMedium.copyWith(
          color: AppTheme.textSecondary(context),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(
            cancelLabel,
            style: TextStyle(color: AppTheme.textHint(context)),
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: confirmColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(confirmLabel),
        ),
      ],
    );
  }
}
