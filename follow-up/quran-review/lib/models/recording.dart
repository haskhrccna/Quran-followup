import 'user_profile.dart';

class Recording {
  final String id;
  final String studentId;
  final String teacherId;
  final String fileUrl;
  final String fileType;
  final String fileName;
  final int? fileSize;
  final String? description;
  final bool reviewed;
  final DateTime? reviewedAt;
  final String? reviewedBy;
  final DateTime createdAt;
  final UserProfile? student;
  final UserProfile? teacher;

  Recording({
    required this.id,
    required this.studentId,
    required this.teacherId,
    required this.fileUrl,
    required this.fileType,
    required this.fileName,
    this.fileSize,
    this.description,
    required this.reviewed,
    this.reviewedAt,
    this.reviewedBy,
    required this.createdAt,
    this.student,
    this.teacher,
  });

  bool get isReviewed => reviewed;
  bool get isAudio => fileType == 'audio';
  bool get isVideo => fileType == 'video';
  bool get isDocument => fileType == 'document';

  String get fileSizeFormatted {
    if (fileSize == null) return '';
    if (fileSize! < 1024) return '$fileSize B';
    if (fileSize! < 1024 * 1024) return '${(fileSize! / 1024).toStringAsFixed(1)} KB';
    return '${(fileSize! / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  factory Recording.fromJson(Map<String, dynamic> json) {
    return Recording(
      id: json['id'] as String,
      studentId: json['student_id'] as String,
      teacherId: json['teacher_id'] as String,
      fileUrl: json['file_url'] as String,
      fileType: json['file_type'] as String,
      fileName: json['file_name'] as String,
      fileSize: json['file_size'] as int?,
      description: json['description'] as String?,
      reviewed: json['reviewed'] as bool? ?? false,
      reviewedAt: json['reviewed_at'] != null
          ? DateTime.parse(json['reviewed_at'] as String)
          : null,
      reviewedBy: json['reviewed_by'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
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
      'file_url': fileUrl,
      'file_type': fileType,
      'file_name': fileName,
      'file_size': fileSize,
      'description': description,
      'reviewed': reviewed,
      'reviewed_at': reviewedAt?.toIso8601String(),
      'reviewed_by': reviewedBy,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Recording copyWith({
    String? id,
    String? studentId,
    String? teacherId,
    String? fileUrl,
    String? fileType,
    String? fileName,
    int? fileSize,
    String? description,
    bool? reviewed,
    DateTime? reviewedAt,
    String? reviewedBy,
    DateTime? createdAt,
    UserProfile? student,
    UserProfile? teacher,
  }) {
    return Recording(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      teacherId: teacherId ?? this.teacherId,
      fileUrl: fileUrl ?? this.fileUrl,
      fileType: fileType ?? this.fileType,
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
      description: description ?? this.description,
      reviewed: reviewed ?? this.reviewed,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      createdAt: createdAt ?? this.createdAt,
      student: student ?? this.student,
      teacher: teacher ?? this.teacher,
    );
  }
}