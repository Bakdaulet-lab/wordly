import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';
import '../utils/api_guard.dart';
import '../utils/result.dart';

/// Repository that mediates between [AuthProvider] and [AuthService].
///
/// Wraps every service call in [apiGuard] so providers never deal
/// with raw exceptions—they receive [Result] objects instead.
class AuthRepository {
  final AuthService _authService;

  AuthRepository(this._authService);

  User? get currentUser => _authService.currentUser;

  Stream<AuthState> get authStateChanges => _authService.authStateChanges;

  Future<Result<AuthResponse>> signUp({
    required String email,
    required String password,
    required String displayName,
  }) {
    return apiGuard(() => _authService.signUp(
          email: email,
          password: password,
          displayName: displayName,
        ),);
  }

  Future<Result<AuthResponse>> signIn({
    required String email,
    required String password,
  }) {
    return apiGuard(() => _authService.signIn(
          email: email,
          password: password,
        ),);
  }

  Future<Result<void>> signOut() {
    return apiGuard(() => _authService.signOut());
  }

  Future<Result<void>> resetPassword(String email) {
    return apiGuard(() => _authService.resetPassword(email));
  }
}
