import 'package:flutter_test/flutter_test.dart';
import 'package:wordly/providers/leaderboard_provider.dart';

void main() {
  group('LeaderboardTab', () {
    test('has three values', () {
      expect(LeaderboardTab.values.length, equals(3));
    });

    test('values are global, weekly, friends', () {
      expect(LeaderboardTab.values, containsAll([
        LeaderboardTab.global,
        LeaderboardTab.weekly,
        LeaderboardTab.friends,
      ]),);
    });
  });
}
