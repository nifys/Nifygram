import 'package:supabase_flutter/supabase_flutter.dart';

/// Thin, client-safe Supabase access layer. Authorization is enforced by RLS
/// and SQL functions; never trust balances or roles supplied by the client.
class NifygramBackend {
  NifygramBackend._();
  static final NifygramBackend instance = NifygramBackend._();

  SupabaseClient get client => Supabase.instance.client;
  User? get currentUser => client.auth.currentUser;

  static Future<void> initialize(String url, String anonKey) async {
    await Supabase.initialize(url: url, anonKey: anonKey);
  }

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String username,
  }) async {
    final normalized = username.trim().toLowerCase();
    if (!RegExp(r'^[a-zA-Z0-9_]{4,32}$').hasMatch(username.trim())) {
      throw const FormatException(
        'Юзернейм должен содержать 4–32 латинских символа, цифры или _.',
      );
    }
    return client.auth.signUp(
      email: email.trim(),
      password: password,
      data: {'username': normalized},
    );
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) => client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );

  Future<void> signOut() => client.auth.signOut();

  Stream<List<Map<String, dynamic>>> watchMyConversations() {
    final uid = currentUser?.id;
    if (uid == null) return const Stream.empty();
    return client
        .from('conversation_members')
        .stream(primaryKey: ['conversation_id', 'user_id'])
        .eq('user_id', uid);
  }

  Stream<List<Map<String, dynamic>>> watchMessages(String conversationId) =>
      client
          .from('messages')
          .stream(primaryKey: ['id'])
          .eq('conversation_id', conversationId)
          .order('created_at');

  Future<void> sendMessage({
    required String conversationId,
    required String body,
  }) async {
    final text = body.trim();
    if (text.isEmpty) return;
    if (text.length > 10000) {
      throw const FormatException('Сообщение слишком длинное.');
    }
    await client.from('messages').insert({
      'conversation_id': conversationId,
      'body': text,
    });
  }

  Future<Map<String, dynamic>> myProfile() async {
    final uid = currentUser?.id;
    if (uid == null) throw StateError('Сначала войдите в аккаунт.');
    return await client.from('profiles').select().eq('id', uid).single();
  }

  /// Fufcoin balance changes must only be made by trusted SQL RPCs/admin
  /// Edge Functions. There is intentionally no client-side "set balance".
}
