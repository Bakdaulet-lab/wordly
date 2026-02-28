/// Records that a user has unlocked a specific achievement.
class UserAchievementModel {
  final int id;
  final String userId;
  final int achievementId;
  final DateTime unlockedAt;

  const UserAchievementModel({
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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserAchievementModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'UserAchievementModel(id: $id, achievementId: $achievementId)';
}
