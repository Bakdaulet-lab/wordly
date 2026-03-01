import '../models/profile_model.dart';
import '../services/profile_service.dart';
import '../utils/api_guard.dart';
import '../utils/performance_monitor.dart';
import '../utils/result.dart';

/// Repository mediating access to user profile data.
class ProfileRepository {
  final ProfileService _profileService;

  ProfileRepository(this._profileService);

  Future<Result<ProfileModel?>> getProfile(String userId) {
    return apiGuard(() => PerformanceMonitor.measure('ProfileRepo.getProfile', () => _profileService.getProfile(userId)));
  }

  Future<Result<void>> updateProfile(
      String userId, Map<String, dynamic> data,) {
    return apiGuard(() => PerformanceMonitor.measure('ProfileRepo.updateProfile', () => _profileService.updateProfile(userId, data)));
  }

  Future<Result<void>> addXp(String userId, int amount) {
    return apiGuard(() => PerformanceMonitor.measure('ProfileRepo.addXp', () => _profileService.addXp(userId, amount)));
  }
}
