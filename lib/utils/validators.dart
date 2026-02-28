import 'input_sanitizer.dart';

/// Common input validators for forms (email, password, display name).
class Validators {
  Validators._();

  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    final sanitized = InputSanitizer.sanitizeEmail(value);
    if (sanitized.length > InputSanitizer.maxEmailLength) {
      return 'Email is too long';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(sanitized)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    if (value.length > 128) {
      return 'Password must be at most 128 characters';
    }
    return null;
  }

  static String? validateDisplayName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Display name is required';
    }
    final sanitized = InputSanitizer.sanitizeDisplayName(value);
    if (sanitized.length < 2) {
      return 'Name must be at least 2 characters';
    }
    if (sanitized.length > InputSanitizer.maxDisplayNameLength) {
      return 'Name must be at most ${InputSanitizer.maxDisplayNameLength} characters';
    }
    // Only allow letters, numbers, spaces, hyphens, apostrophes
    final nameRegex = RegExp(r"^[a-zA-Z0-9\s\-'À-ÿёЁа-яА-Я]+$");
    if (!nameRegex.hasMatch(sanitized)) {
      return 'Name contains invalid characters';
    }
    return null;
  }

  /// Validate a search query (used in the word list search bar).
  static String? validateSearchQuery(String? value) {
    if (value == null || value.trim().isEmpty) return null; // empty is OK
    final sanitized = InputSanitizer.sanitizeSearch(value);
    if (sanitized.length > InputSanitizer.maxSearchLength) {
      return 'Search query is too long';
    }
    return null;
  }
}
