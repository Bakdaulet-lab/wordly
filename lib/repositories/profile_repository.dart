import '../models/profile_model.dart';
import '../services/profile_service.dart';
import '../utils/api_guard.dart';
import '../utils/result.dart';

/// Repository mediating access to user profile data.
class ProfileRepository {
  final ProfileService _profileService;

  ProfileRepository(this._profileService);

  Future<Result<ProfileModel?>> getProfile(String userId) {
    return apiGuard(() => _profileService.getProfile(userId));
  }

  Future<Result<void>> updateProfile(
      String userId, Map<String, dynamic> data) {
    return apiGuard(() => _profileService.updateProfile(userId, data));
  }

  Future<Result<void>> addXp(String userId, int amount) {
    return apiGuard(() => _profileService.addXp(userId, amount));
  }
}
