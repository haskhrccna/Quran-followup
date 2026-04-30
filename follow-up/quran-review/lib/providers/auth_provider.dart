import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';

final supabaseProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(ref.watch(supabaseProvider));
});

final authStateProvider = StreamProvider<UserProfile?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

final currentUserProvider = StateProvider<UserProfile?>((ref) => null);

class AuthNotifier extends StateNotifier<AsyncValue<UserProfile?>> {
  final AuthService _authService;
  final Ref _ref;

  AuthNotifier(this._authService, this._ref) : super(const AsyncValue.loading()) {
    _init();
  }

  Future<void> _init() async {
    state = const AsyncValue.loading();
    try {
      final user = await _authService.getCurrentUser();
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<UserProfile> login({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    try {
      final user = await _authService.login(email: email, password: password);
      state = AsyncValue.data(user);
      _ref.read(currentUserProvider.notifier).state = user;
      return user;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<UserProfile> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? phone,
  }) async {
    state = const AsyncValue.loading();
    try {
      final user = await _authService.register(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
        phone: phone,
      );
      state = AsyncValue.data(user);
      _ref.read(currentUserProvider.notifier).state = user;
      return user;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    state = const AsyncValue.data(null);
    _ref.read(currentUserProvider.notifier).state = null;
  }

  Future<void> updatePassword(String newPassword) async {
    await _authService.updatePassword(newPassword);
  }

  Future<void> refreshUser() async {
    try {
      final user = await _authService.getCurrentUser();
      state = AsyncValue.data(user);
      _ref.read(currentUserProvider.notifier).state = user;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AsyncValue<UserProfile?>>((ref) {
  return AuthNotifier(ref.watch(authServiceProvider), ref);
});