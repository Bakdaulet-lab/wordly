import 'package:flutter/material.dart';

/// Base class for all providers that need loading / error state management.
///
/// Extracts the common `isLoading`, `errorMessage`, `setLoading()`,
/// `setError()`, and `clearError()` pattern so individual providers
/// don't have to redefine it.
///
/// Subclasses still call [notifyListeners] via the helper methods —
/// no manual notification is needed after calling them.
abstract class BaseProvider extends ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;

  /// Whether a long-running operation is in progress.
  bool get isLoading => _isLoading;

  /// User-facing error message, or `null` if no error.
  String? get errorMessage => _errorMessage;

  /// Mark the provider as loading (or not) and notify listeners.
  @protected
  void setLoading(bool value) {
    if (_isLoading == value) return;
    _isLoading = value;
    notifyListeners();
  }

  /// Set an error message and notify listeners.
  ///
  /// If [notify] is false the caller is responsible for calling
  /// [notifyListeners] (useful when batching multiple state changes).
  @protected
  void setError(String? message, {bool notify = true}) {
    _errorMessage = message;
    if (notify) notifyListeners();
  }

  /// Clear any existing error and notify listeners.
  void clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    notifyListeners();
  }
}
