import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  final SupabaseClient _client = Supabase.instance.client;

  Future<void> signIn(String email, String password) async {
    await _client.auth.signInWithPassword(email: email, password: password);
  }

  String get userId => _client.auth.currentUser!.id;

  Future<Map<String, dynamic>?> fetchUserKeys() async {
    return await _client
        .from('user_keys')
        .select()
        .eq('user_id', userId)
        .maybeSingle();
  }
}