import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/appointment.dart';

class AppointmentService {
  final SupabaseClient _supabase;

  AppointmentService(this._supabase);

  Future<List<Appointment>> getStudentAppointments(String studentId) async {
    final response = await _supabase
        .from('appointments')
        .select('''
          *,
          student:profiles!student_id(*),
          teacher:profiles!teacher_id(*)
        ''')
        .eq('student_id', studentId)
        .order('requested_date', ascending: false);

    return (response as List).map((e) => Appointment.fromJson(e)).toList();
  }

  Future<List<Appointment>> getTeacherAppointments(String teacherId) async {
    final response = await _supabase
        .from('appointments')
        .select('''
          *,
          student:profiles!student_id(*),
          teacher:profiles!teacher_id(*)
        ''')
        .eq('teacher_id', teacherId)
        .order('requested_date', ascending: false);

    return (response as List).map((e) => Appointment.fromJson(e)).toList();
  }

  Future<List<Appointment>> getAllAppointments() async {
    final response = await _supabase
        .from('appointments')
        .select('''
          *,
          student:profiles!student_id(*),
          teacher:profiles!teacher_id(*)
        ''')
        .order('requested_date', ascending: false);

    return (response as List).map((e) => Appointment.fromJson(e)).toList();
  }

  Future<List<Appointment>> getPendingAppointments(String teacherId) async {
    final response = await _supabase
        .from('appointments')
        .select('''
          *,
          student:profiles!student_id(*),
          teacher:profiles!teacher_id(*)
        ''')
        .eq('teacher_id', teacherId)
        .eq('status', 'requested')
        .order('requested_date');

    return (response as List).map((e) => Appointment.fromJson(e)).toList();
  }

  Future<Appointment> createAppointment({
    required String studentId,
    required String teacherId,
    required DateTime requestedDate,
    required String requestedTime,
    String? purpose,
  }) async {
    final response = await _supabase.from('appointments').insert({
      'student_id': studentId,
      'teacher_id': teacherId,
      'requested_date': requestedDate.toIso8601String().split('T')[0],
      'requested_time': requestedTime,
      'purpose': purpose,
      'status': 'requested',
    }).select('''
      *,
      student:profiles!student_id(*),
      teacher:profiles!teacher_id(*)
    ''').single();

    return Appointment.fromJson(response);
  }

  Future<Appointment> updateAppointmentStatus(
    String id,
    AppointmentStatus status, {
    DateTime? amendedDate,
    String? amendedTime,
    String? teacherNotes,
  }) async {
    final data = {
      'status': status.name,
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (amendedDate != null) {
      data['amended_date'] = amendedDate.toIso8601String().split('T')[0];
    }
    if (amendedTime != null) {
      data['amended_time'] = amendedTime;
    }
    if (teacherNotes != null) {
      data['teacher_notes'] = teacherNotes;
    }

    final response = await _supabase
        .from('appointments')
        .update(data)
        .eq('id', id)
        .select('''
          *,
          student:profiles!student_id(*),
          teacher:profiles!teacher_id(*)
        ''')
        .single();

    return Appointment.fromJson(response);
  }

  Future<void> deleteAppointment(String id) async {
    await _supabase.from('appointments').delete().eq('id', id);
  }

  Future<List<Appointment>> getTodaysAppointments(String teacherId) async {
    final today = DateTime.now().toIso8601String().split('T')[0];

    final response = await _supabase
        .from('appointments')
        .select('''
          *,
          student:profiles!student_id(*),
          teacher:profiles!teacher_id(*)
        ''')
        .eq('teacher_id', teacherId)
        .eq('requested_date', today)
        .order('requested_time');

    return (response as List).map((e) => Appointment.fromJson(e)).toList();
  }

  Future<int> getPendingAppointmentCount() async {
    final response = await _supabase
        .from('appointments')
        .select('id')
        .eq('status', 'requested');

    return (response as List).length;
  }
}