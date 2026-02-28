import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/input_sanitizer.dart';
import 'interfaces/i_auth_service.dart';

/// Supabase authentication wrapper (email/password flows).
class AuthService implements IAuthService {
  final SupabaseClient _client;

  AuthService(this._client);

  @override
  User? get currentUser => _client.auth.currentUser;

  @override
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  @override
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final sanitizedEmail = InputSanitizer.sanitizeEmail(email);
    final sanitizedName = InputSanitizer.sanitizeDisplayName(displayName);
    return await _client.auth.signUp(
      email: sanitizedEmail,
      password: password,
      data: {'display_name': sanitizedName},
    );
  }

  @override
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    final sanitizedEmail = InputSanitizer.sanitizeEmail(email);
    return await _client.auth.signInWithPassword(
      email: sanitizedEmail,
      password: password,
    );
  }

  @override
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  @override
  Future<void> resetPassword(String email) async {
    final sanitizedEmail = InputSanitizer.sanitizeEmail(email);
    await _client.auth.resetPasswordForEmail(sanitizedEmail);
  }
}
