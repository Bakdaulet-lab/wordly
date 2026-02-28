import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/word_list_provider.dart';
import '../../providers/stats_provider.dart';
import '../../providers/progress_provider.dart';
import '../../providers/achievement_provider.dart';
import '../../providers/quiz_provider.dart';
import '../dashboard/dashboard_screen.dart';
import '../words/word_list_screen.dart';
import '../profile/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // Defer data loading to after the first frame to avoid
    // "setState() called during build" from provider notifications.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    final userId = context.read<AuthProvider>().user?.id;
    if (userId == null) return;

    final profileProvider = context.read<ProfileProvider>();
    final wordListProvider = context.read<WordListProvider>();
    final statsProvider = context.read<StatsProvider>();
    final progressProvider = context.read<ProgressProvider>();
    final achievementProvider = context.read<AchievementProvider>();

    await Future.wait([
      profileProvider.loadProfile(userId),
      wordListProvider.loadWords(),
      statsProvider.loadStats(userId),
      progressProvider.refreshDueCount(userId),
      achievementProvider.loadAchievements(userId),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      const DashboardScreen(),
      const WordListScreen(),
      _buildQuizTab(),
      const ProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textHint,
        selectedLabelStyle: AppTextStyles.caption.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: AppTextStyles.caption,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_rounded),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book_rounded),
            label: 'Words',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.quiz_rounded),
            label: 'Quiz',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildQuizTab() {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.quiz_rounded,
                size: 80,
                color: AppColors.primary,
              ),
              const SizedBox(height: 24),
              Text(
                'Vocabulary Quiz',
                style: AppTextStyles.heading1.copyWith(
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Test your knowledge with a quick quiz session.\n'
                'Answer questions about word translations and earn XP!',
                style: AppTextStyles.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => context.go('/quiz'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Start Quiz', style: AppTextStyles.button),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => _showDifficultyPicker(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Quiz by Difficulty',
                    style: AppTextStyles.button.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDifficultyPicker() {
    final difficulties = [
      {'level': 1, 'label': 'Beginner', 'color': AppColors.difficultyBeginner},
      {'level': 2, 'label': 'Easy', 'color': AppColors.difficultyEasy},
      {'level': 3, 'label': 'Medium', 'color': AppColors.difficultyMedium},
      {'level': 4, 'label': 'Hard', 'color': AppColors.difficultyHard},
      {'level': 5, 'label': 'Expert', 'color': AppColors.difficultyExpert},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Choose Difficulty', style: AppTextStyles.heading3),
                const SizedBox(height: 16),
                ...difficulties.map((d) {
                  final level = d['level'] as int;
                  final label = d['label'] as String;
                  final color = d['color'] as Color;
                  final allWords = context.read<WordListProvider>().allWords;
                  final count = allWords.where((w) => w.difficultyLevel == level).length;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: InkWell(
                      onTap: count >= 4
                          ? () {
                              Navigator.pop(ctx);
                              _startDifficultyQuiz(level);
                            }
                          : null,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          vertical: 14,
                          horizontal: 16,
                        ),
                        decoration: BoxDecoration(
                          color: count >= 4
                              ? color.withValues(alpha: 0.1)
                              : AppColors.textHint.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: count >= 4
                                ? color.withValues(alpha: 0.3)
                                : AppColors.textHint.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              label,
                              style: AppTextStyles.bodyLarge.copyWith(
                                fontWeight: FontWeight.w600,
                                color: count >= 4
                                    ? AppColors.textPrimary
                                    : AppColors.textHint,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '$count words',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textHint,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  void _startDifficultyQuiz(int difficulty) {
    final allWords = context.read<WordListProvider>().allWords;
    final filtered = allWords.where((w) => w.difficultyLevel == difficulty).toList();
    final quizProvider = context.read<QuizProvider>();
    quizProvider.startQuizWithWords(filtered, allWords);
    context.go('/quiz');
  }
}
