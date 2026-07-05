import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase client for shared dashboard data providers.
/// Both apps call `Supabase.initialize` against the same project.
final sharedSupabaseProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});
