/// Utility class that strips potentially dangerous or unwanted content from
/// user-supplied text before it reaches services or the database.
class InputSanitizer {
  InputSanitizer._();

  /// Maximum allowed length for generic text fields (display names, etc.).
  static const int maxDisplayNameLength = 50;

  /// Maximum allowed length for email addresses (RFC 5321).
  static const int maxEmailLength = 254;

  /// Maximum allowed length for search queries.
  static const int maxSearchLength = 100;

  /// Removes HTML / script tags and trims whitespace.
  ///
  /// Example:
  /// ```dart
  /// sanitize('<b>Hello</b>') // → 'Hello'
  /// ```
  static String sanitize(String input) {
    // Strip HTML tags
    final noHtml = input.replaceAll(RegExp(r'<[^>]*>'), '');
    // Collapse multiple spaces into one & trim
    return noHtml.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  /// Sanitizes and enforces a maximum length.
  static String sanitizeWithLimit(String input, int maxLength) {
    final cleaned = sanitize(input);
    if (cleaned.length > maxLength) {
      return cleaned.substring(0, maxLength);
    }
    return cleaned;
  }

  /// Sanitize a display name: strip tags, trim, enforce length limit.
  static String sanitizeDisplayName(String input) {
    return sanitizeWithLimit(input, maxDisplayNameLength);
  }

  /// Sanitize an email: lowercase, trim, enforce length limit.
  static String sanitizeEmail(String input) {
    final trimmed = input.trim().toLowerCase();
    if (trimmed.length > maxEmailLength) {
      return trimmed.substring(0, maxEmailLength);
    }
    return trimmed;
  }

  /// Sanitize a search query: strip tags, trim, enforce length limit.
  static String sanitizeSearch(String input) {
    return sanitizeWithLimit(input, maxSearchLength);
  }
}
