import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/grade.dart';
import '../services/grade_service.dart';
import 'auth_provider.dart';

final gradeServiceProvider = Provider<GradeService>((ref) {
  return GradeService(ref.watch(supabaseProvider));
});

final studentGradesProvider = FutureProvider.family<List<Grade>, String>((ref, studentId) async {
  return ref.watch(gradeServiceProvider).getStudentGrades(studentId);
});

final teacherGradesProvider = FutureProvider.family<List<Grade>, String>((ref, teacherId) async {
  return ref.watch(gradeServiceProvider).getTeacherGrades(teacherId);
});

final allGradesProvider = FutureProvider<List<Grade>>((ref) async {
  return ref.watch(gradeServiceProvider).getAllGrades();
});

final studentAverageGradeProvider = FutureProvider.family<double, String>((ref, studentId) async {
  return ref.watch(gradeServiceProvider).getStudentAverageGrade(studentId);
});

class GradeNotifier extends StateNotifier<AsyncValue<List<Grade>>> {
  final GradeService _service;
  final String? _teacherId;
  final String? _studentId;

  GradeNotifier(this._service, this._teacherId, this._studentId) : super(const AsyncValue.loading()) {
    refresh();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      List<Grade> grades;
      if (_teacherId != null) {
        grades = await _service.getTeacherGrades(_teacherId);
      } else if (_studentId != null) {
        grades = await _service.getStudentGrades(_studentId);
      } else {
        grades = await _service.getAllGrades();
      }
      state = AsyncValue.data(grades);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<Grade> giveGrade({
    required String studentId,
    required String teacherId,
    required String subject,
    required double gradeValue,
    required GradeType gradeType,
    String? comments,
  }) async {
    final grade = await _service.giveGrade(
      studentId: studentId,
      teacherId: teacherId,
      subject: subject,
      gradeValue: gradeValue,
      gradeType: gradeType,
      comments: comments,
    );
    await refresh();
    return grade;
  }

  Future<Grade> updateGrade(String id, Map<String, dynamic> data) async {
    final grade = await _service.updateGrade(id, data);
    await refresh();
    return grade;
  }

  Future<void> deleteGrade(String id) async {
    await _service.deleteGrade(id);
    await refresh();
  }
}

final teacherGradeNotifierProvider = StateNotifierProvider.family<
    GradeNotifier, AsyncValue<List<Grade>>, String>((ref, teacherId) {
  return GradeNotifier(
    ref.watch(gradeServiceProvider),
    teacherId: teacherId,
    studentId: null,
  );
});

final studentGradeNotifierProvider = StateNotifierProvider.family<
    GradeNotifier, AsyncValue<List<Grade>>, String>((ref, studentId) {
  return GradeNotifier(
    ref.watch(gradeServiceProvider),
    teacherId: null,
    studentId: studentId,
  );
});