import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_profile.dart';
import '../models/assignment.dart';
import '../services/user_service.dart';
import 'auth_provider.dart';

final userServiceProvider = Provider<UserService>((ref) {
  return UserService(ref.watch(supabaseProvider));
});

final teachersProvider = FutureProvider<List<UserProfile>>((ref) async {
  return ref.watch(userServiceProvider).getTeachers();
});

final studentsProvider = FutureProvider.family<List<UserProfile>, String?>((ref, status) async {
  return ref.watch(userServiceProvider).getStudents(status: status);
});

final pendingStudentsProvider = FutureProvider<List<UserProfile>>((ref) async {
  return ref.watch(userServiceProvider).getStudents(status: 'pending');
});

final pendingStudentCountProvider = FutureProvider<int>((ref) async {
  return ref.watch(userServiceProvider).getPendingStudentCount();
});

final userByIdProvider = FutureProvider.family<UserProfile, String>((ref, id) async {
  return ref.watch(userServiceProvider).getUserById(id);
});

final assignedTeacherProvider = FutureProvider.family<UserProfile?, String>((ref, studentId) async {
  return ref.watch(userServiceProvider).getAssignedTeacher(studentId);
});

final assignedStudentsProvider = FutureProvider.family<List<UserProfile>, String>((ref, teacherId) async {
  return ref.watch(userServiceProvider).getAssignedStudents(teacherId);
});

final studentAssignmentsProvider = FutureProvider.family<List<Assignment>, String>((ref, studentId) async {
  return ref.watch(userServiceProvider).getStudentAssignments(studentId);
});

final teacherAssignmentsProvider = FutureProvider.family<List<Assignment>, String>((ref, teacherId) async {
  return ref.watch(userServiceProvider).getTeacherAssignments(teacherId);
});

class UserNotifier extends StateNotifier<AsyncValue<void>> {
  final UserService _service;

  UserNotifier(this._service) : super(const AsyncValue.data(null));

  Future<UserProfile> createTeacher({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? phone,
  }) async {
    state = const AsyncValue.loading();
    try {
      final teacher = await _service.createTeacher(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
        phone: phone,
      );
      state = const AsyncValue.data(null);
      return teacher;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<UserProfile> updateUser(String id, Map<String, dynamic> data) async {
    state = const AsyncValue.loading();
    try {
      final user = await _service.updateUser(id, data);
      state = const AsyncValue.data(null);
      return user;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> deleteUser(String id) async {
    state = const AsyncValue.loading();
    try {
      await _service.deleteUser(id);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> resetPassword(String id, String newPassword) async {
    state = const AsyncValue.loading();
    try {
      await _service.resetUserPassword(id, newPassword);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<UserProfile> acceptStudent(String studentId, String teacherId, String adminId) async {
    state = const AsyncValue.loading();
    try {
      final user = await _service.acceptStudent(studentId, teacherId, adminId);
      state = const AsyncValue.data(null);
      return user;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> assignTeacher(String studentId, String teacherId, String adminId) async {
    state = const AsyncValue.loading();
    try {
      await _service.assignTeacher(studentId, teacherId, adminId);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final userNotifierProvider = StateNotifierProvider<UserNotifier, AsyncValue<void>>((ref) {
  return UserNotifier(ref.watch(userServiceProvider));
});