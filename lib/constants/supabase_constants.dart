/// Supabase project credentials loaded from compile-time environment
/// variables (`--dart-define`) so that secrets never appear in source code.
///
/// Build example:
/// ```sh
/// flutter run \
///   --dart-define=SUPABASE_URL=https://<ref>.supabase.co \
///   --dart-define=SUPABASE_ANON_KEY=<your-anon-key>
/// ```
///
/// Or point to a file with all defines:
/// ```sh
/// flutter run --dart-define-from-file=.env
/// ```
class SupabaseConstants {
  SupabaseConstants._();

  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  /// Returns `true` when both required env vars have been provided.
  static bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
