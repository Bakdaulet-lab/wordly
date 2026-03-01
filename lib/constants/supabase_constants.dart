import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Supabase project credentials loaded at runtime from the `.env` file
/// via [flutter_dotenv]. Secrets never appear in source code.
///
/// The `.env` file must contain:
/// ```
/// SUPABASE_URL=https://<ref>.supabase.co
/// SUPABASE_ANON_KEY=<your-anon-key>
/// ```
///
/// Call `await dotenv.load()` in `main()` before accessing these values.
class SupabaseConstants {
  SupabaseConstants._();

  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';

  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  /// Returns `true` when both required env vars have been provided.
  static bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
