import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/xp_calculator.dart';

class XpService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Award XP to a user. Updates total_xp and recalculates level.
  Future<void> awardXp(String userId, int amount) async {
    final response = await _client
        .from('profiles')
        .select('total_xp')
        .eq('id', userId)
        .limit(1);

    final list = response as List;
    if (list.isEmpty) return;

    final currentXp = list.first['total_xp'] as int? ?? 0;
    final newTotalXp = currentXp + amount;
    final newLevel = XpCalculator.levelFromXp(newTotalXp);

    await _client.from('profiles').update({
      'total_xp': newTotalXp,
      'level': newLevel,
    }).eq('id', userId);
  }
}
