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

  /// Characters allowed in display names (letters, digits, spaces, hyphens,
  /// underscores, apostrophes, dots, and common Unicode letters).
  static final RegExp _displayNameAllowed =
      RegExp(r"[^\p{L}\p{N}\s\-_.'·]", unicode: true);

  /// Patterns commonly used in XSS payloads (event handlers, javascript:, etc.).
  static final RegExp _xssPatterns = RegExp(
    r'(javascript\s*:|on\w+\s*=)',
    caseSensitive: false,
  );

  /// Removes HTML / script tags and trims whitespace.
  ///
  /// Example:
  /// ```dart
  /// sanitize('<b>Hello</b>') // → 'Hello'
  /// ```
  static String sanitize(String input) {
    // Strip HTML tags
    final noHtml = input.replaceAll(RegExp(r'<[^>]*>'), '');
    // Remove XSS patterns (javascript: URIs, event handlers)
    final noXss = noHtml.replaceAll(_xssPatterns, '');
    // Collapse multiple spaces into one & trim
    return noXss.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  /// Escapes the five critical HTML characters so that the string is safe
  /// when rendered in an HTML context.
  static String escapeHtml(String input) {
    return input
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#x27;');
  }

  /// Sanitizes and enforces a maximum length.
  static String sanitizeWithLimit(String input, int maxLength) {
    final cleaned = sanitize(input);
    if (cleaned.length > maxLength) {
      return cleaned.substring(0, maxLength);
    }
    return cleaned;
  }

  /// Sanitize a display name: strip tags, remove XSS patterns, filter to
  /// allowed characters, trim, and enforce length limit.
  ///
  /// Characters not in the whitelist (letters, digits, spaces, hyphens,
  /// underscores, apostrophes, dots) are silently removed. Use [escapeHtml]
  /// separately when rendering in an HTML context.
  static String sanitizeDisplayName(String input) {
    final base = sanitizeWithLimit(input, maxDisplayNameLength);
    // Remove characters not in the whitelist
    final filtered = base.replaceAll(_displayNameAllowed, '');
    return filtered.trim();
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
