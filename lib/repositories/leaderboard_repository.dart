import '../models/leaderboard_entry.dart';
import '../models/friend_model.dart';
import '../services/leaderboard_service.dart';
import '../utils/api_guard.dart';
import '../utils/result.dart';

/// Repository wrapping [LeaderboardService] with error handling.
class LeaderboardRepository {
  final LeaderboardService _service;

  LeaderboardRepository(this._service);

  // ── Leaderboard queries ────────────────────────────────────────────

  Future<Result<List<LeaderboardEntry>>> getGlobalLeaderboard({
    int limit = 50,
  }) {
    return apiGuard(() => _service.getGlobalLeaderboard(limit: limit));
  }

  Future<Result<int>> getUserRank(String userId) {
    return apiGuard(() => _service.getUserRank(userId));
  }

  Future<Result<List<LeaderboardEntry>>> getFriendsLeaderboard(String userId) {
    return apiGuard(() => _service.getFriendsLeaderboard(userId));
  }

  Future<Result<List<LeaderboardEntry>>> getWeeklyLeaderboard({
    int limit = 50,
  }) {
    return apiGuard(() => _service.getWeeklyLeaderboard(limit: limit));
  }

  // ── Friend management ──────────────────────────────────────────────

  Future<Result<void>> sendFriendRequest({
    required String userId,
    required String friendId,
  }) {
    return apiGuard(
      () => _service.sendFriendRequest(userId: userId, friendId: friendId),
    );
  }

  Future<Result<void>> acceptFriendRequest({
    required String userId,
    required String friendId,
  }) {
    return apiGuard(
      () => _service.acceptFriendRequest(userId: userId, friendId: friendId),
    );
  }

  Future<Result<void>> rejectFriendRequest({
    required String userId,
    required String fromUserId,
  }) {
    return apiGuard(
      () => _service.rejectFriendRequest(
          userId: userId, fromUserId: fromUserId,),
    );
  }

  Future<Result<void>> removeFriend({
    required String userId,
    required String friendId,
  }) {
    return apiGuard(
      () => _service.removeFriend(userId: userId, friendId: friendId),
    );
  }

  Future<Result<List<FriendModel>>> getFriends(String userId) {
    return apiGuard(() => _service.getFriends(userId));
  }

  Future<Result<List<FriendModel>>> getPendingRequests(String userId) {
    return apiGuard(() => _service.getPendingRequests(userId));
  }

  Future<Result<List<Map<String, dynamic>>>> searchUsers(
      String query, String currentUserId,) {
    return apiGuard(() => _service.searchUsers(query, currentUserId));
  }
}
