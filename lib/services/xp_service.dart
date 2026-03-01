import 'package:supabase_flutter/supabase_flutter.dart';
import 'interfaces/i_xp_service.dart';

/// Supabase data-access layer for awarding experience points.
class XpService implements IXpService {
  final SupabaseClient _client;

  XpService(this._client);

  /// Award XP to a user atomically via Supabase RPC.
  ///
  /// Calls the `award_xp` stored procedure which performs the read-then-write
  /// in a single transaction, avoiding race conditions from concurrent calls.
  @override
  Future<void> awardXp(String userId, int amount) async {
    await _client.rpc('award_xp', params: {
      'p_user_id': userId,
      'p_amount': amount,
    },);
  }
}
