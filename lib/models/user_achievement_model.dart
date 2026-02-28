class UserAchievementModel {
  final int id;
  final String userId;
  final int achievementId;
  final DateTime unlockedAt;

  UserAchievementModel({
    required this.id,
    required this.userId,
    required this.achievementId,
    required this.unlockedAt,
  });

  factory UserAchievementModel.fromJson(Map<String, dynamic> json) {
    return UserAchievementModel(
      id: json['id'] as int,
      userId: json['user_id'] as String,
      achievementId: json['achievement_id'] as int,
      unlockedAt: DateTime.parse(json['unlocked_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'achievement_id': achievementId,
    };
  }
}
