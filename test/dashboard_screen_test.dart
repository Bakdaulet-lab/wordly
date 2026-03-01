import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:wordly/constants/app_theme.dart';
import 'package:wordly/models/daily_stats_model.dart';
import 'package:wordly/models/word_model.dart';
import 'package:wordly/providers/auth_provider.dart';
import 'package:wordly/providers/profile_provider.dart';
import 'package:wordly/providers/progress_provider.dart';
import 'package:wordly/providers/stats_provider.dart';
import 'package:wordly/providers/word_list_provider.dart';
import 'package:wordly/widgets/shimmer_loading.dart';
import 'package:wordly/screens/dashboard/dashboard_screen.dart';

// ── Mocks ────────────────────────────────────────────────────────────────

class MockAuthProvider extends Mock implements AuthProvider {}

class MockProfileProvider extends Mock implements ProfileProvider {}

class MockStatsProvider extends Mock implements StatsProvider {}

class MockProgressProvider extends Mock implements ProgressProvider {}

class MockWordListProvider extends Mock implements WordListProvider {}

// ── Helpers ──────────────────────────────────────────────────────────────

Widget buildDashboard({
  required MockAuthProvider auth,
  required MockProfileProvider profile,
  required MockStatsProvider stats,
  required MockProgressProvider progress,
  required MockWordListProvider wordList,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthProvider>.value(value: auth),
      ChangeNotifierProvider<ProfileProvider>.value(value: profile),
      ChangeNotifierProvider<StatsProvider>.value(value: stats),
      ChangeNotifierProvider<ProgressProvider>.value(value: progress),
      ChangeNotifierProvider<WordListProvider>.value(value: wordList),
    ],
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      home: const Scaffold(body: DashboardScreen()),
    ),
  );
}

List<WordModel> _sampleWords(int count) => List.generate(
      count,
      (i) => WordModel(
        id: i + 1,
        englishWord: 'word_${i + 1}',
        russianTranslation: 'слово_${i + 1}',
        difficultyLevel: 1,
        category: 'general',
        createdAt: DateTime(2025, 1, 1),
      ),
    );

DailyStatsModel _sampleStats({
  required DateTime date,
  int xpEarned = 0,
}) =>
    DailyStatsModel(
      id: 1,
      userId: 'u1',
      date: date,
      wordsLearned: 0,
      wordsReviewed: 0,
      correctAnswers: 0,
      incorrectAnswers: 0,
      xpEarned: xpEarned,
      sessionDurationSeconds: 0,
    );

/// Pump the widget and advance time so flutter_animate animations complete.
Future<void> pumpDashboard(WidgetTester tester, Widget widget) async {
  await tester.pumpWidget(widget);
  await tester.pump(const Duration(seconds: 1));
}

// ── Tests ────────────────────────────────────────────────────────────────

void main() {
  late MockAuthProvider mockAuth;
  late MockProfileProvider mockProfile;
  late MockStatsProvider mockStats;
  late MockProgressProvider mockProgress;
  late MockWordListProvider mockWordList;

  setUpAll(() {
    Animate.restartOnHotReload = false;
  });

  setUp(() {
    mockAuth = MockAuthProvider();
    mockProfile = MockProfileProvider();
    mockStats = MockStatsProvider();
    mockProgress = MockProgressProvider();
    mockWordList = MockWordListProvider();

    when(() => mockAuth.user).thenReturn(null);
    when(() => mockAuth.addListener(any())).thenReturn(null);
    when(() => mockAuth.removeListener(any())).thenReturn(null);

    when(() => mockProfile.isLoading).thenReturn(false);
    when(() => mockProfile.errorMessage).thenReturn(null);
    when(() => mockProfile.displayName).thenReturn('Alice');
    when(() => mockProfile.level).thenReturn(5);
    when(() => mockProfile.xpProgress).thenReturn(0.6);
    when(() => mockProfile.totalXp).thenReturn(600);
    when(() => mockProfile.xpForNextLevel).thenReturn(1000);
    when(() => mockProfile.currentStreak).thenReturn(7);
    when(() => mockProfile.addListener(any())).thenReturn(null);
    when(() => mockProfile.removeListener(any())).thenReturn(null);

    when(() => mockStats.isLoading).thenReturn(false);
    when(() => mockStats.errorMessage).thenReturn(null);
    when(() => mockStats.todayWordsReviewed).thenReturn(12);
    when(() => mockStats.todayAccuracy).thenReturn(0.85);
    when(() => mockStats.todayXpEarned).thenReturn(120);
    when(() => mockStats.dailyXpGoal).thenReturn(100);
    when(() => mockStats.dailyGoalProgress).thenReturn(1.0);
    when(() => mockStats.dailyGoalReached).thenReturn(true);
    when(() => mockStats.recentStats).thenReturn([]);
    when(() => mockStats.addListener(any())).thenReturn(null);
    when(() => mockStats.removeListener(any())).thenReturn(null);

    when(() => mockProgress.dueCount).thenReturn(3);
    when(() => mockProgress.addListener(any())).thenReturn(null);
    when(() => mockProgress.removeListener(any())).thenReturn(null);

    when(() => mockWordList.allWords).thenReturn(_sampleWords(20));
    when(() => mockWordList.addListener(any())).thenReturn(null);
    when(() => mockWordList.removeListener(any())).thenReturn(null);
  });

  group('DashboardScreen — Profile Summary', () {
    testWidgets('shows display name and level', (tester) async {
      await pumpDashboard(tester, buildDashboard(
        auth: mockAuth, profile: mockProfile, stats: mockStats,
        progress: mockProgress, wordList: mockWordList,
      ),);
      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('Level 5'), findsOneWidget);
    });

    testWidgets('shows avatar initial from display name', (tester) async {
      await pumpDashboard(tester, buildDashboard(
        auth: mockAuth, profile: mockProfile, stats: mockStats,
        progress: mockProgress, wordList: mockWordList,
      ),);
      expect(find.text('A'), findsOneWidget);
    });

    testWidgets('shows streak badge with fire icon when streak > 0',
        (tester) async {
      await pumpDashboard(tester, buildDashboard(
        auth: mockAuth, profile: mockProfile, stats: mockStats,
        progress: mockProgress, wordList: mockWordList,
      ),);
      expect(find.text('7'), findsOneWidget);
      expect(find.byIcon(Icons.local_fire_department_rounded), findsOneWidget);
    });

    testWidgets('hides streak badge when streak is 0', (tester) async {
      when(() => mockProfile.currentStreak).thenReturn(0);
      await pumpDashboard(tester, buildDashboard(
        auth: mockAuth, profile: mockProfile, stats: mockStats,
        progress: mockProgress, wordList: mockWordList,
      ),);
      expect(find.byIcon(Icons.local_fire_department_rounded), findsNothing);
    });

    testWidgets('shows XP total and "Next" label', (tester) async {
      await pumpDashboard(tester, buildDashboard(
        auth: mockAuth, profile: mockProfile, stats: mockStats,
        progress: mockProgress, wordList: mockWordList,
      ),);
      expect(find.text('XP: 600'), findsOneWidget);
      expect(find.text('Next: 1000 XP'), findsOneWidget);
    });

    testWidgets('shows XP progress bar', (tester) async {
      await pumpDashboard(tester, buildDashboard(
        auth: mockAuth, profile: mockProfile, stats: mockStats,
        progress: mockProgress, wordList: mockWordList,
      ),);
      expect(find.byType(LinearProgressIndicator), findsWidgets);
    });

    testWidgets('shows loading shimmer when profile is loading',
        (tester) async {
      when(() => mockProfile.isLoading).thenReturn(true);
      await pumpDashboard(tester, buildDashboard(
        auth: mockAuth, profile: mockProfile, stats: mockStats,
        progress: mockProgress, wordList: mockWordList,
      ),);
      expect(find.byType(ShimmerProfileCard), findsOneWidget);
    });

    testWidgets('shows error card when profile has error', (tester) async {
      when(() => mockProfile.isLoading).thenReturn(false);
      when(() => mockProfile.errorMessage).thenReturn('Network error');
      await pumpDashboard(tester, buildDashboard(
        auth: mockAuth, profile: mockProfile, stats: mockStats,
        progress: mockProgress, wordList: mockWordList,
      ),);
      expect(find.text('Network error'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('shows fallback "?" when display name is empty',
        (tester) async {
      when(() => mockProfile.displayName).thenReturn('');
      await pumpDashboard(tester, buildDashboard(
        auth: mockAuth, profile: mockProfile, stats: mockStats,
        progress: mockProgress, wordList: mockWordList,
      ),);
      expect(find.text('?'), findsOneWidget);
      expect(find.text('Learner'), findsOneWidget);
    });
  });

  group('DashboardScreen — Stat Cards', () {
    testWidgets('displays Reviewed, Accuracy, and XP Earned',
        (tester) async {
      await pumpDashboard(tester, buildDashboard(
        auth: mockAuth, profile: mockProfile, stats: mockStats,
        progress: mockProgress, wordList: mockWordList,
      ),);
      expect(find.text('Reviewed'), findsOneWidget);
      expect(find.text('12'), findsOneWidget);
      expect(find.text('Accuracy'), findsOneWidget);
      expect(find.text('85%'), findsOneWidget);
      expect(find.text('XP Earned'), findsOneWidget);
      expect(find.text('120'), findsOneWidget);
    });

    testWidgets('shows loading shimmer when stats are loading',
        (tester) async {
      when(() => mockStats.isLoading).thenReturn(true);
      await pumpDashboard(tester, buildDashboard(
        auth: mockAuth, profile: mockProfile, stats: mockStats,
        progress: mockProgress, wordList: mockWordList,
      ),);
      expect(find.byType(ShimmerStatCards), findsOneWidget);
    });

    testWidgets('shows stat icons', (tester) async {
      await pumpDashboard(tester, buildDashboard(
        auth: mockAuth, profile: mockProfile, stats: mockStats,
        progress: mockProgress, wordList: mockWordList,
      ),);
      expect(find.byIcon(Icons.menu_book_rounded), findsOneWidget);
      expect(find.byIcon(Icons.track_changes_rounded), findsOneWidget);
      expect(find.byIcon(Icons.star_rounded), findsWidgets);
    });
  });

  group('DashboardScreen — Daily Goal', () {
    testWidgets('shows "Daily Goal" label and XP fraction', (tester) async {
      await pumpDashboard(tester, buildDashboard(
        auth: mockAuth, profile: mockProfile, stats: mockStats,
        progress: mockProgress, wordList: mockWordList,
      ),);
      expect(find.text('Daily Goal'), findsOneWidget);
      expect(find.text('120 / 100 XP'), findsOneWidget);
    });

    testWidgets('shows "Goal reached!" text when goal met', (tester) async {
      await pumpDashboard(tester, buildDashboard(
        auth: mockAuth, profile: mockProfile, stats: mockStats,
        progress: mockProgress, wordList: mockWordList,
      ),);
      expect(find.textContaining('Goal reached'), findsOneWidget);
    });

    testWidgets('hides "Goal reached!" when not met', (tester) async {
      when(() => mockStats.dailyGoalReached).thenReturn(false);
      when(() => mockStats.dailyGoalProgress).thenReturn(0.5);
      when(() => mockStats.todayXpEarned).thenReturn(50);
      await pumpDashboard(tester, buildDashboard(
        auth: mockAuth, profile: mockProfile, stats: mockStats,
        progress: mockProgress, wordList: mockWordList,
      ),);
      expect(find.textContaining('Goal reached'), findsNothing);
    });
  });

  group('DashboardScreen — Word of the Day', () {
    testWidgets('renders section with deterministic word', (tester) async {
      await pumpDashboard(tester, buildDashboard(
        auth: mockAuth, profile: mockProfile, stats: mockStats,
        progress: mockProgress, wordList: mockWordList,
      ),);
      expect(find.text('Word of the Day'), findsOneWidget);

      final now = DateTime.now();
      final daySeed = now.year * 10000 + now.month * 100 + now.day;
      final index = Random(daySeed).nextInt(20);
      expect(find.text('word_${index + 1}'), findsOneWidget);
      expect(find.text('слово_${index + 1}'), findsOneWidget);
    });

    testWidgets('hides when no words available', (tester) async {
      when(() => mockWordList.allWords).thenReturn([]);
      await pumpDashboard(tester, buildDashboard(
        auth: mockAuth, profile: mockProfile, stats: mockStats,
        progress: mockProgress, wordList: mockWordList,
      ),);
      expect(find.text('Word of the Day'), findsNothing);
    });
  });

  group('DashboardScreen — Review Card', () {
    testWidgets('shows due count when words are due', (tester) async {
      await pumpDashboard(tester, buildDashboard(
        auth: mockAuth, profile: mockProfile, stats: mockStats,
        progress: mockProgress, wordList: mockWordList,
      ),);
      expect(find.text('Words Due for Review'), findsOneWidget);
      expect(find.text('3 words ready to review'), findsOneWidget);
    });

    testWidgets('shows "No words due" when dueCount is 0', (tester) async {
      when(() => mockProgress.dueCount).thenReturn(0);
      await pumpDashboard(tester, buildDashboard(
        auth: mockAuth, profile: mockProfile, stats: mockStats,
        progress: mockProgress, wordList: mockWordList,
      ),);
      expect(find.text('No words due right now. Great job!'), findsOneWidget);
    });

    testWidgets('shows singular text for 1 word', (tester) async {
      when(() => mockProgress.dueCount).thenReturn(1);
      await pumpDashboard(tester, buildDashboard(
        auth: mockAuth, profile: mockProfile, stats: mockStats,
        progress: mockProgress, wordList: mockWordList,
      ),);
      expect(find.text('1 word ready to review'), findsOneWidget);
    });
  });

  group('DashboardScreen — Weekly Chart', () {
    testWidgets('hides chart when recentStats is empty', (tester) async {
      await pumpDashboard(tester, buildDashboard(
        auth: mockAuth, profile: mockProfile, stats: mockStats,
        progress: mockProgress, wordList: mockWordList,
      ),);
      expect(find.text('Weekly XP'), findsNothing);
    });

    testWidgets('shows Weekly XP heading when recentStats is non-empty',
        (tester) async {
      when(() => mockStats.recentStats).thenReturn([
        _sampleStats(date: DateTime.now(), xpEarned: 50),
      ]);
      await pumpDashboard(tester, buildDashboard(
        auth: mockAuth, profile: mockProfile, stats: mockStats,
        progress: mockProgress, wordList: mockWordList,
      ),);
      expect(find.text('Weekly XP'), findsOneWidget);
    });
  });

  group('DashboardScreen — static navigation cards', () {
    testWidgets('shows Analytics & Charts card', (tester) async {
      await pumpDashboard(tester, buildDashboard(
        auth: mockAuth, profile: mockProfile, stats: mockStats,
        progress: mockProgress, wordList: mockWordList,
      ),);
      expect(find.text('Analytics & Charts'), findsOneWidget);
    });

    testWidgets('shows Word Lifter card', (tester) async {
      await pumpDashboard(tester, buildDashboard(
        auth: mockAuth, profile: mockProfile, stats: mockStats,
        progress: mockProgress, wordList: mockWordList,
      ),);
      expect(find.textContaining('Word Lifter'), findsOneWidget);
    });
  });
}
