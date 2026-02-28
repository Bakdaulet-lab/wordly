import '../../models/profile_model.dart';

/// Contract for user profile data access.
abstract class IProfileService {
  /// Fetch a user's profile by [userId]. Returns `null` if not found.
  Future<ProfileModel?> getProfile(String userId);

  /// Update arbitrary profile fields for [userId].
  Future<void> updateProfile(String userId, Map<String, dynamic> data);

  /// Add [amount] XP to the user's total.
  Future<void> addXp(String userId, int amount);
}
