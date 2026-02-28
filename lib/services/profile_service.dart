import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile_model.dart';

class ProfileService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<ProfileModel?> getProfile(String userId) async {
    final response = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .limit(1);
    final list = response as List;
    if (list.isEmpty) return null;
    return ProfileModel.fromJson(list.first);
  }

  Future<void> updateProfile(String userId, Map<String, dynamic> data) async {
    await _client.from('profiles').update(data).eq('id', userId);
  }

  Future<void> addXp(String userId, int amount) async {
    final profile = await getProfile(userId);
    if (profile == null) return;

    final newTotalXp = profile.totalXp + amount;
    await _client.from('profiles').update({
      'total_xp': newTotalXp,
    }).eq('id', userId);
  }
}
