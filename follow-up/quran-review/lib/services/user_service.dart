import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';
import '../models/assignment.dart';

class UserService {
  final SupabaseClient _supabase;

  UserService(this._supabase);

  Future<List<UserProfile>> getTeachers() async {
    final response = await _supabase
        .from('profiles')
        .select()
        .eq('role', 'teacher')
        .eq('status', 'active')
        .order('first_name');

    return (response as List).map((e) => UserProfile.fromJson(e)).toList();
  }

  Future<List<UserProfile>> getStudents({String? status}) async {
    var query = _supabase.from('profiles').select().eq('role', 'student');

    if (status != null) {
      query = query.eq('status', status);
    }

    final response = await query.order('first_name');
    return (response as List).map((e) => UserProfile.fromJson(e)).toList();
  }

  Future<UserProfile> getUserById(String id) async {
    final response = await _supabase
        .from('profiles')
        .select()
        .eq('id', id)
        .single();

    return UserProfile.fromJson(response);
  }

  Future<UserProfile> createTeacher({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? phone,
  }) async {
    final response = await _supabase.auth.admin.createUser(
      AdminUserAttributes(
        email: email,
        password: password,
        emailConfirm: true,
      ),
    );

    await _supabase.from('profiles').insert({
      'id': response.user!.id,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'phone': phone,
      'role': 'teacher',
      'status': 'active',
    });

    final profileResponse = await _supabase
        .from('profiles')
        .select()
        .eq('id', response.user!.id)
        .single();

    return UserProfile.fromJson(profileResponse);
  }

  Future<UserProfile> updateUser(String id, Map<String, dynamic> data) async {
    data['updated_at'] = DateTime.now().toIso8601String();

    await _supabase.from('profiles').update(data).eq('id', id);

    final response = await _supabase
        .from('profiles')
        .select()
        .eq('id', id)
        .single();

    return UserProfile.fromJson(response);
  }

  Future<void> deleteUser(String id) async {
    await _supabase.auth.admin.deleteUser(id);
  }

  Future<void> resetUserPassword(String id, String newPassword) async {
    await _supabase.auth.admin.updateUserById(
      id,
      attributes: AdminUserAttributes(password: newPassword),
    );
  }

  Future<UserProfile> acceptStudent(
    String studentId,
    String teacherId,
    String adminId,
  ) async {
    await _supabase.from('profiles').update({'status': 'active'}).eq('id', studentId);

    await _supabase.from('student_teacher_assignments').insert({
      'student_id': studentId,
      'teacher_id': teacherId,
      'assigned_by': adminId,
    });

    final response = await _supabase
        .from('profiles')
        .select()
        .eq('id', studentId)
        .single();

    return UserProfile.fromJson(response);
  }

  Future<void> assignTeacher(
    String studentId,
    String teacherId,
    String adminId,
  ) async {
    final existing = await _supabase
        .from('student_teacher_assignments')
        .select()
        .eq('student_id', studentId)
        .eq('is_active', true)
        .maybeSingle();

    if (existing != null) {
      await _supabase
          .from('student_teacher_assignments')
          .update({'is_active': false}).eq('id', existing['id']);
    }

    await _supabase.from('student_teacher_assignments').insert({
      'student_id': studentId,
      'teacher_id': teacherId,
      'assigned_by': adminId,
    });
  }

  Future<List<Assignment>> getStudentAssignments(String studentId) async {
    final response = await _supabase
        .from('student_teacher_assignments')
        .select('''
          *,
          student:profiles!student_id(*),
          teacher:profiles!teacher_id(*),
          assigned_by_profile:profiles!assigned_by(*)
        ''')
        .eq('student_id', studentId)
        .eq('is_active', true);

    return (response as List).map((e) => Assignment.fromJson(e)).toList();
  }

  Future<List<Assignment>> getTeacherAssignments(String teacherId) async {
    final response = await _supabase
        .from('student_teacher_assignments')
        .select('''
          *,
          student:profiles!student_id(*),
          teacher:profiles!teacher_id(*),
          assigned_by_profile:profiles!assigned_by(*)
        ''')
        .eq('teacher_id', teacherId)
        .eq('is_active', true);

    return (response as List).map((e) => Assignment.fromJson(e)).toList();
  }

  Future<UserProfile?> getAssignedTeacher(String studentId) async {
    final response = await _supabase
        .from('student_teacher_assignments')
        .select('''
          teacher:profiles!teacher_id(*)
        ''')
        .eq('student_id', studentId)
        .eq('is_active', true)
        .maybeSingle();

    if (response == null) return null;
    return UserProfile.fromJson(response['teacher'] as Map<String, dynamic>);
  }

  Future<List<UserProfile>> getAssignedStudents(String teacherId) async {
    final response = await _supabase
        .from('student_teacher_assignments')
        .select('''
          student:profiles!student_id(*)
        ''')
        .eq('teacher_id', teacherId)
        .eq('is_active', true);

    return (response as List)
        .map((e) => UserProfile.fromJson(e['student'] as Map<String, dynamic>))
        .toList();
  }

  Future<int> getPendingStudentCount() async {
    final response = await _supabase
        .from('profiles')
        .select('id')
        .eq('role', 'student')
        .eq('status', 'pending');

    return (response as List).length;
  }
}