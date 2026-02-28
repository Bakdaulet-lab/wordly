class WordModel {
  final int id;
  final String englishWord;
  final String russianTranslation;
  final String? exampleSentence;
  final int difficultyLevel;
  final String category;
  final DateTime createdAt;

  WordModel({
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
}
