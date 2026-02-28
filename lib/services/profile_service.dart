import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile_model.dart';
import '../utils/input_sanitizer.dart';
import 'interfaces/i_profile_service.dart';

/// Supabase data-access layer for user profiles.
class ProfileService implements IProfileService {
  final SupabaseClient _client;

  ProfileService(this._client);

  @override
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

  @override
  Future<void> updateProfile(String userId, Map<String, dynamic> data) async {
    // Sanitize known text fields before sending to DB
    final sanitized = Map<String, dynamic>.from(data);
    if (sanitized.containsKey('display_name')) {
      sanitized['display_name'] = InputSanitizer.sanitizeDisplayName(
        sanitized['display_name'] as String,
      );
    }
    await _client.from('profiles').update(sanitized).eq('id', userId);
  }

  @override
  Future<void> addXp(String userId, int amount) async {
    final profile = await getProfile(userId);
    if (profile == null) return;

    final newTotalXp = profile.totalXp + amount;
    await _client.from('profiles').update({
      'total_xp': newTotalXp,
    }).eq('id', userId);
  }
}
