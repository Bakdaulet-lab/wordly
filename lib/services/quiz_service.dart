import 'dart:math';
import '../models/word_model.dart';
import '../models/quiz_option_model.dart';
import '../constants/app_constants.dart';

class QuizService {
  final Random _random = Random();

  /// Generate a quiz question: 1 correct answer + 3 random wrong answers.
  List<QuizOptionModel> generateOptions({
    required WordModel correctWord,
    required List<WordModel> allWords,
  }) {
    // Filter out the correct word and pick 3 random wrong answers
    final wrongWords = allWords
        .where((w) => w.id != correctWord.id)
        .toList()
      ..shuffle(_random);

    final wrongOptions = wrongWords
        .take(AppConstants.quizOptionsCount - 1)
        .map((w) => QuizOptionModel(
              wordId: w.id,
              text: w.russianTranslation,
              isCorrect: false,
            ))
        .toList();

    final correctOption = QuizOptionModel(
      wordId: correctWord.id,
      text: correctWord.russianTranslation,
      isCorrect: true,
    );

    final options = [...wrongOptions, correctOption]..shuffle(_random);
    return options;
  }

  /// Pick N random words for a quiz session.
  List<WordModel> pickQuizWords(List<WordModel> allWords, {int count = 10}) {
    final shuffled = List<WordModel>.from(allWords)..shuffle(_random);
    return shuffled.take(count.clamp(1, allWords.length)).toList();
  }
}
