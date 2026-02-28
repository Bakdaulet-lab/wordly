/// A vocabulary word from the `words` table.
class WordModel {
  final int id;
  final String englishWord;
  final String russianTranslation;
  final String? exampleSentence;
  final int difficultyLevel;
  final String category;
  final DateTime createdAt;

  const WordModel({
    required this.id,
    required this.englishWord,
    required this.russianTranslation,
    this.exampleSentence,
    required this.difficultyLevel,
    required this.category,
    required this.createdAt,
  });

  factory WordModel.fromJson(Map<String, dynamic> json) {
    return WordModel(
      id: json['id'] as int,
      englishWord: json['english_word'] as String,
      russianTranslation: json['russian_translation'] as String,
      exampleSentence: json['example_sentence'] as String?,
      difficultyLevel: json['difficulty_level'] as int? ?? 1,
      category: json['category'] as String? ?? 'general',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'english_word': englishWord,
      'russian_translation': russianTranslation,
      'example_sentence': exampleSentence,
      'difficulty_level': difficultyLevel,
      'category': category,
    };
  }

  WordModel copyWith({
    int? id,
    String? englishWord,
    String? russianTranslation,
    String? exampleSentence,
    int? difficultyLevel,
    String? category,
    DateTime? createdAt,
  }) {
    return WordModel(
      id: id ?? this.id,
      englishWord: englishWord ?? this.englishWord,
      russianTranslation: russianTranslation ?? this.russianTranslation,
      exampleSentence: exampleSentence ?? this.exampleSentence,
      difficultyLevel: difficultyLevel ?? this.difficultyLevel,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WordModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'WordModel(id: $id, englishWord: $englishWord, category: $category)';
}
