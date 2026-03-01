import '../models/leaderboard_entry.dart';
import '../models/friend_model.dart';
import '../di/service_locator.dart';
import '../repositories/leaderboard_repository.dart';
import 'base_provider.dart';

/// Leaderboard tab type for the UI.
enum LeaderboardTab { global, weekly, friends }

/// Provider for leaderboard and friend management state.
class LeaderboardProvider extends BaseProvider {
  final LeaderboardRepository _repo = sl<LeaderboardRepository>();

  // ── State ──────────────────────────────────────────────────────────
  List<LeaderboardEntry> _globalEntries = [];
  List<LeaderboardEntry> _weeklyEntries = [];
  List<LeaderboardEntry> _friendsEntries = [];
  int _userRank = 0;

  List<FriendModel> _friends = [];
  List<FriendModel> _pendingRequests = [];
  List<Map<String, dynamic>> _searchResults = [];

  LeaderboardTab _activeTab = LeaderboardTab.global;

  // ── Getters ────────────────────────────────────────────────────────
  List<LeaderboardEntry> get globalEntries => _globalEntries;
  List<LeaderboardEntry> get weeklyEntries => _weeklyEntries;
  List<LeaderboardEntry> get friendsEntries => _friendsEntries;
  int get userRank => _userRank;

  List<FriendModel> get friends => _friends;
  List<FriendModel> get pendingRequests => _pendingRequests;
  List<Map<String, dynamic>> get searchResults => _searchResults;

  LeaderboardTab get activeTab => _activeTab;

  List<LeaderboardEntry> get activeEntries => switch (_activeTab) {
        LeaderboardTab.global => _globalEntries,
        LeaderboardTab.weekly => _weeklyEntries,
        LeaderboardTab.friends => _friendsEntries,
      };

  void setActiveTab(LeaderboardTab tab) {
    _activeTab = tab;
    notifyListeners();
  }

  // ── Leaderboard loading ────────────────────────────────────────────

  Future<void> loadLeaderboard(String userId) async {
    setLoading(true);
    clearError();

    final results = await Future.wait([
      _repo.getGlobalLeaderboard(),
      _repo.getWeeklyLeaderboard(),
      _repo.getFriendsLeaderboard(userId),
      _repo.getUserRank(userId),
    ]);

    results[0].when(
      success: (data) =>
          _globalEntries = data as List<LeaderboardEntry>,
      failure: (e) => setError(e.userMessage, notify: false),
    );
    results[1].when(
      success: (data) =>
          _weeklyEntries = data as List<LeaderboardEntry>,
      failure: (e) {
        if (errorMessage == null) setError(e.userMessage, notify: false);
      },
    );
    results[2].when(
      success: (data) =>
          _friendsEntries = data as List<LeaderboardEntry>,
      failure: (e) {
        if (errorMessage == null) setError(e.userMessage, notify: false);
      },
    );
    results[3].when(
      success: (data) => _userRank = data as int,
      failure: (_) {},
    );

    setLoading(false);
  }

  // ── Friends management ─────────────────────────────────────────────

  Future<void> loadFriends(String userId) async {
    final friendsResult = await _repo.getFriends(userId);
    friendsResult.when(
      success: (data) => _friends = data,
      failure: (e) => setError(e.userMessage, notify: false),
    );

    final pendingResult = await _repo.getPendingRequests(userId);
    pendingResult.when(
      success: (data) => _pendingRequests = data,
      failure: (e) {
        if (errorMessage == null) setError(e.userMessage, notify: false);
      },
    );

    notifyListeners();
  }

  Future<void> searchUsers(String query, String currentUserId) async {
    if (query.trim().isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }

    final result = await _repo.searchUsers(query, currentUserId);
    result.when(
      success: (data) => _searchResults = data,
      failure: (e) => setError(e.userMessage, notify: false),
    );
    notifyListeners();
  }

  Future<bool> sendFriendRequest({
    required String userId,
    required String friendId,
  }) async {
    final result =
        await _repo.sendFriendRequest(userId: userId, friendId: friendId);
    return result.isSuccess;
  }

  Future<bool> acceptFriendRequest({
    required String userId,
    required String friendId,
  }) async {
    final result =
        await _repo.acceptFriendRequest(userId: userId, friendId: friendId);
    if (result.isSuccess) {
      await loadFriends(userId);
    }
    return result.isSuccess;
  }

  Future<bool> rejectFriendRequest({
    required String userId,
    required String fromUserId,
  }) async {
    final result = await _repo.rejectFriendRequest(
        userId: userId, fromUserId: fromUserId,);
    if (result.isSuccess) {
      _pendingRequests.removeWhere((f) => f.userId == fromUserId);
      notifyListeners();
    }
    return result.isSuccess;
  }

  Future<bool> removeFriend({
    required String userId,
    required String friendId,
  }) async {
    final result =
        await _repo.removeFriend(userId: userId, friendId: friendId);
    if (result.isSuccess) {
      _friends.removeWhere((f) => f.friendId == friendId);
      notifyListeners();
    }
    return result.isSuccess;
  }
}
