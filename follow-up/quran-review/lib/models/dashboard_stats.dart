class DashboardStats {
  final int totalStudents;
  final int totalTeachers;
  final int pendingApprovals;
  final int totalAppointments;
  final int pendingAppointments;
  final int completedAppointments;
  final int totalGrades;
  final int totalRecordings;
  final int pendingRecordings;
  final double averageGrade;
  final List<ActivityItem> recentActivity;

  DashboardStats({
    required this.totalStudents,
    required this.totalTeachers,
    required this.pendingApprovals,
    required this.totalAppointments,
    required this.pendingAppointments,
    required this.completedAppointments,
    required this.totalGrades,
    required this.totalRecordings,
    required this.pendingRecordings,
    required this.averageGrade,
    required this.recentActivity,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      totalStudents: json['total_students'] as int? ?? 0,
      totalTeachers: json['total_teachers'] as int? ?? 0,
      pendingApprovals: json['pending_approvals'] as int? ?? 0,
      totalAppointments: json['total_appointments'] as int? ?? 0,
      pendingAppointments: json['pending_appointments'] as int? ?? 0,
      completedAppointments: json['completed_appointments'] as int? ?? 0,
      totalGrades: json['total_grades'] as int? ?? 0,
      totalRecordings: json['total_recordings'] as int? ?? 0,
      pendingRecordings: json['pending_recordings'] as int? ?? 0,
      averageGrade: (json['average_grade'] as num?)?.toDouble() ?? 0.0,
      recentActivity: (json['recent_activity'] as List<dynamic>?)
              ?.map((e) => ActivityItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class ActivityItem {
  final String id;
  final String type;
  final String description;
  final String userId;
  final String userName;
  final DateTime createdAt;

  ActivityItem({
    required this.id,
    required this.type,
    required this.description,
    required this.userId,
    required this.userName,
    required this.createdAt,
  });

  factory ActivityItem.fromJson(Map<String, dynamic> json) {
    return ActivityItem(
      id: json['id'] as String,
      type: json['type'] as String,
      description: json['description'] as String,
      userId: json['user_id'] as String,
      userName: json['user_name'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class TeacherProgress {
  final String teacherId;
  final String teacherName;
  final int studentCount;
  final int appointmentsCount;
  final int gradesGiven;
  final double averageGrade;
  final double completionRate;
  final List<MonthlyStat> monthlyStats;

  TeacherProgress({
    required this.teacherId,
    required this.teacherName,
    required this.studentCount,
    required this.appointmentsCount,
    required this.gradesGiven,
    required this.averageGrade,
    required this.completionRate,
    required this.monthlyStats,
  });

  factory TeacherProgress.fromJson(Map<String, dynamic> json) {
    return TeacherProgress(
      teacherId: json['teacher_id'] as String,
      teacherName: json['teacher_name'] as String,
      studentCount: json['student_count'] as int? ?? 0,
      appointmentsCount: json['appointments_count'] as int? ?? 0,
      gradesGiven: json['grades_given'] as int? ?? 0,
      averageGrade: (json['average_grade'] as num?)?.toDouble() ?? 0.0,
      completionRate: (json['completion_rate'] as num?)?.toDouble() ?? 0.0,
      monthlyStats: (json['monthly_stats'] as List<dynamic>?)
              ?.map((e) => MonthlyStat.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class StudentProgress {
  final String studentId;
  final String studentName;
  final int totalAppointments;
  final int completedAppointments;
  final int totalGrades;
  final double averageGrade;
  final int recordingsUploaded;
  final int recordingsReviewed;
  final List<MonthlyStat> monthlyStats;

  StudentProgress({
    required this.studentId,
    required this.studentName,
    required this.totalAppointments,
    required this.completedAppointments,
    required this.totalGrades,
    required this.averageGrade,
    required this.recordingsUploaded,
    required this.recordingsReviewed,
    required this.monthlyStats,
  });

  factory StudentProgress.fromJson(Map<String, dynamic> json) {
    return StudentProgress(
      studentId: json['student_id'] as String,
      studentName: json['student_name'] as String,
      totalAppointments: json['total_appointments'] as int? ?? 0,
      completedAppointments: json['completed_appointments'] as int? ?? 0,
      totalGrades: json['total_grades'] as int? ?? 0,
      averageGrade: (json['average_grade'] as num?)?.toDouble() ?? 0.0,
      recordingsUploaded: json['recordings_uploaded'] as int? ?? 0,
      recordingsReviewed: json['recordings_reviewed'] as int? ?? 0,
      monthlyStats: (json['monthly_stats'] as List<dynamic>?)
              ?.map((e) => MonthlyStat.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class MonthlyStat {
  final String month;
  final int count;
  final double value;

  MonthlyStat({
    required this.month,
    required this.count,
    required this.value,
  });

  factory MonthlyStat.fromJson(Map<String, dynamic> json) {
    return MonthlyStat(
      month: json['month'] as String,
      count: json['count'] as int? ?? 0,
      value: (json['value'] as num?)?.toDouble() ?? 0.0,
    );
  }
}