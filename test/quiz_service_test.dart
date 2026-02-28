import 'package:flutter_test/flutter_test.dart';
import 'package:wordly/models/word_model.dart';
import 'package:wordly/services/quiz_service.dart';

void main() {
  group('QuizService', () {
    late QuizService service;
    late List<WordModel> words;

    setUp(() {
      service = QuizService();
      words = List.generate(
        10,
        (i) => WordModel(
          id: i + 1,
          englishWord: 'word_$i',
          russianTranslation: 'слово_$i',
          difficultyLevel: 1,
          category: 'general',
          createdAt: DateTime(2025, 1, 1),
        ),
      );
    });

    group('generateOptions', () {
      test('returns 4 options', () {
        final options = service.generateOptions(
          correctWord: words[0],
          allWords: words,
        );
        expect(options.length, 4);
      });

      test('exactly one option is correct', () {
        final options = service.generateOptions(
          correctWord: words[0],
          allWords: words,
        );
        final correctCount = options.where((o) => o.isCorrect).length;
        expect(correctCount, 1);
      });

      test('correct option has the correct word text', () {
        final options = service.generateOptions(
          correctWord: words[0],
          allWords: words,
        );
        final correct = options.firstWhere((o) => o.isCorrect);
        expect(correct.text, words[0].russianTranslation);
      });

      test('wrong options do not contain the correct word ID', () {
        final options = service.generateOptions(
          correctWord: words[0],
          allWords: words,
        );
        final wrongIds =
            options.where((o) => !o.isCorrect).map((o) => o.wordId);
        expect(wrongIds, isNot(contains(words[0].id)));
      });
    });

    group('pickQuizWords', () {
      test('returns requested count', () {
        final picked = service.pickQuizWords(words, count: 5);
        expect(picked.length, 5);
      });

      test('clamps to available words when count exceeds list', () {
        final picked = service.pickQuizWords(words, count: 100);
        expect(picked.length, words.length);
      });

      test('returns at least 1 word', () {
        final picked = service.pickQuizWords(words, count: 0);
        expect(picked.length, 1);
      });
    });
  });
}
