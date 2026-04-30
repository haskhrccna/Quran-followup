import 'user_profile.dart';

class Report {
  final String id;
  final String teacherId;
  final String studentId;
  final String pdfUrl;
  final String title;
  final DateTime createdAt;
  final UserProfile? teacher;
  final UserProfile? student;

  Report({
    required this.id,
    required this.teacherId,
    required this.studentId,
    required this.pdfUrl,
    required this.title,
    required this.createdAt,
    this.teacher,
    this.student,
  });

  factory Report.fromJson(Map<String, dynamic> json) {
    return Report(
      id: json['id'] as String,
      teacherId: json['teacher_id'] as String,
      studentId: json['student_id'] as String,
      pdfUrl: json['pdf_url'] as String,
      title: json['title'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      teacher: json['teacher'] != null
          ? UserProfile.fromJson(json['teacher'] as Map<String, dynamic>)
          : null,
      student: json['student'] != null
          ? UserProfile.fromJson(json['student'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'teacher_id': teacherId,
      'student_id': studentId,
      'pdf_url': pdfUrl,
      'title': title,
      'created_at': createdAt.toIso8601String(),
    };
  }
}