import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'constants/supabase_constants.dart';
import 'di/service_locator.dart';
import 'providers/auth_provider.dart';
import 'providers/profile_provider.dart';
import 'providers/word_list_provider.dart';
import 'providers/quiz_provider.dart';
import 'providers/progress_provider.dart';
import 'providers/achievement_provider.dart';
import 'providers/stats_provider.dart';
import 'providers/analytics_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/locale_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/connectivity_provider.dart';
import 'providers/leaderboard_provider.dart';
import 'services/connectivity_service.dart';
import 'services/sync_service.dart';
import 'services/notification_service.dart';
import 'services/tts_service.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Global error handlers to prevent silent crashes in release mode
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('FlutterError: ${details.exception}');
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Uncaught platform error: $error\n$stack');
    return true;
  };

  // Validate that Supabase credentials were supplied via --dart-define
  if (!SupabaseConstants.isConfigured) {
    debugPrint(
      'ERROR: Supabase credentials missing.\n'
      'Run with: flutter run '
      '--dart-define=SUPABASE_URL=<url> '
      '--dart-define=SUPABASE_ANON_KEY=<key>\n'
      'Or use: flutter run --dart-define-from-file=.env',
    );
    runApp(const _InitErrorApp());
    return;
  }

  try {
    await Supabase.initialize(
      url: SupabaseConstants.supabaseUrl,
      anonKey: SupabaseConstants.supabaseAnonKey,
    );
  } catch (e) {
    debugPrint('Supabase initialization failed: $e');
    runApp(const _InitErrorApp());
    return;
  }

  // Register all services and repositories
  setupServiceLocator();

  final prefs = await SharedPreferences.getInstance();
  final onboardingComplete = prefs.getBool('onboarding_complete') ?? false;

  // Initialize theme provider
  final themeProvider = ThemeProvider();
  await themeProvider.init();

  // Initialize locale provider
  final localeProvider = LocaleProvider();
  await localeProvider.init();

  // Sync TTS speech rate from saved preference
  final ttsService = sl<TtsService>();
  await ttsService.setSpeechRate(themeProvider.speechRate);

  // Initialize connectivity & sync services
  final connectivityService = sl<ConnectivityService>();
  await connectivityService.init();
  final syncService = sl<SyncService>();
  syncService.start();

  // Initialize notification service
  final notificationService = sl<NotificationService>();
  await notificationService.init();
  await notificationService.restoreReminder();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(create: (_) => WordListProvider()),
        ChangeNotifierProvider(create: (_) => QuizProvider()),
        ChangeNotifierProvider(create: (_) => ProgressProvider()),
        ChangeNotifierProvider(create: (_) => AchievementProvider()),
        ChangeNotifierProvider(create: (_) => StatsProvider()),
        ChangeNotifierProvider(create: (_) => AnalyticsProvider()),
        ChangeNotifierProvider.value(value: themeProvider),
        ChangeNotifierProvider.value(value: localeProvider),
        ChangeNotifierProvider(
          create: (_) => NotificationProvider(notificationService),
        ),
        ChangeNotifierProvider(
          create: (_) =>
              ConnectivityProvider(connectivityService, syncService),
        ),
        ChangeNotifierProvider(create: (_) => LeaderboardProvider()),
      ],
      child: MyApp(onboardingComplete: onboardingComplete),
    ),
  );
}

/// Fallback app displayed when Supabase fails to initialize (e.g. no network).
class _InitErrorApp extends StatelessWidget {
  const _InitErrorApp();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.cloud_off_rounded, size: 64, color: Colors.red),
                SizedBox(height: 16),
                Text(
                  'Failed to connect to server',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8),
                Text(
                  'Please check your internet connection and restart the app.',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
