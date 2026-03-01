import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../models/word_lifter_phase.dart';
import '../../providers/word_lifter_provider.dart';
import '../../providers/word_list_provider.dart';
import 'widgets/barbell_widget.dart';
import 'widgets/character_widget.dart';
import 'widgets/combo_progress_bar.dart';
import 'widgets/game_hud_widget.dart';
import 'widgets/game_over_card.dart';
import 'widgets/gym_background_widget.dart';
import 'widgets/quiz_card_widget.dart';
import 'widgets/rep_result_overlay.dart';

/// The main screen for the Word Lifter gym mini-game.
class WordLifterScreen extends StatefulWidget {
  const WordLifterScreen({super.key});

  @override
  State<WordLifterScreen> createState() => _WordLifterScreenState();
}

class _WordLifterScreenState extends State<WordLifterScreen> {
  @override
  void dispose() {
    // Reset provider so it's clean for next time
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) return;
      // Provider already disposed if screen removed from tree
    });
    super.dispose();
  }

  void _startGame() {
    final allWords = context.read<WordListProvider>().allWords;
    if (allWords.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Need at least 4 words to play. Add more words first!'),
        ),
      );
      return;
    }
    context.read<WordLifterProvider>().startGame(allWords);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white),
          onPressed: () {
            context.read<WordLifterProvider>().reset();
            context.pop();
          },
        ),
        title: const Text(
          'Word Lifter',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Consumer<WordLifterProvider>(
        builder: (context, provider, _) {
          return Stack(
            children: [
              // Layer 1: Background
              const GymBackgroundWidget(),

              // Layer 2: Game content based on phase
              _buildPhaseContent(provider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPhaseContent(WordLifterProvider provider) {
    switch (provider.gamePhase) {
      case WordLifterPhase.ready:
        return _buildReadyScreen();
      case WordLifterPhase.playing:
      case WordLifterPhase.repSuccess:
      case WordLifterPhase.repFail:
        return _buildGameplayScreen(provider);
      case WordLifterPhase.finished:
        return _buildFinishedScreen(provider);
    }
  }

  // ─── Ready screen ─────────────────────────────────────────────
  Widget _buildReadyScreen() {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.fitness_center_rounded,
                size: 80,
                color: AppColors.xpGold,
              )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scale(
                    begin: const Offset(1.0, 1.0),
                    end: const Offset(1.1, 1.1),
                    duration: 1200.ms,
                    curve: Curves.easeInOut,
                  ),
              const SizedBox(height: 24),
              Text(
                'Word Lifter',
                style: AppTextStyles.heading1.copyWith(
                  color: Colors.white,
                  fontSize: 32,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Answer translations correctly to lift the barbell!\n'
                '5 correct in a row = 1 rep.\n'
                'Wrong answer = barbell drops.\n'
                '3 drops and the workout is over.',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: Colors.white70,
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 36),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _startGame,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  child: const Text('Start Workout 💪'),
                ),
              )
                  .animate()
                  .fadeIn(duration: 600.ms, delay: 200.ms)
                  .slideY(begin: 0.2, end: 0, duration: 600.ms, delay: 200.ms),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Gameplay screen ──────────────────────────────────────────
  Widget _buildGameplayScreen(WordLifterProvider provider) {
    const maxLift = 100.0; // pixels the barbell can travel up
    final barbellBottom = 10.0 + provider.barbellPosition * maxLift;

    final isRepPhase = provider.gamePhase == WordLifterPhase.repSuccess ||
        provider.gamePhase == WordLifterPhase.repFail;

    return SafeArea(
      child: Column(
        children: [
          // HUD
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: GameHudWidget(
              currentRep: provider.currentRep,
              timerSeconds: provider.timerSeconds,
              timerDuration: provider.timerDuration,
              totalXp: provider.totalXpEarned,
              failedReps: provider.failedReps,
              maxFailedReps: provider.maxFailedReps,
            ),
          ),

          // Gym scene (character + barbell + combo)
          Expanded(
            flex: 3,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Character
                Positioned(
                  bottom: 20,
                  child: CharacterWidget(
                    muscleScale:
                        1.0 + provider.totalSuccessfulReps * 0.03,
                  ),
                ),

                // Barbell — animated position
                AnimatedPositioned(
                  duration: provider.isDropping
                      ? const Duration(milliseconds: 500)
                      : const Duration(milliseconds: 400),
                  curve: provider.isDropping
                      ? Curves.bounceOut
                      : Curves.easeOutBack,
                  bottom: barbellBottom,
                  child: BarbellWidget(
                    weight: provider.currentWeight,
                    isShaking: provider.gamePhase == WordLifterPhase.repFail,
                  ),
                ),

                // Combo progress bar
                Positioned(
                  top: 8,
                  child: ComboProgressBar(
                    filledCount: provider.correctStreak,
                    total: provider.streakForRep,
                    isComplete:
                        provider.gamePhase == WordLifterPhase.repSuccess,
                  ),
                ),

                // Rep overlays
                if (provider.gamePhase == WordLifterPhase.repSuccess)
                  RepResultOverlay(
                    isSuccess: true,
                    xpGained: 25,
                    newWeight: provider.currentWeight + 10,
                  ),
                if (provider.gamePhase == WordLifterPhase.repFail)
                  const RepResultOverlay(isSuccess: false),
              ],
            ),
          ),

          // Quiz card (hidden during rep overlays with reduced opacity)
          AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: isRepPhase ? 0.3 : 1.0,
            child: IgnorePointer(
              ignoring: isRepPhase,
              child: provider.currentWord != null
                  ? Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: QuizCardWidget(
                        englishWord: provider.currentWord!.englishWord,
                        options: provider.options,
                        selectedIndex: provider.selectedOptionIndex,
                        isAnswered: provider.isAnswered,
                        onOptionTap: provider.submitAnswer,
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Finished screen ──────────────────────────────────────────
  Widget _buildFinishedScreen(WordLifterProvider provider) {
    return SafeArea(
      child: GameOverCard(
        totalReps: provider.totalSuccessfulReps,
        maxWeight: provider.currentWeight,
        totalXp: provider.totalXpEarned,
        correctAnswers: provider.correctAnswers,
        totalQuestions: provider.questionsAnswered,
        onPlayAgain: _startGame,
        onGoHome: () {
          provider.reset();
          context.go('/home');
        },
      ),
    );
  }
}
