import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../di/service_locator.dart';
import '../repositories/auth_repository.dart';
import 'base_provider.dart';

/// Manages authentication state (sign-up, sign-in, sign-out, reset).
class AuthProvider extends BaseProvider {
  final AuthRepository _authRepo = sl<AuthRepository>();

  User? _user;
  StreamSubscription<AuthState>? _authSubscription;

  User? get user => _user;
  bool get isAuthenticated => _user != null;

  AuthProvider() {
    _user = _authRepo.currentUser;
    _authSubscription = _authRepo.authStateChanges.listen((authState) {
      _user = authState.session?.user;
      notifyListeners();
    });
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    setLoading(true);
    setError(null, notify: false);

    final result = await _authRepo.signUp(
      email: email,
      password: password,
      displayName: displayName,
    );

    setLoading(false);

    return result.when(
      success: (response) {
        _user = response.user;
        notifyListeners();
        return _user != null;
      },
      failure: (error) {
        setError(error.userMessage);
        return false;
      },
    );
  }

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    setLoading(true);
    setError(null, notify: false);

    final result = await _authRepo.signIn(
      email: email,
      password: password,
    );

    setLoading(false);

    return result.when(
      success: (response) {
        _user = response.user;
        notifyListeners();
        return _user != null;
      },
      failure: (error) {
        setError(error.userMessage);
        return false;
      },
    );
  }

  Future<void> signOut() async {
    setLoading(true);

    final result = await _authRepo.signOut();
    result.when(
      success: (_) => _user = null,
      failure: (error) => setError(error.userMessage, notify: false),
    );

    setLoading(false);
  }

  Future<bool> resetPassword(String email) async {
    setLoading(true);
    setError(null, notify: false);

    final result = await _authRepo.resetPassword(email);

    setLoading(false);

    return result.when(
      success: (_) {
        notifyListeners();
        return true;
      },
      failure: (error) {
        setError(error.userMessage);
        return false;
      },
    );
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
