import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/grade.dart';

class GradeService {
  final SupabaseClient _supabase;

  GradeService(this._supabase);

  Future<List<Grade>> getStudentGrades(String studentId) async {
    final response = await _supabase
        .from('grades')
        .select('''
          *,
          student:profiles!student_id(*),
          teacher:profiles!teacher_id(*)
        ''')
        .eq('student_id', studentId)
        .order('created_at', ascending: false);

    return (response as List).map((e) => Grade.fromJson(e)).toList();
  }

  Future<List<Grade>> getTeacherGrades(String teacherId) async {
    final response = await _supabase
        .from('grades')
        .select('''
          *,
          student:profiles!student_id(*),
          teacher:profiles!teacher_id(*)
        ''')
        .eq('teacher_id', teacherId)
        .order('created_at', ascending: false);

    return (response as List).map((e) => Grade.fromJson(e)).toList();
  }

  Future<List<Grade>> getAllGrades() async {
    final response = await _supabase
        .from('grades')
        .select('''
          *,
          student:profiles!student_id(*),
          teacher:profiles!teacher_id(*)
        ''')
        .order('created_at', ascending: false);

    return (response as List).map((e) => Grade.fromJson(e)).toList();
  }

  Future<Grade> giveGrade({
    required String studentId,
    required String teacherId,
    required String subject,
    required double gradeValue,
    required GradeType gradeType,
    String? comments,
  }) async {
    final response = await _supabase.from('grades').insert({
      'student_id': studentId,
      'teacher_id': teacherId,
      'subject': subject,
      'grade_value': gradeValue,
      'grade_type': gradeType.name,
      'comments': comments,
    }).select('''
      *,
      student:profiles!student_id(*),
      teacher:profiles!teacher_id(*)
    ''').single();

    return Grade.fromJson(response);
  }

  Future<Grade> updateGrade(
    String id,
    Map<String, dynamic> data,
  ) async {
    data['updated_at'] = DateTime.now().toIso8601String();

    final response = await _supabase
        .from('grades')
        .update(data)
        .eq('id', id)
        .select('''
          *,
          student:profiles!student_id(*),
          teacher:profiles!teacher_id(*)
        ''')
        .single();

    return Grade.fromJson(response);
  }

  Future<void> deleteGrade(String id) async {
    await _supabase.from('grades').delete().eq('id', id);
  }

  Future<double> getStudentAverageGrade(String studentId) async {
    final response = await _supabase
        .from('grades')
        .select('grade_value')
        .eq('student_id', studentId);

    if ((response as List).isEmpty) return 0.0;

    final total = response.fold<double>(
      0.0,
      (sum, item) => sum + (item['grade_value'] as num).toDouble(),
    );

    return total / (response as List).length;
  }

  Future<List<Grade>> getStudentGradesBySubject(
    String studentId,
    String subject,
  ) async {
    final response = await _supabase
        .from('grades')
        .select('''
          *,
          student:profiles!student_id(*),
          teacher:profiles!teacher_id(*)
        ''')
        .eq('student_id', studentId)
        .eq('subject', subject)
        .order('created_at', ascending: false);

    return (response as List).map((e) => Grade.fromJson(e)).toList();
  }

  Future<List<Grade>> getStudentGradesByType(
    String studentId,
    GradeType gradeType,
  ) async {
    final response = await _supabase
        .from('grades')
        .select('''
          *,
          student:profiles!student_id(*),
          teacher:profiles!teacher_id(*)
        ''')
        .eq('student_id', studentId)
        .eq('grade_type', gradeType.name)
        .order('created_at', ascending: false);

    return (response as List).map((e) => Grade.fromJson(e)).toList();
  }
}