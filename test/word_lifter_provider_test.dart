import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:wordly/models/word_lifter_phase.dart';
import 'package:wordly/models/word_model.dart';
import 'package:wordly/providers/word_lifter_provider.dart';
import 'package:wordly/services/interfaces/i_quiz_service.dart';
import 'package:wordly/services/quiz_service.dart';

void main() {
  late WordLifterProvider provider;
  late List<WordModel> words;

  List<WordModel> makeWords(int count) {
    return List.generate(
      count,
      (i) => WordModel(
        id: i + 1,
        englishWord: 'word_$i',
        russianTranslation: 'слово_$i',
        difficultyLevel: 1,
        category: 'general',
        createdAt: DateTime(2025, 1, 1),
      ),
    );
  }

  setUp(() {
    final sl = GetIt.instance;
    if (!sl.isRegistered<IQuizService>()) {
      sl.registerLazySingleton<IQuizService>(() => QuizService());
    }
    words = makeWords(20);
    provider = WordLifterProvider();
  });

  tearDown(() {
    provider.dispose();
  });

  group('WordLifterProvider', () {
    test('initial phase is ready', () {
      expect(provider.gamePhase, WordLifterPhase.ready);
    });

    test('startGame transitions to playing with a current word', () {
      provider.startGame(words);

      expect(provider.gamePhase, WordLifterPhase.playing);
      expect(provider.currentWord, isNotNull);
      expect(provider.options.length, 4);
      expect(provider.correctStreak, 0);
      expect(provider.currentRep, 1);
      expect(provider.totalXpEarned, 0);
    });

    test('startGame requires at least 4 words', () {
      provider.startGame(makeWords(3));
      // Should not start — stays ready
      expect(provider.gamePhase, WordLifterPhase.ready);
    });

    test('correct answer increments streak and XP', () {
      provider.startGame(words);
      final correctIndex =
          provider.options.indexWhere((o) => o.isCorrect);

      provider.submitAnswer(correctIndex);

      expect(provider.correctStreak, 1);
      expect(provider.correctAnswers, 1);
      expect(provider.totalXpEarned, 10); // xpCorrectAnswer
      expect(provider.barbellPosition, closeTo(0.2, 0.01));
    });

    test('incorrect answer resets streak and increments failed reps', () async {
      provider.startGame(words);
      final wrongIndex =
          provider.options.indexWhere((o) => !o.isCorrect);

      provider.submitAnswer(wrongIndex);

      expect(provider.correctStreak, 0);
      expect(provider.lastAnswerCorrect, false);
      expect(provider.barbellPosition, 0.0);
      expect(provider.totalXpEarned, 2); // xpIncorrectAnswer
      // Phase transitions to repFail
      expect(provider.gamePhase, WordLifterPhase.repFail);
      expect(provider.failedReps, 1);
    });

    test('5 correct answers trigger rep success', () async {
      provider.startGame(words);

      for (int i = 0; i < 5; i++) {
        final correctIndex =
            provider.options.indexWhere((o) => o.isCorrect);
        provider.submitAnswer(correctIndex);

        if (i < 4) {
          // Wait for auto-advance (800ms delay + buffer)
          await Future.delayed(const Duration(milliseconds: 900));
        }
      }

      // After 5 correct answers, phase should be repSuccess
      expect(provider.gamePhase, WordLifterPhase.repSuccess);
      expect(provider.totalSuccessfulReps, 1);
      expect(provider.correctStreak, 5);
    });

    test('cannot submit answer when not playing', () {
      provider.startGame(words);
      provider.reset();

      provider.submitAnswer(0);
      // Should not change anything
      expect(provider.questionsAnswered, 0);
    });

    test('cannot submit twice for same question', () {
      provider.startGame(words);

      final correctIndex =
          provider.options.indexWhere((o) => o.isCorrect);
      provider.submitAnswer(correctIndex);
      final xpAfterFirst = provider.totalXpEarned;

      // Try to submit again
      provider.submitAnswer(0);
      expect(provider.totalXpEarned, xpAfterFirst);
    });

    test('reset returns to ready state', () {
      provider.startGame(words);
      provider.submitAnswer(0);
      provider.reset();

      expect(provider.gamePhase, WordLifterPhase.ready);
      expect(provider.currentWord, isNull);
      expect(provider.options, isEmpty);
      expect(provider.totalXpEarned, 0);
      expect(provider.correctStreak, 0);
    });

    test('3 failed reps end the game', () async {
      provider.startGame(words);

      // Fail 3 times
      for (int i = 0; i < 3; i++) {
        final wrongIndex =
            provider.options.indexWhere((o) => !o.isCorrect);
        provider.submitAnswer(wrongIndex);

        // Wait for repFail phase to resolve
        await Future.delayed(const Duration(milliseconds: 1600));
      }

      expect(provider.failedReps, 3);
      expect(provider.gamePhase, WordLifterPhase.finished);
    });

    test('weight increases after successful rep', () async {
      provider.startGame(words);
      final initialWeight = provider.currentWeight;

      // Complete 5 correct answers
      for (int i = 0; i < 5; i++) {
        final correctIndex =
            provider.options.indexWhere((o) => o.isCorrect);
        provider.submitAnswer(correctIndex);
        if (i < 4) {
          await Future.delayed(const Duration(milliseconds: 900));
        }
      }

      // Wait for rep success to process
      await Future.delayed(const Duration(milliseconds: 2000));

      expect(provider.currentWeight, initialWeight + 10);
      expect(provider.currentRep, 2);
    });

    test('mistakes list tracks unique incorrect words', () {
      provider.startGame(words);
      final word = provider.currentWord;
      final wrongIndex =
          provider.options.indexWhere((o) => !o.isCorrect);
      provider.submitAnswer(wrongIndex);

      expect(provider.mistakes, contains(word));
      expect(provider.mistakes.length, 1);
    });

    test('accuracy computed correctly', () {
      provider.startGame(words);
      // Answer 1 correct
      final correctIndex =
          provider.options.indexWhere((o) => o.isCorrect);
      provider.submitAnswer(correctIndex);

      expect(provider.accuracy, 1.0);
      expect(provider.questionsAnswered, 1);
    });
  });
}
