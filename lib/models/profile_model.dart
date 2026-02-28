/// User profile data from the `profiles` table.
class ProfileModel {
  final String id;
  final String displayName;
  final String? avatarUrl;
  final int level;
  final int totalXp;
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastLoginDate;
  final DateTime createdAt;

  const ProfileModel({
    required this.id,
    required this.displayName,
    this.avatarUrl,
    required this.level,
    required this.totalXp,
    required this.currentStreak,
    required this.longestStreak,
    this.lastLoginDate,
    required this.createdAt,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'] as String,
      displayName: json['display_name'] as String? ?? '',
      avatarUrl: json['avatar_url'] as String?,
      level: json['level'] as int? ?? 1,
      totalXp: json['total_xp'] as int? ?? 0,
      currentStreak: json['current_streak'] as int? ?? 0,
      longestStreak: json['longest_streak'] as int? ?? 0,
      lastLoginDate: json['last_login_date'] != null
          ? DateTime.parse(json['last_login_date'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'display_name': displayName,
      'avatar_url': avatarUrl,
      'level': level,
      'total_xp': totalXp,
      'current_streak': currentStreak,
      'longest_streak': longestStreak,
      'last_login_date': lastLoginDate?.toIso8601String().split('T')[0],
      'created_at': createdAt.toIso8601String(),
    };
  }

  ProfileModel copyWith({
    String? displayName,
    String? avatarUrl,
    int? level,
    int? totalXp,
    int? currentStreak,
    int? longestStreak,
    DateTime? lastLoginDate,
  }) {
    return ProfileModel(
      id: id,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      level: level ?? this.level,
      totalXp: totalXp ?? this.totalXp,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastLoginDate: lastLoginDate ?? this.lastLoginDate,
      createdAt: createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProfileModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'ProfileModel(id: $id, displayName: $displayName, level: $level, totalXp: $totalXp)';
}
