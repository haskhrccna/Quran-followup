import 'user_profile.dart';

enum AppointmentStatus {
  requested,
  accepted,
  amended,
  rejected,
  completed,
  cancelled,
}

class Appointment {
  final String id;
  final String studentId;
  final String teacherId;
  final DateTime requestedDate;
  final String requestedTime;
  final String? purpose;
  final AppointmentStatus status;
  final DateTime? amendedDate;
  final String? amendedTime;
  final String? teacherNotes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final UserProfile? student;
  final UserProfile? teacher;

  Appointment({
    required this.id,
    required this.studentId,
    required this.teacherId,
    required this.requestedDate,
    required this.requestedTime,
    this.purpose,
    required this.status,
    this.amendedDate,
    this.amendedTime,
    this.teacherNotes,
    required this.createdAt,
    required this.updatedAt,
    this.student,
    this.teacher,
  });

  bool get isPending => status == AppointmentStatus.requested;
  bool get isAccepted => status == AppointmentStatus.accepted;
  bool get isAmended => status == AppointmentStatus.amended;
  bool get isRejected => status == AppointmentStatus.rejected;
  bool get isCompleted => status == AppointmentStatus.completed;
  bool get isCancelled => status == AppointmentStatus.cancelled;

  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      id: json['id'] as String,
      studentId: json['student_id'] as String,
      teacherId: json['teacher_id'] as String,
      requestedDate: DateTime.parse(json['requested_date'] as String),
      requestedTime: json['requested_time'] as String,
      purpose: json['purpose'] as String?,
      status: AppointmentStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => AppointmentStatus.requested,
      ),
      amendedDate: json['amended_date'] != null
          ? DateTime.parse(json['amended_date'] as String)
          : null,
      amendedTime: json['amended_time'] as String?,
      teacherNotes: json['teacher_notes'] as String?,
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
      'requested_date': requestedDate.toIso8601String().split('T')[0],
      'requested_time': requestedTime,
      'purpose': purpose,
      'status': status.name,
      'amended_date': amendedDate?.toIso8601String().split('T')[0],
      'amended_time': amendedTime,
      'teacher_notes': teacherNotes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Appointment copyWith({
    String? id,
    String? studentId,
    String? teacherId,
    DateTime? requestedDate,
    String? requestedTime,
    String? purpose,
    AppointmentStatus? status,
    DateTime? amendedDate,
    String? amendedTime,
    String? teacherNotes,
    DateTime? createdAt,
    DateTime? updatedAt,
    UserProfile? student,
    UserProfile? teacher,
  }) {
    return Appointment(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      teacherId: teacherId ?? this.teacherId,
      requestedDate: requestedDate ?? this.requestedDate,
      requestedTime: requestedTime ?? this.requestedTime,
      purpose: purpose ?? this.purpose,
      status: status ?? this.status,
      amendedDate: amendedDate ?? this.amendedDate,
      amendedTime: amendedTime ?? this.amendedTime,
      teacherNotes: teacherNotes ?? this.teacherNotes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      student: student ?? this.student,
      teacher: teacher ?? this.teacher,
    );
  }
}