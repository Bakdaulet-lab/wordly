import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../di/service_locator.dart';
import '../repositories/auth_repository.dart';

/// Manages authentication state (sign-up, sign-in, sign-out, reset).
class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepo = sl<AuthRepository>();

  User? _user;
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription<AuthState>? _authSubscription;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
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
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _authRepo.signUp(
      email: email,
      password: password,
      displayName: displayName,
    );

    _isLoading = false;

    return result.when(
      success: (response) {
        _user = response.user;
        notifyListeners();
        return _user != null;
      },
      failure: (error) {
        _errorMessage = error.userMessage;
        notifyListeners();
        return false;
      },
    );
  }

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _authRepo.signIn(
      email: email,
      password: password,
    );

    _isLoading = false;

    return result.when(
      success: (response) {
        _user = response.user;
        notifyListeners();
        return _user != null;
      },
      failure: (error) {
        _errorMessage = error.userMessage;
        notifyListeners();
        return false;
      },
    );
  }

  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();

    final result = await _authRepo.signOut();
    result.when(
      success: (_) => _user = null,
      failure: (error) => _errorMessage = error.userMessage,
    );

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> resetPassword(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _authRepo.resetPassword(email);

    _isLoading = false;

    return result.when(
      success: (_) {
        notifyListeners();
        return true;
      },
      failure: (error) {
        _errorMessage = error.userMessage;
        notifyListeners();
        return false;
      },
    );
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
