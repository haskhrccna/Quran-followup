import 'user_profile.dart';

class Assignment {
  final String id;
  final String studentId;
  final String teacherId;
  final String assignedBy;
  final DateTime assignedAt;
  final bool isActive;
  final UserProfile? student;
  final UserProfile? teacher;
  final UserProfile? assignedByProfile;

  Assignment({
    required this.id,
    required this.studentId,
    required this.teacherId,
    required this.assignedBy,
    required this.assignedAt,
    required this.isActive,
    this.student,
    this.teacher,
    this.assignedByProfile,
  });

  factory Assignment.fromJson(Map<String, dynamic> json) {
    return Assignment(
      id: json['id'] as String,
      studentId: json['student_id'] as String,
      teacherId: json['teacher_id'] as String,
      assignedBy: json['assigned_by'] as String,
      assignedAt: DateTime.parse(json['assigned_at'] as String),
      isActive: json['is_active'] as bool? ?? true,
      student: json['student'] != null
          ? UserProfile.fromJson(json['student'] as Map<String, dynamic>)
          : null,
      teacher: json['teacher'] != null
          ? UserProfile.fromJson(json['teacher'] as Map<String, dynamic>)
          : null,
      assignedByProfile: json['assigned_by_profile'] != null
          ? UserProfile.fromJson(json['assigned_by_profile'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'student_id': studentId,
      'teacher_id': teacherId,
      'assigned_by': assignedBy,
      'assigned_at': assignedAt.toIso8601String(),
      'is_active': isActive,
    };
  }
}