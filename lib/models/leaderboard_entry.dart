/// A public leaderboard entry.
class LeaderboardEntry {
  final String userId;
  final String displayName;
  final String? avatarUrl;
  final int totalXp;
  final int level;
  final int rank;

  const LeaderboardEntry({
    required this.userId,
    required this.displayName,
    this.avatarUrl,
    required this.totalXp,
    required this.level,
    required this.rank,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json, {int rank = 0}) {
    return LeaderboardEntry(
      userId: json['id'] as String? ?? json['user_id'] as String,
      displayName: json['display_name'] as String? ?? '',
      avatarUrl: json['avatar_url'] as String?,
      totalXp: json['total_xp'] as int? ?? 0,
      level: json['level'] as int? ?? 1,
      rank: rank,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LeaderboardEntry &&
          runtimeType == other.runtimeType &&
          userId == other.userId;

  @override
  int get hashCode => userId.hashCode;

  @override
  String toString() =>
      'LeaderboardEntry(userId: $userId, displayName: $displayName, rank: $rank)';
}
