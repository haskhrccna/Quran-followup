import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';

class AuthService {
  final SupabaseClient _supabase;

  AuthService(this._supabase);

  Future<UserProfile?> getCurrentUser() async {
    final session = _supabase.auth.currentSession;
    if (session == null) return null;

    final response = await _supabase
        .from('profiles')
        .select()
        .eq('id', session.user.id)
        .single();

    return UserProfile.fromJson(response);
  }

  Future<UserProfile> login({
    required String email,
    required String password,
  }) async {
    final response = await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );

    final profileResponse = await _supabase
        .from('profiles')
        .select()
        .eq('id', response.user!.id)
        .single();

    return UserProfile.fromJson(profileResponse);
  }

  Future<UserProfile> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? phone,
  }) async {
    final response = await _supabase.auth.signUp(
      email: email,
      password: password,
    );

    await _supabase.from('profiles').insert({
      'id': response.user!.id,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'phone': phone,
      'role': 'student',
      'status': 'pending',
    });

    final profileResponse = await _supabase
        .from('profiles')
        .select()
        .eq('id', response.user!.id)
        .single();

    return UserProfile.fromJson(profileResponse);
  }

  Future<void> logout() async {
    await _supabase.auth.signOut();
  }

  Future<void> updatePassword(String newPassword) async {
    await _supabase.auth.updateUser(UserAttributes(password: newPassword));
  }

  Future<void> resetPassword(String email) async {
    await _supabase.auth.resetPasswordForEmail(email);
  }

  Stream<UserProfile?> get authStateChanges {
    return _supabase.auth.onAuthStateChange.asyncMap((event) async {
      if (event.session == null) return null;

      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', event.session!.user.id)
          .single();

      return UserProfile.fromJson(response);
    });
  }

  Future<void> updateFcmToken(String token) async {
    final session = _supabase.auth.currentSession;
    if (session == null) return;

    await _supabase
        .from('profiles')
        .update({'fcm_token': token})
        .eq('id', session.user.id);
  }
}