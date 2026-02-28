/// A friendship connection between two users.
class FriendModel {
  final int id;
  final String userId;
  final String friendId;
  final String status; // 'pending', 'accepted', 'rejected'
  final DateTime createdAt;

  // Populated from a join with profiles
  final String? friendDisplayName;
  final String? friendAvatarUrl;
  final int? friendLevel;
  final int? friendTotalXp;
  final int? friendCurrentStreak;

  const FriendModel({
    required this.id,
    required this.userId,
    required this.friendId,
    required this.status,
    required this.createdAt,
    this.friendDisplayName,
    this.friendAvatarUrl,
    this.friendLevel,
    this.friendTotalXp,
    this.friendCurrentStreak,
  });

  factory FriendModel.fromJson(Map<String, dynamic> json) {
    // Handle the nested profile data from a join
    final friendProfile = json['friend_profile'] as Map<String, dynamic>?;

    return FriendModel(
      id: json['id'] as int,
      userId: json['user_id'] as String,
      friendId: json['friend_id'] as String,
      status: json['status'] as String? ?? 'pending',
      createdAt: DateTime.parse(json['created_at'] as String),
      friendDisplayName: friendProfile?['display_name'] as String?,
      friendAvatarUrl: friendProfile?['avatar_url'] as String?,
      friendLevel: friendProfile?['level'] as int?,
      friendTotalXp: friendProfile?['total_xp'] as int?,
      friendCurrentStreak: friendProfile?['current_streak'] as int?,
    );
  }

  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FriendModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'FriendModel(id: $id, userId: $userId, friendId: $friendId, status: $status)';
}
