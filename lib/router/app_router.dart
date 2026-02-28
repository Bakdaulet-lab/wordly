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
import '../screens/onboarding/onboarding_screen.dart';

Page<void> _fadeTransition(GoRouterState state, Widget child) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(opacity: animation, child: child);
    },
    transitionDuration: const Duration(milliseconds: 200),
  );
}

Page<void> _slideUpTransition(GoRouterState state, Widget child) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final offsetAnimation = Tween<Offset>(
        begin: const Offset(0, 0.15),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut));
      return SlideTransition(
        position: offsetAnimation,
        child: FadeTransition(opacity: animation, child: child),
      );
    },
    transitionDuration: const Duration(milliseconds: 250),
  );
}

GoRouter createRouter(BuildContext context, {required bool onboardingComplete}) {
  final authProvider = context.read<AuthProvider>();

  return GoRouter(
    initialLocation: onboardingComplete ? '/login' : '/onboarding',
    redirect: (context, state) {
      final isAuthenticated = authProvider.isAuthenticated;
      final isOnAuth = state.matchedLocation == '/login' ||
          state.matchedLocation == '/signup';
      final isOnboarding = state.matchedLocation == '/onboarding';

      // Let onboarding pass through
      if (isOnboarding) return null;

      if (!isAuthenticated && !isOnAuth) return '/login';
      if (isAuthenticated && isOnAuth) return '/home';
      return null;
    },
    routes: [
      GoRoute(
        path: '/onboarding',
        pageBuilder: (context, state) =>
            _fadeTransition(state, const OnboardingScreen()),
      ),
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) =>
            _fadeTransition(state, const LoginScreen()),
      ),
      GoRoute(
        path: '/signup',
        pageBuilder: (context, state) =>
            _fadeTransition(state, const SignupScreen()),
      ),
      GoRoute(
        path: '/home',
        pageBuilder: (context, state) =>
            _fadeTransition(state, const HomeScreen()),
      ),
      GoRoute(
        path: '/words',
        pageBuilder: (context, state) =>
            _fadeTransition(state, const WordListScreen()),
      ),
      GoRoute(
        path: '/words/:id',
        pageBuilder: (context, state) {
          final wordId = int.tryParse(state.pathParameters['id'] ?? '');
          if (wordId == null) {
            return _fadeTransition(state, const HomeScreen());
          }
          return _slideUpTransition(state, WordDetailScreen(wordId: wordId));
        },
      ),
      GoRoute(
        path: '/quiz',
        pageBuilder: (context, state) =>
            _slideUpTransition(state, const QuizScreen()),
      ),
      GoRoute(
        path: '/quiz-result',
        pageBuilder: (context, state) =>
            _fadeTransition(state, const QuizResultScreen()),
      ),
      GoRoute(
        path: '/review',
        pageBuilder: (context, state) =>
            _slideUpTransition(state, const ReviewScreen()),
      ),
      GoRoute(
        path: '/achievements',
        pageBuilder: (context, state) =>
            _fadeTransition(state, const AchievementsScreen()),
      ),
      GoRoute(
        path: '/profile',
        pageBuilder: (context, state) =>
            _fadeTransition(state, const ProfileScreen()),
      ),
    ],
  );
}
