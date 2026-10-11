import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const url = String.fromEnvironment('SUPABASE_URL');
  static const publishableKey =
  String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

  static Future<void> initialize() async {
    if (url.isEmpty || publishableKey.isEmpty) {
      throw StateError(
        'Missing Supabase configuration. '
        'Supply SUPABASE_URL and SUPABASE_PUBLISHABLE_KEY.',
      );
    }

    await Supabase.initialize(url: url, publishableKey: publishableKey);
  }
}
