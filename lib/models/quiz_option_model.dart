/// A single answer option displayed during a quiz question.
class QuizOptionModel {
  final int wordId;
  final String text;
  final bool isCorrect;

  const QuizOptionModel({
    required this.wordId,
    required this.text,
    required this.isCorrect,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuizOptionModel &&
          runtimeType == other.runtimeType &&
          wordId == other.wordId &&
          text == other.text &&
          isCorrect == other.isCorrect;

  @override
  int get hashCode => Object.hash(wordId, text, isCorrect);

  @override
  String toString() =>
      'QuizOptionModel(wordId: $wordId, text: $text, isCorrect: $isCorrect)';
}
