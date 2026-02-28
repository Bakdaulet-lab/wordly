import '../../models/word_model.dart';
import '../../models/quiz_option_model.dart';

/// Contract for quiz question generation (pure logic, no network).
abstract class IQuizService {
  /// Generate 4 shuffled options for a quiz question.
  List<QuizOptionModel> generateOptions({
    required WordModel correctWord,
    required List<WordModel> allWords,
  });

  /// Pick [count] random words for a quiz session.
  List<WordModel> pickQuizWords(List<WordModel> allWords, {int count = 10});
}
