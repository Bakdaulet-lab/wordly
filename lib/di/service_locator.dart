import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/achievement_service.dart';
import '../services/auth_service.dart';
import '../services/daily_goal_service.dart';
import '../services/favorites_service.dart';
import '../services/profile_service.dart';
import '../services/progress_service.dart';
import '../services/quiz_service.dart';
import '../services/stats_service.dart';
import '../services/tts_service.dart';
import '../services/word_service.dart';
import '../services/xp_service.dart';
import '../services/local_database.dart';
import '../services/connectivity_service.dart';
import '../services/sync_service.dart';
import '../services/notification_service.dart';
import '../services/leaderboard_service.dart';
import '../services/offline_cache_service.dart';
import '../services/word_cache_service.dart';
import '../services/export_service.dart';

import '../services/interfaces/interfaces.dart';

import '../repositories/auth_repository.dart';
import '../repositories/word_repository.dart';
import '../repositories/profile_repository.dart';
import '../repositories/progress_repository.dart';
import '../repositories/quiz_repository.dart';
import '../repositories/stats_repository.dart';
import '../repositories/achievement_repository.dart';
import '../repositories/leaderboard_repository.dart';

/// Global service locator instance.
final GetIt sl = GetIt.instance;

/// Register all services and repositories.
///
/// Must be called once during app startup (before [runApp]).
void setupServiceLocator() {
  // ── External dependencies ──────────────────────────────────────────
  sl.registerLazySingleton<SupabaseClient>(
    () => Supabase.instance.client,
  );

  // ── Services (data-access layer) ──────────────────────────────────
  sl.registerLazySingleton<AuthService>(
    () => AuthService(sl<SupabaseClient>()),
  );
  sl.registerLazySingleton<ProfileService>(
    () => ProfileService(sl<SupabaseClient>()),
  );
  sl.registerLazySingleton<WordService>(
    () => WordService(sl<SupabaseClient>()),
  );
  sl.registerLazySingleton<ProgressService>(
    () => ProgressService(sl<SupabaseClient>()),
  );
  sl.registerLazySingleton<StatsService>(
    () => StatsService(sl<SupabaseClient>()),
  );
  sl.registerLazySingleton<AchievementService>(
    () => AchievementService(sl<SupabaseClient>()),
  );
  sl.registerLazySingleton<XpService>(
    () => XpService(sl<SupabaseClient>()),
  );
  sl.registerLazySingleton<QuizService>(() => QuizService());
  sl.registerLazySingleton<DailyGoalService>(() => DailyGoalService());
  sl.registerLazySingleton<FavoritesService>(() => FavoritesService());
  sl.registerLazySingleton<TtsService>(() => TtsService());

  // ── Interface aliases (for testability / DI by contract) ──────────
  sl.registerLazySingleton<IAuthService>(() => sl<AuthService>());
  sl.registerLazySingleton<IWordService>(() => sl<WordService>());
  sl.registerLazySingleton<IProfileService>(() => sl<ProfileService>());
  sl.registerLazySingleton<IProgressService>(() => sl<ProgressService>());
  sl.registerLazySingleton<IQuizService>(() => sl<QuizService>());
  sl.registerLazySingleton<IXpService>(() => sl<XpService>());
  sl.registerLazySingleton<IStatsService>(() => sl<StatsService>());
  sl.registerLazySingleton<IAchievementService>(
    () => sl<AchievementService>(),
  );

  // ── Offline-first & sync services ─────────────────────────────────
  sl.registerLazySingleton<LocalDatabase>(() => LocalDatabase());
  sl.registerLazySingleton<ConnectivityService>(() => ConnectivityService());
  sl.registerLazySingleton<SyncService>(
    () => SyncService(
      sl<LocalDatabase>(),
      sl<ConnectivityService>(),
      sl<SupabaseClient>(),
    ),
  );

  // ── Notification service ──────────────────────────────────────────
  sl.registerLazySingleton<NotificationService>(() => NotificationService());

  // ── Offline cache service ─────────────────────────────────────────
  sl.registerLazySingleton<OfflineCacheService>(
    () => OfflineCacheService(
      sl<LocalDatabase>(),
      sl<ConnectivityService>(),
    ),
  );

  // ── Word cache service ────────────────────────────────────────────
  sl.registerLazySingleton<WordCacheService>(
    () => WordCacheService(sl<LocalDatabase>()),
  );

  // ── Export service ────────────────────────────────────────────────
  sl.registerLazySingleton<ExportService>(() => ExportService());

  // ── Leaderboard service ───────────────────────────────────────────
  sl.registerLazySingleton<LeaderboardService>(
    () => LeaderboardService(sl<SupabaseClient>()),
  );

  // ── Repositories (business-logic layer) ───────────────────────────
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepository(sl<AuthService>()),
  );
  sl.registerLazySingleton<ProfileRepository>(
    () => ProfileRepository(sl<ProfileService>()),
  );
  sl.registerLazySingleton<WordRepository>(
    () => WordRepository(sl<WordService>(), sl<FavoritesService>()),
  );
  sl.registerLazySingleton<ProgressRepository>(
    () => ProgressRepository(
      sl<ProgressService>(),
      sl<XpService>(),
      sl<StatsService>(),
    ),
  );
  sl.registerLazySingleton<QuizRepository>(
    () => QuizRepository(
      sl<QuizService>(),
      sl<ProgressService>(),
      sl<XpService>(),
      sl<StatsService>(),
    ),
  );
  sl.registerLazySingleton<StatsRepository>(
    () => StatsRepository(sl<StatsService>(), sl<DailyGoalService>()),
  );
  sl.registerLazySingleton<AchievementRepository>(
    () => AchievementRepository(sl<AchievementService>()),
  );
  sl.registerLazySingleton<LeaderboardRepository>(
    () => LeaderboardRepository(sl<LeaderboardService>()),
  );
}
