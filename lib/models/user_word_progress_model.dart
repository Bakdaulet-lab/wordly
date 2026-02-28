class UserWordProgressModel {
  final int id;
  final String userId;
  final int wordId;
  final double easeFactor;
  final int intervalDays;
  final int repetitionCount;
  final DateTime nextReviewDate;
  final DateTime? lastReviewDate;
  final int correctCount;
  final int incorrectCount;

  UserWordProgressModel({
    required this.id,
    required this.userId,
    required this.wordId,
    required this.easeFactor,
    required this.intervalDays,
    required this.repetitionCount,
    required this.nextReviewDate,
    this.lastReviewDate,
    required this.correctCount,
    required this.incorrectCount,
  });

  factory UserWordProgressModel.fromJson(Map<String, dynamic> json) {
    return UserWordProgressModel(
      id: json['id'] as int,
      userId: json['user_id'] as String,
      wordId: json['word_id'] as int,
      easeFactor: (json['ease_factor'] as num).toDouble(),
      intervalDays: json['interval_days'] as int? ?? 0,
      repetitionCount: json['repetition_count'] as int? ?? 0,
      nextReviewDate: DateTime.parse(json['next_review_date'] as String),
      lastReviewDate: json['last_review_date'] != null
          ? DateTime.parse(json['last_review_date'] as String)
          : null,
      correctCount: json['correct_count'] as int? ?? 0,
      incorrectCount: json['incorrect_count'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'word_id': wordId,
      'ease_factor': easeFactor,
      'interval_days': intervalDays,
      'repetition_count': repetitionCount,
      'next_review_date': nextReviewDate.toIso8601String().split('T')[0],
      'last_review_date': lastReviewDate?.toIso8601String().split('T')[0],
      'correct_count': correctCount,
      'incorrect_count': incorrectCount,
    };
  }
}
