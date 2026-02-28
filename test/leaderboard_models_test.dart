import 'package:flutter_test/flutter_test.dart';
import 'package:wordly/models/leaderboard_entry.dart';
import 'package:wordly/models/friend_model.dart';

void main() {
  group('LeaderboardEntry', () {
    test('fromJson with id field', () {
      final json = {
        'id': 'user-123',
        'display_name': 'Alice',
        'avatar_url': 'https://example.com/alice.png',
        'total_xp': 1500,
        'level': 5,
      };
      final entry = LeaderboardEntry.fromJson(json, rank: 1);

      expect(entry.userId, equals('user-123'));
      expect(entry.displayName, equals('Alice'));
      expect(entry.avatarUrl, equals('https://example.com/alice.png'));
      expect(entry.totalXp, equals(1500));
      expect(entry.level, equals(5));
      expect(entry.rank, equals(1));
    });

    test('fromJson with user_id field', () {
      final json = {
        'user_id': 'user-456',
        'display_name': 'Bob',
        'total_xp': 200,
        'level': 2,
      };
      final entry = LeaderboardEntry.fromJson(json, rank: 3);

      expect(entry.userId, equals('user-456'));
      expect(entry.displayName, equals('Bob'));
      expect(entry.avatarUrl, isNull);
      expect(entry.totalXp, equals(200));
      expect(entry.level, equals(2));
      expect(entry.rank, equals(3));
    });

    test('fromJson with null defaults', () {
      final json = <String, dynamic>{
        'id': 'user-789',
      };
      final entry = LeaderboardEntry.fromJson(json);

      expect(entry.userId, equals('user-789'));
      expect(entry.displayName, equals(''));
      expect(entry.avatarUrl, isNull);
      expect(entry.totalXp, equals(0));
      expect(entry.level, equals(1));
      expect(entry.rank, equals(0));
    });

    test('rank defaults to 0 when not provided', () {
      final json = {
        'id': 'user-1',
        'display_name': 'Test',
        'total_xp': 100,
        'level': 1,
      };
      final entry = LeaderboardEntry.fromJson(json);
      expect(entry.rank, equals(0));
    });
  });

  group('FriendModel', () {
    test('fromJson with friend_profile', () {
      final json = {
        'id': 42,
        'user_id': 'user-a',
        'friend_id': 'user-b',
        'status': 'accepted',
        'created_at': '2025-01-15T10:30:00Z',
        'friend_profile': {
          'display_name': 'Bob',
          'avatar_url': 'https://example.com/bob.png',
          'level': 3,
          'total_xp': 750,
          'current_streak': 5,
        },
      };
      final friend = FriendModel.fromJson(json);

      expect(friend.id, equals(42));
      expect(friend.userId, equals('user-a'));
      expect(friend.friendId, equals('user-b'));
      expect(friend.status, equals('accepted'));
      expect(friend.createdAt, equals(DateTime.parse('2025-01-15T10:30:00Z')));
      expect(friend.friendDisplayName, equals('Bob'));
      expect(friend.friendAvatarUrl, equals('https://example.com/bob.png'));
      expect(friend.friendLevel, equals(3));
      expect(friend.friendTotalXp, equals(750));
      expect(friend.friendCurrentStreak, equals(5));
    });

    test('fromJson without friend_profile', () {
      final json = {
        'id': 1,
        'user_id': 'user-a',
        'friend_id': 'user-b',
        'status': 'pending',
        'created_at': '2025-06-01T00:00:00Z',
      };
      final friend = FriendModel.fromJson(json);

      expect(friend.friendDisplayName, isNull);
      expect(friend.friendAvatarUrl, isNull);
      expect(friend.friendLevel, isNull);
      expect(friend.friendTotalXp, isNull);
      expect(friend.friendCurrentStreak, isNull);
    });

    test('fromJson defaults status to pending', () {
      final json = {
        'id': 2,
        'user_id': 'user-a',
        'friend_id': 'user-b',
        'created_at': '2025-06-01T00:00:00Z',
      };
      final friend = FriendModel.fromJson(json);
      expect(friend.status, equals('pending'));
    });

    test('isPending returns true for pending status', () {
      final friend = FriendModel(
        id: 1,
        userId: 'a',
        friendId: 'b',
        status: 'pending',
        createdAt: DateTime.now(),
      );
      expect(friend.isPending, isTrue);
      expect(friend.isAccepted, isFalse);
    });

    test('isAccepted returns true for accepted status', () {
      final friend = FriendModel(
        id: 1,
        userId: 'a',
        friendId: 'b',
        status: 'accepted',
        createdAt: DateTime.now(),
      );
      expect(friend.isPending, isFalse);
      expect(friend.isAccepted, isTrue);
    });

    test('rejected status returns false for both helpers', () {
      final friend = FriendModel(
        id: 1,
        userId: 'a',
        friendId: 'b',
        status: 'rejected',
        createdAt: DateTime.now(),
      );
      expect(friend.isPending, isFalse);
      expect(friend.isAccepted, isFalse);
    });
  });
}
