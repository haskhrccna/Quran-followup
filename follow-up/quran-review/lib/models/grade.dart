import 'user_profile.dart';

enum GradeType { exam, quiz, assignment, project, finalExam }

class Grade {
  final String id;
  final String studentId;
  final String teacherId;
  final String subject;
  final double gradeValue;
  final GradeType gradeType;
  final String? comments;
  final DateTime createdAt;
  final DateTime updatedAt;
  final UserProfile? student;
  final UserProfile? teacher;

  Grade({
    required this.id,
    required this.studentId,
    required this.teacherId,
    required this.subject,
    required this.gradeValue,
    required this.gradeType,
    this.comments,
    required this.createdAt,
    required this.updatedAt,
    this.student,
    this.teacher,
  });

  factory Grade.fromJson(Map<String, dynamic> json) {
    return Grade(
      id: json['id'] as String,
      studentId: json['student_id'] as String,
      teacherId: json['teacher_id'] as String,
      subject: json['subject'] as String,
      gradeValue: (json['grade_value'] as num).toDouble(),
      gradeType: GradeType.values.firstWhere(
        (e) => e.name == json['grade_type'],
        orElse: () => GradeType.exam,
      ),
      comments: json['comments'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      student: json['student'] != null
          ? UserProfile.fromJson(json['student'] as Map<String, dynamic>)
          : null,
      teacher: json['teacher'] != null
          ? UserProfile.fromJson(json['teacher'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'student_id': studentId,
      'teacher_id': teacherId,
      'subject': subject,
      'grade_value': gradeValue,
      'grade_type': gradeType.name,
      'comments': comments,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Grade copyWith({
    String? id,
    String? studentId,
    String? teacherId,
    String? subject,
    double? gradeValue,
    GradeType? gradeType,
    String? comments,
    DateTime? createdAt,
    DateTime? updatedAt,
    UserProfile? student,
    UserProfile? teacher,
  }) {
    return Grade(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      teacherId: teacherId ?? this.teacherId,
      subject: subject ?? this.subject,
      gradeValue: gradeValue ?? this.gradeValue,
      gradeType: gradeType ?? this.gradeType,
      comments: comments ?? this.comments,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      student: student ?? this.student,
      teacher: teacher ?? this.teacher,
    );
  }
}