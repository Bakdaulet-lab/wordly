import 'package:supabase_flutter/supabase_flutter.dart';

/// Contract for authentication operations.
///
/// Abstracting this behind an interface makes the auth layer
/// testable with mocks and allows swapping implementations
/// (e.g. Firebase Auth) without touching consumers.
abstract class IAuthService {
  /// Currently signed-in user, or `null`.
  User? get currentUser;

  /// Stream that emits whenever the auth state changes.
  Stream<AuthState> get authStateChanges;

  /// Create a new account with email/password.
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String displayName,
  });

  /// Sign in with email/password.
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  });

  /// Sign the current user out.
  Future<void> signOut();

  /// Send a password-reset email.
  Future<void> resetPassword(String email);
}
