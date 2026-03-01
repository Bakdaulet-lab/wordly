import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../constants/app_theme.dart';
import '../../models/word_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/word_list_provider.dart';
import '../../di/service_locator.dart';
import '../../repositories/stats_repository.dart';
import '../../services/tts_service.dart';

/// Flashcard study mode: swipe through word cards, tap to flip between
/// English and Russian. Tracks cards reviewed in daily stats.
class FlashcardScreen extends StatefulWidget {
  const FlashcardScreen({super.key});

  @override
  State<FlashcardScreen> createState() => _FlashcardScreenState();
}

class _FlashcardScreenState extends State<FlashcardScreen> {
  late PageController _pageController;
  List<WordModel> _words = [];
  int _currentIndex = 0;
  int _cardsReviewed = 0;
  final Set<int> _reviewedIds = {};
  bool _isFlipped = false;
  bool _sessionComplete = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadWords());
  }

  void _loadWords() {
    final allWords = context.read<WordListProvider>().allWords;
    if (allWords.isEmpty) return;

    final shuffled = List<WordModel>.from(allWords)..shuffle(Random());
    setState(() {
      _words = shuffled.take(20).toList(); // Study up to 20 cards per session
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    // Persist reviewed count to daily stats
    _saveStats();
    super.dispose();
  }

  Future<void> _saveStats() async {
    if (_cardsReviewed <= 0) return;
    final userId = context.read<AuthProvider>().user?.id;
    if (userId == null) return;

    try {
      final statsRepo = sl<StatsRepository>();
      await statsRepo.incrementStat(userId, 'words_reviewed', _cardsReviewed);
    } catch (_) {}
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
      _isFlipped = false;
    });

    // Track this card as reviewed
    if (index < _words.length && !_reviewedIds.contains(_words[index].id)) {
      _reviewedIds.add(_words[index].id);
      _cardsReviewed++;
    }

    // Check if complete
    if (index >= _words.length - 1) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted && _currentIndex >= _words.length - 1) {
          setState(() => _sessionComplete = true);
        }
      });
    }
  }

  void _toggleFlip() {
    HapticFeedback.lightImpact();
    setState(() => _isFlipped = !_isFlipped);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background(context),
      appBar: AppBar(
        title: Text(
          _words.isEmpty
              ? 'Flashcards'
              : 'Card ${_currentIndex + 1} of ${_words.length}',
        ),
        backgroundColor: AppTheme.surface(context),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.go('/home'),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.successGreen.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '$_cardsReviewed reviewed',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.successGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: _words.isEmpty
          ? _buildEmptyState()
          : _sessionComplete
              ? _buildSessionComplete()
              : _buildFlashcards(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.style_rounded, size: 64, color: AppColors.textHint),
          const SizedBox(height: 16),
          Text(
            'No words available for flashcards',
            style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textHint),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.go('/home'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Go Home'),
          ),
        ],
      ),
    );
  }

  Widget _buildFlashcards() {
    return Column(
      children: [
        // Progress bar
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _words.isNotEmpty
                  ? (_currentIndex + 1) / _words.length
                  : 0,
              backgroundColor: AppColors.textHint.withValues(alpha: 0.2),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.primary),
              minHeight: 6,
            ),
          ),
        ),

        // Swipe hint
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            'Tap to flip • Swipe to next',
            style: AppTextStyles.caption.copyWith(
              color: AppTheme.textHint(context),
            ),
          ),
        ),

        // Flashcard PageView
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            itemCount: _words.length,
            onPageChanged: _onPageChanged,
            itemBuilder: (context, index) {
              final word = _words[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: _FlashcardView(
                  word: word,
                  isFlipped: index == _currentIndex ? _isFlipped : false,
                  onTap: index == _currentIndex ? _toggleFlip : null,
                ),
              );
            },
          ),
        ),

        // Bottom buttons
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Row(
            children: [
              // Previous
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _currentIndex > 0
                      ? () {
                          _pageController.previousPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        }
                      : null,
                  icon: const Icon(Icons.arrow_back_rounded, size: 18),
                  label: const Text('Prev'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primary(context),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: AppTheme.primary(context)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // TTS
              IconButton(
                onPressed: () => TtsService().speak(_words[_currentIndex].englishWord),
                icon: const Icon(Icons.volume_up_rounded),
                color: AppColors.primary,
                iconSize: 28,
                tooltip: 'Listen',
              ),
              const SizedBox(width: 12),
              // Next
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _currentIndex < _words.length - 1
                      ? () {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        }
                      : null,
                  icon: const Text('Next'),
                  label: const Icon(Icons.arrow_forward_rounded, size: 18),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSessionComplete() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle_rounded,
              size: 80,
              color: AppColors.successGreen,
            )
                .animate()
                .scale(
                  begin: const Offset(0, 0),
                  end: const Offset(1, 1),
                  duration: 600.ms,
                  curve: Curves.elasticOut,
                ),
            const SizedBox(height: 24),
            Text(
              'Session Complete!',
              style: AppTextStyles.heading1.copyWith(
                color: AppTheme.primary(context),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'You reviewed $_cardsReviewed flashcard${_cardsReviewed == 1 ? '' : 's'}.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppTheme.textSecondary(context),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    _sessionComplete = false;
                    _currentIndex = 0;
                    _isFlipped = false;
                    _loadWords();
                  });
                  _pageController.jumpToPage(0);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Study Again', style: AppTextStyles.button),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => context.go('/home'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Go Home',
                  style: AppTextStyles.button.copyWith(color: AppColors.primary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A single flashcard: tap to flip between English front and Russian back.
class _FlashcardView extends StatelessWidget {
  final WordModel word;
  final bool isFlipped;
  final VoidCallback? onTap;

  const _FlashcardView({
    required this.word,
    required this.isFlipped,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween(begin: 0.95, end: 1.0).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOut),
              ),
              child: child,
            ),
          );
        },
        child: isFlipped
            ? _buildBack(context)
            : _buildFront(context),
      ),
    );
  }

  Widget _buildFront(BuildContext context) {
    return Container(
      key: const ValueKey('front'),
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primary(context),
            AppTheme.primary(context).withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary(context).withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.translate_rounded, size: 40, color: Colors.white38),
          const SizedBox(height: 24),
          Text(
            word.englishWord,
            style: AppTextStyles.heading1.copyWith(
              color: Colors.white,
              fontSize: 36,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              word.category,
              style: AppTextStyles.bodySmall.copyWith(
                color: Colors.white70,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 30),
          Text(
            'Tap to reveal translation',
            style: AppTextStyles.caption.copyWith(color: Colors.white54),
          ),
        ],
      ),
    );
  }

  Widget _buildBack(BuildContext context) {
    return Container(
      key: const ValueKey('back'),
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppTheme.card(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.successGreen.withValues(alpha: 0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            word.englishWord,
            style: AppTextStyles.heading3.copyWith(
              color: AppTheme.textSecondary(context),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Divider(),
          const SizedBox(height: 8),
          Text(
            word.russianTranslation,
            style: AppTextStyles.heading1.copyWith(
              color: AppColors.successGreen,
              fontSize: 32,
            ),
            textAlign: TextAlign.center,
          ),
          if (word.exampleSentence != null && word.exampleSentence!.isNotEmpty) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.surface(context),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.format_quote_rounded,
                      size: 16, color: AppTheme.textHint(context),),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      word.exampleSentence!,
                      style: AppTextStyles.bodySmall.copyWith(
                        fontStyle: FontStyle.italic,
                        color: AppTheme.textSecondary(context),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          Text(
            'Tap to show English',
            style: AppTextStyles.caption.copyWith(
              color: AppTheme.textHint(context),
            ),
          ),
        ],
      ),
    );
  }
}
