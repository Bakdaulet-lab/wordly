class DailyStatsModel {
  final int id;
  final String userId;
  final DateTime date;
  final int wordsLearned;
  final int wordsReviewed;
  final int correctAnswers;
  final int incorrectAnswers;
  final int xpEarned;
  final int sessionDurationSeconds;

  DailyStatsModel({
    required this.id,
    required this.userId,
    required this.date,
    required this.wordsLearned,
    required this.wordsReviewed,
    required this.correctAnswers,
    required this.incorrectAnswers,
    required this.xpEarned,
    required this.sessionDurationSeconds,
  });

  factory DailyStatsModel.fromJson(Map<String, dynamic> json) {
    return DailyStatsModel(
      id: json['id'] as int,
      userId: json['user_id'] as String,
      date: DateTime.parse(json['date'] as String),
      wordsLearned: json['words_learned'] as int? ?? 0,
      wordsReviewed: json['words_reviewed'] as int? ?? 0,
      correctAnswers: json['correct_answers'] as int? ?? 0,
      incorrectAnswers: json['incorrect_answers'] as int? ?? 0,
      xpEarned: json['xp_earned'] as int? ?? 0,
      sessionDurationSeconds: json['session_duration_seconds'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'date': date.toIso8601String().split('T')[0],
      'words_learned': wordsLearned,
      'words_reviewed': wordsReviewed,
      'correct_answers': correctAnswers,
      'incorrect_answers': incorrectAnswers,
      'xp_earned': xpEarned,
      'session_duration_seconds': sessionDurationSeconds,
    };
  }
}
