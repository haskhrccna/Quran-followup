import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/dashboard_stats.dart';

final dashboardStatsProvider = FutureProvider<DashboardStats>((ref) async {
  return DashboardStats(
    totalStudents: 0,
    totalTeachers: 0,
    pendingApprovals: 0,
    totalAppointments: 0,
    pendingAppointments: 0,
    completedAppointments: 0,
    totalGrades: 0,
    totalRecordings: 0,
    pendingRecordings: 0,
    averageGrade: 0.0,
    recentActivity: [],
  );
});

final teacherProgressProvider = FutureProvider.family<TeacherProgress, String>((ref, teacherId) async {
  return TeacherProgress(
    teacherId: teacherId,
    teacherName: '',
    studentCount: 0,
    appointmentsCount: 0,
    gradesGiven: 0,
    averageGrade: 0.0,
    completionRate: 0.0,
    monthlyStats: [],
  );
});

final studentProgressProvider = FutureProvider.family<StudentProgress, String>((ref, studentId) async {
  return StudentProgress(
    studentId: studentId,
    studentName: '',
    totalAppointments: 0,
    completedAppointments: 0,
    totalGrades: 0,
    averageGrade: 0.0,
    recordingsUploaded: 0,
    recordingsReviewed: 0,
    monthlyStats: [],
  );
});

class DashboardStatsNotifier extends StateNotifier<AsyncValue<DashboardStats>> {
  DashboardStatsNotifier() : super(const AsyncValue.loading()) {
    refresh();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      final stats = DashboardStats(
        totalStudents: 0,
        totalTeachers: 0,
        pendingApprovals: 0,
        totalAppointments: 0,
        pendingAppointments: 0,
        completedAppointments: 0,
        totalGrades: 0,
        totalRecordings: 0,
        pendingRecordings: 0,
        averageGrade: 0.0,
        recentActivity: [],
      );
      state = AsyncValue.data(stats);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final dashboardStatsNotifierProvider = StateNotifierProvider<DashboardStatsNotifier, AsyncValue<DashboardStats>>((ref) {
  return DashboardStatsNotifier();
});