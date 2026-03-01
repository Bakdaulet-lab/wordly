import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/leaderboard_entry.dart';
import '../models/friend_model.dart';
import '../utils/response_validator.dart';

/// Service for leaderboard queries and friend management.
///
/// Uses Supabase RPC calls for ranked leaderboard and direct
/// table access for friend operations.
class LeaderboardService {
  final SupabaseClient _client;

  LeaderboardService(this._client);

  // ── Global leaderboard ─────────────────────────────────────────────

  /// Fetch top N users ordered by total XP.
  Future<List<LeaderboardEntry>> getGlobalLeaderboard({int limit = 50}) async {
    final response = await _client
        .from('profiles')
        .select('id, display_name, avatar_url, total_xp, level')
        .order('total_xp', ascending: false)
        .limit(limit);

    final validated = ResponseValidator.validateList(
      response,
      context: 'getGlobalLeaderboard',
    );
    final list = validated.when(
      success: (rows) => rows,
      failure: (error) => throw error,
    );
    return List.generate(list.length, (i) {
      return LeaderboardEntry.fromJson(list[i], rank: i + 1);
    });
  }

  /// Fetch the current user's rank.
  Future<int> getUserRank(String userId) async {
    // Count how many users have more XP than the current user
    final userResponse = await _client
        .from('profiles')
        .select('total_xp')
        .eq('id', userId)
        .limit(1);

    final userValidated = ResponseValidator.validateList(
      userResponse,
      context: 'getUserRank.user',
    );
    final list = userValidated.when(
      success: (rows) => rows,
      failure: (error) => throw error,
    );
    if (list.isEmpty) return 0;
    final userXp = list.first['total_xp'] as int? ?? 0;

    final countResponse = await _client
        .from('profiles')
        .select('id')
        .gt('total_xp', userXp);
    final countValidated = ResponseValidator.validateList(
      countResponse,
      context: 'getUserRank.count',
    );
    return countValidated.when(
      success: (rows) => rows.length + 1,
      failure: (error) => throw error,
    );
  }

  // ── Friends leaderboard ────────────────────────────────────────────

  /// Fetch leaderboard limited to friends of the user.
  Future<List<LeaderboardEntry>> getFriendsLeaderboard(String userId) async {
    // Get accepted friend IDs
    final friendsResponse = await _client
        .from('friendships')
        .select('friend_id')
        .eq('user_id', userId)
        .eq('status', 'accepted');

    final friendsValidated = ResponseValidator.validateList(
      friendsResponse,
      context: 'getFriendsLeaderboard.friends',
    );
    final friendIds = friendsValidated.when(
      success: (rows) => rows.map((r) => r['friend_id'] as String).toList(),
      failure: (error) => throw error,
    );

    // Include self
    friendIds.add(userId);

    if (friendIds.isEmpty) return [];

    final response = await _client
        .from('profiles')
        .select('id, display_name, avatar_url, total_xp, level')
        .inFilter('id', friendIds)
        .order('total_xp', ascending: false);

    final validated = ResponseValidator.validateList(
      response,
      context: 'getFriendsLeaderboard.profiles',
    );
    final list = validated.when(
      success: (rows) => rows,
      failure: (error) => throw error,
    );
    return List.generate(list.length, (i) {
      return LeaderboardEntry.fromJson(list[i], rank: i + 1);
    });
  }

  // ── Weekly leaderboard ─────────────────────────────────────────────

  /// Fetch users ranked by XP earned this week.
  Future<List<LeaderboardEntry>> getWeeklyLeaderboard({int limit = 50}) async {
    final now = DateTime.now();
    final weekStart =
        now.subtract(Duration(days: now.weekday - 1)); // Monday
    final startDate = DateTime(weekStart.year, weekStart.month, weekStart.day)
        .toIso8601String()
        .split('T')[0];

    final response = await _client
        .from('daily_stats')
        .select('user_id, xp_earned')
        .gte('date', startDate);

    // Validate and aggregate XP per user
    final weeklyValidated = ResponseValidator.validateList(
      response,
      context: 'getWeeklyLeaderboard.stats',
    );
    final rows = weeklyValidated.when(
      success: (r) => r,
      failure: (error) => throw error,
    );
    final xpMap = <String, int>{};
    for (final row in rows) {
      final uid = row['user_id'] as String;
      xpMap[uid] = (xpMap[uid] ?? 0) + (row['xp_earned'] as int? ?? 0);
    }

    // Sort by XP
    final sorted = xpMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Fetch profiles for the top users
    final topIds = sorted.take(limit).map((e) => e.key).toList();
    if (topIds.isEmpty) return [];

    final profilesResponse = await _client
        .from('profiles')
        .select('id, display_name, avatar_url, total_xp, level')
        .inFilter('id', topIds);

    final profilesValidated = ResponseValidator.validateList(
      profilesResponse,
      context: 'getWeeklyLeaderboard.profiles',
    );
    final profiles = profilesValidated.when(
      success: (r) => r,
      failure: (error) => throw error,
    );
    final profileMap = <String, Map<String, dynamic>>{};
    for (final p in profiles) {
      profileMap[p['id'] as String] = p;
    }

    return List.generate(sorted.length.clamp(0, limit), (i) {
      final entry = sorted[i];
      final profile = profileMap[entry.key] ?? {};
      return LeaderboardEntry(
        userId: entry.key,
        displayName: profile['display_name'] as String? ?? '',
        avatarUrl: profile['avatar_url'] as String?,
        totalXp: entry.value,
        level: profile['level'] as int? ?? 1,
        rank: i + 1,
      );
    });
  }

  // ── Friend management ──────────────────────────────────────────────

  /// Send a friend request.
  Future<void> sendFriendRequest({
    required String userId,
    required String friendId,
  }) async {
    await _client.from('friendships').insert({
      'user_id': userId,
      'friend_id': friendId,
      'status': 'pending',
    });
  }

  /// Accept a friend request (creates the reciprocal record).
  Future<void> acceptFriendRequest({
    required String userId,
    required String friendId,
  }) async {
    // Update the pending request
    await _client
        .from('friendships')
        .update({'status': 'accepted'})
        .eq('user_id', friendId)
        .eq('friend_id', userId);

    // Create the reverse entry
    await _client.from('friendships').upsert({
      'user_id': userId,
      'friend_id': friendId,
      'status': 'accepted',
    });
  }

  /// Reject a friend request.
  Future<void> rejectFriendRequest({
    required String userId,
    required String fromUserId,
  }) async {
    await _client
        .from('friendships')
        .update({'status': 'rejected'})
        .eq('user_id', fromUserId)
        .eq('friend_id', userId);
  }

  /// Remove a friend (both directions).
  Future<void> removeFriend({
    required String userId,
    required String friendId,
  }) async {
    await _client
        .from('friendships')
        .delete()
        .eq('user_id', userId)
        .eq('friend_id', friendId);
    await _client
        .from('friendships')
        .delete()
        .eq('user_id', friendId)
        .eq('friend_id', userId);
  }

  /// Get all friends (accepted).
  Future<List<FriendModel>> getFriends(String userId) async {
    final response = await _client
        .from('friendships')
        .select('*, friend_profile:profiles!friendships_friend_id_fkey(*)')
        .eq('user_id', userId)
        .eq('status', 'accepted');

    final validated = ResponseValidator.validateAndMapList(
      response, FriendModel.fromJson,
      context: 'getFriends',
    );
    return validated.when(
      success: (list) => list,
      failure: (error) => throw error,
    );
  }

  /// Get pending friend requests (where user is the recipient).
  Future<List<FriendModel>> getPendingRequests(String userId) async {
    final response = await _client
        .from('friendships')
        .select('*, friend_profile:profiles!friendships_user_id_fkey(*)')
        .eq('friend_id', userId)
        .eq('status', 'pending');

    final validated = ResponseValidator.validateList(
      response,
      context: 'getPendingRequests',
    );
    return validated.when(
      success: (rows) => rows.map((json) {
        final modified = Map<String, dynamic>.from(json);
        modified['friend_profile'] = json['friend_profile'];
        return FriendModel.fromJson(modified);
      }).toList(),
      failure: (error) => throw error,
    );
  }

  /// Search for users by display name (for adding friends).
  Future<List<Map<String, dynamic>>> searchUsers(
      String query, String currentUserId,) async {
    final response = await _client
        .from('profiles')
        .select('id, display_name, avatar_url, level, total_xp')
        .ilike('display_name', '%$query%')
        .neq('id', currentUserId)
        .limit(20);
    final validated = ResponseValidator.validateList(
      response,
      context: 'searchUsers',
    );
    return validated.when(
      success: (rows) => rows,
      failure: (error) => throw error,
    );
  }
}
