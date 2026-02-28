import 'package:flutter_test/flutter_test.dart';
import 'package:wordly/services/sync_service.dart';

void main() {
  group('SyncStatus', () {
    test('has four values', () {
      expect(SyncStatus.values.length, equals(4));
    });

    test('values are synced, syncing, error, offline', () {
      expect(SyncStatus.values, containsAll([
        SyncStatus.synced,
        SyncStatus.syncing,
        SyncStatus.error,
        SyncStatus.offline,
      ]),);
    });
  });
}
