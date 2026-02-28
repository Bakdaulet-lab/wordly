/// Converts raw exceptions into user-friendly messages.
///
/// Network and Supabase errors are mapped to plain-language strings.
/// Unknown errors fall back to a generic message so raw stack traces
/// never reach the UI.
String friendlyError(Object e) {
  final msg = e.toString().toLowerCase();

  if (msg.contains('socketexception') ||
      msg.contains('connection') ||
      msg.contains('network')) {
    return 'No internet connection. Please check your network.';
  }
  if (msg.contains('too many requests') || msg.contains('rate limit')) {
    return 'Too many requests. Please wait a moment and try again.';
  }
  if (msg.contains('permission') || msg.contains('row-level security')) {
    return 'Permission denied. Please sign in again.';
  }
  if (msg.contains('timeout') || msg.contains('timed out')) {
    return 'Request timed out. Please try again.';
  }

  return 'Something went wrong. Please try again.';
}
