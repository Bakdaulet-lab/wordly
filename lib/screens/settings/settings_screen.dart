import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../constants/app_theme.dart';
import '../../providers/theme_provider.dart';
import '../../providers/locale_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/connectivity_provider.dart';
import '../../providers/word_list_provider.dart';
import '../../services/sync_service.dart';
import '../../di/service_locator.dart';
import '../../services/tts_service.dart';
import '../../l10n/app_localizations.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppTheme.background(context),
      appBar: AppBar(
        title: Text(l.translate('settings')),
        backgroundColor: AppTheme.surface(context),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader(context, l.translate('appearance')),
          _buildThemeCard(context),
          const SizedBox(height: 24),
          _buildSectionHeader(context, l.translate('language')),
          _buildLanguageCard(context),
          const SizedBox(height: 24),
          _buildSectionHeader(context, l.translate('speechRate')),
          _buildSpeechRateCard(context),
          const SizedBox(height: 24),
          _buildSectionHeader(context, 'Quiz Settings'),
          _buildQuizModeCard(context),
          const SizedBox(height: 24),
          _buildSectionHeader(context, l.translate('notifications')),
          _buildNotificationCard(context),
          const SizedBox(height: 12),
          _buildWotdNotificationCard(context),
          const SizedBox(height: 24),
          _buildSectionHeader(context, l.translate('dataSync')),
          _buildSyncCard(context),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: AppTextStyles.heading3.copyWith(
          color: AppTheme.textPrimary(context),
        ),
      ),
    );
  }

  // ── Theme settings ─────────────────────────────────────────────────

  Widget _buildThemeCard(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return Card(
          color: AppTheme.card(context),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Theme Mode', style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary(context),
                ),),
                const SizedBox(height: 12),
                _buildThemeOption(
                  context,
                  themeProvider,
                  AppThemeMode.system,
                  'System',
                  'Follow device theme',
                  Icons.settings_brightness_rounded,
                ),
                _buildThemeOption(
                  context,
                  themeProvider,
                  AppThemeMode.light,
                  'Light',
                  'Always use light theme',
                  Icons.light_mode_rounded,
                ),
                _buildThemeOption(
                  context,
                  themeProvider,
                  AppThemeMode.dark,
                  'Dark',
                  'Always use dark theme',
                  Icons.dark_mode_rounded,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildThemeOption(
    BuildContext context,
    ThemeProvider provider,
    AppThemeMode mode,
    String title,
    String subtitle,
    IconData icon,
  ) {
    final isSelected = provider.themeMode == mode;
    return RadioListTile<AppThemeMode>(
      value: mode,
      groupValue: provider.themeMode,
      onChanged: (value) {
        if (value != null) provider.setThemeMode(value);
      },
      title: Row(
        children: [
          Icon(icon,
              size: 20,
              color: isSelected
                  ? AppTheme.primary(context)
                  : AppTheme.textHint(context),),
          const SizedBox(width: 8),
          Text(title, style: TextStyle(
            color: AppTheme.textPrimary(context),
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),),
        ],
      ),
      subtitle: Text(subtitle, style: TextStyle(
        color: AppTheme.textSecondary(context),
        fontSize: 12,
      ),),
      activeColor: AppTheme.primary(context),
      visualDensity: VisualDensity.compact,
      contentPadding: EdgeInsets.zero,
    );
  }

  // ── Notification settings ──────────────────────────────────────────

  Widget _buildLanguageCard(BuildContext context) {
    return Consumer<LocaleProvider>(
      builder: (context, localeProvider, _) {
        return Card(
          color: AppTheme.card(context),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Interface Language', style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary(context),
                ),),
                const SizedBox(height: 12),
                RadioListTile<String>(
                  value: 'en',
                  groupValue: localeProvider.locale.languageCode,
                  onChanged: (_) => localeProvider.setLocale(const Locale('en')),
                  title: Row(
                    children: [
                      Icon(Icons.language, size: 20,
                        color: localeProvider.isEnglish
                            ? AppTheme.primary(context)
                            : AppTheme.textHint(context),),
                      const SizedBox(width: 8),
                      Text('English', style: TextStyle(
                        color: AppTheme.textPrimary(context),
                        fontWeight: localeProvider.isEnglish ? FontWeight.w600 : FontWeight.normal,
                      ),),
                    ],
                  ),
                  activeColor: AppTheme.primary(context),
                  visualDensity: VisualDensity.compact,
                  contentPadding: EdgeInsets.zero,
                ),
                RadioListTile<String>(
                  value: 'ru',
                  groupValue: localeProvider.locale.languageCode,
                  onChanged: (_) => localeProvider.setLocale(const Locale('ru')),
                  title: Row(
                    children: [
                      Icon(Icons.language, size: 20,
                        color: localeProvider.isRussian
                            ? AppTheme.primary(context)
                            : AppTheme.textHint(context),),
                      const SizedBox(width: 8),
                      Text('Русский', style: TextStyle(
                        color: AppTheme.textPrimary(context),
                        fontWeight: localeProvider.isRussian ? FontWeight.w600 : FontWeight.normal,
                      ),),
                    ],
                  ),
                  activeColor: AppTheme.primary(context),
                  visualDensity: VisualDensity.compact,
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSpeechRateCard(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        final rate = themeProvider.speechRate;
        final label = rate < 0.3
            ? 'Slow'
            : rate < 0.6
                ? 'Normal'
                : 'Fast';
        return Card(
          color: AppTheme.card(context),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('TTS Speech Rate', style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary(context),
                ),),
                const SizedBox(height: 4),
                Text(
                  'Adjust the pronunciation speed for word audio',
                  style: TextStyle(
                    color: AppTheme.textSecondary(context),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.slow_motion_video, size: 20,
                        color: AppTheme.textHint(context),),
                    Expanded(
                      child: Slider(
                        value: rate,
                        min: 0.1,
                        max: 1.0,
                        divisions: 9,
                        label: '${rate.toStringAsFixed(1)} ($label)',
                        activeColor: AppTheme.primary(context),
                        onChanged: (value) {
                          themeProvider.setSpeechRate(value);
                          sl<TtsService>().setSpeechRate(value);
                        },
                      ),
                    ),
                    Icon(Icons.speed, size: 20,
                        color: AppTheme.textHint(context),),
                  ],
                ),
                Center(
                  child: Text(
                    '$label (${rate.toStringAsFixed(1)})',
                    style: TextStyle(
                      color: AppTheme.textSecondary(context),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Quiz mode settings ────────────────────────────────────────────

  Widget _buildQuizModeCard(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return Card(
          color: AppTheme.card(context),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Answer Mode',
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary(context),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Choose how you answer quiz questions',
                  style: TextStyle(
                    color: AppTheme.textSecondary(context),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 12),
                RadioListTile<QuizMode>(
                  value: QuizMode.multipleChoice,
                  groupValue: themeProvider.quizMode,
                  onChanged: (v) {
                    if (v != null) themeProvider.setQuizMode(v);
                  },
                  title: Row(
                    children: [
                      Icon(
                        Icons.grid_view_rounded,
                        size: 20,
                        color: !themeProvider.isTypingQuiz
                            ? AppTheme.primary(context)
                            : AppTheme.textHint(context),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Multiple Choice',
                        style: TextStyle(
                          color: AppTheme.textPrimary(context),
                          fontWeight: !themeProvider.isTypingQuiz
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                  subtitle: Text(
                    'Pick the correct translation from 4 options',
                    style: TextStyle(
                      color: AppTheme.textSecondary(context),
                      fontSize: 12,
                    ),
                  ),
                  activeColor: AppTheme.primary(context),
                  visualDensity: VisualDensity.compact,
                  contentPadding: EdgeInsets.zero,
                ),
                RadioListTile<QuizMode>(
                  value: QuizMode.typing,
                  groupValue: themeProvider.quizMode,
                  onChanged: (v) {
                    if (v != null) themeProvider.setQuizMode(v);
                  },
                  title: Row(
                    children: [
                      Icon(
                        Icons.keyboard_rounded,
                        size: 20,
                        color: themeProvider.isTypingQuiz
                            ? AppTheme.primary(context)
                            : AppTheme.textHint(context),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Typing',
                        style: TextStyle(
                          color: AppTheme.textPrimary(context),
                          fontWeight: themeProvider.isTypingQuiz
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                  subtitle: Text(
                    'Type the translation — minor typos accepted for long words',
                    style: TextStyle(
                      color: AppTheme.textSecondary(context),
                      fontSize: 12,
                    ),
                  ),
                  activeColor: AppTheme.primary(context),
                  visualDensity: VisualDensity.compact,
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Notification settings (original) ──────────────────────────────

  Widget _buildNotificationCard(BuildContext context) {
    return Consumer<NotificationProvider>(
      builder: (context, notifProvider, _) {
        return Card(
          color: AppTheme.card(context),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Daily Study Reminder',
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary(context),
                      ),),
                  subtitle: Text(
                    notifProvider.reminderEnabled
                        ? 'Reminder at ${_formatTime(notifProvider.reminderTime)}'
                        : 'Get notified to practice every day',
                    style: TextStyle(color: AppTheme.textSecondary(context)),
                  ),
                  value: notifProvider.reminderEnabled,
                  onChanged: (_) => notifProvider.toggleReminder(),
                  activeColor: AppTheme.primary(context),
                ),
                if (notifProvider.reminderEnabled) ...[
                  const Divider(),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.access_time,
                        color: AppTheme.primary(context),),
                    title: Text('Reminder Time', style: TextStyle(
                      color: AppTheme.textPrimary(context),
                    ),),
                    trailing: Text(
                      _formatTime(notifProvider.reminderTime),
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: AppTheme.primary(context),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: notifProvider.reminderTime,
                      );
                      if (picked != null) {
                        notifProvider.setReminderTime(picked);
                      }
                    },
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Word of the Day notification settings ──────────────────────────

  Widget _buildWotdNotificationCard(BuildContext context) {
    return Consumer2<NotificationProvider, WordListProvider>(
      builder: (context, notifProvider, wordProvider, _) {
        final words = wordProvider.allWords;
        return Card(
          color: AppTheme.card(context),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'Word of the Day Notification',
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary(context),
                    ),
                  ),
                  subtitle: Text(
                    notifProvider.wotdEnabled
                        ? 'Daily word at ${_formatTime(notifProvider.wotdTime)}'
                        : 'Get a new word every morning',
                    style: TextStyle(color: AppTheme.textSecondary(context)),
                  ),
                  value: notifProvider.wotdEnabled,
                  onChanged: (_) => notifProvider.toggleWotd(words),
                  activeColor: AppTheme.primary(context),
                ),
                if (notifProvider.wotdEnabled) ...[
                  const Divider(),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.access_time,
                        color: AppTheme.primary(context),),
                    title: Text(
                      'Notification Time',
                      style: TextStyle(
                        color: AppTheme.textPrimary(context),
                      ),
                    ),
                    trailing: Text(
                      _formatTime(notifProvider.wotdTime),
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: AppTheme.primary(context),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: notifProvider.wotdTime,
                      );
                      if (picked != null) {
                        notifProvider.setWotdTime(picked, words);
                      }
                    },
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Sync settings ──────────────────────────────────────────────────

  Widget _buildSyncCard(BuildContext context) {
    return Consumer<ConnectivityProvider>(
      builder: (context, connProvider, _) {
        final statusText = switch (connProvider.syncStatus) {
          SyncStatus.synced => 'All data synced',
          SyncStatus.syncing => 'Syncing...',
          SyncStatus.error => 'Sync error',
          SyncStatus.offline => 'Offline — changes saved locally',
        };
        final statusColor = switch (connProvider.syncStatus) {
          SyncStatus.synced => AppColors.successGreen,
          SyncStatus.syncing => AppColors.xpGold,
          SyncStatus.error => AppColors.errorRed,
          SyncStatus.offline => AppColors.streakOrange,
        };

        return Card(
          color: AppTheme.card(context),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      connProvider.isOnline
                          ? Icons.cloud_done_rounded
                          : Icons.cloud_off_rounded,
                      color: connProvider.isOnline
                          ? AppColors.successGreen
                          : AppColors.streakOrange,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      connProvider.isOnline ? 'Online' : 'Offline',
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary(context),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(statusText, style: TextStyle(
                      color: AppTheme.textSecondary(context),
                    ),),
                  ],
                ),
                if (connProvider.lastSync != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Last synced: ${_formatDateTime(connProvider.lastSync!)}',
                    style: AppTextStyles.caption.copyWith(
                      color: AppTheme.textHint(context),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.sync_rounded),
                    label: const Text('Sync Now'),
                    onPressed: connProvider.isOnline
                        ? () => connProvider.syncNow()
                        : null,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
