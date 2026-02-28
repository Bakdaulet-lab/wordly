import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/words/word_list_screen.dart';
import '../screens/words/word_detail_screen.dart';
import '../screens/quiz/quiz_screen.dart';
import '../screens/quiz/quiz_result_screen.dart';
import '../screens/progress/review_screen.dart';
import '../screens/achievements/achievements_screen.dart';
import '../screens/profile/profile_screen.dart';

GoRouter createRouter(BuildContext context) {
  final authProvider = context.read<AuthProvider>();

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final isAuthenticated = authProvider.isAuthenticated;
      final isOnAuth = state.matchedLocation == '/login' ||
          state.matchedLocation == '/signup';

      if (!isAuthenticated && !isOnAuth) return '/login';
      if (isAuthenticated && isOnAuth) return '/home';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/words',
        builder: (context, state) => const WordListScreen(),
      ),
      GoRoute(
        path: '/words/:id',
        builder: (context, state) {
          final wordId = int.parse(state.pathParameters['id']!);
          return WordDetailScreen(wordId: wordId);
        },
      ),
      GoRoute(
        path: '/quiz',
        builder: (context, state) => const QuizScreen(),
      ),
      GoRoute(
        path: '/quiz-result',
        builder: (context, state) => const QuizResultScreen(),
      ),
      GoRoute(
        path: '/review',
        builder: (context, state) => const ReviewScreen(),
      ),
      GoRoute(
        path: '/achievements',
        builder: (context, state) => const AchievementsScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
    ],
  );
}
