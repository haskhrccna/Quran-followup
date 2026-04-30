enum UserRole { student, teacher, admin }

enum UserStatus { pending, active, suspended }

class UserProfile {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String? phone;
  final UserRole role;
  final UserStatus status;
  final String? avatarUrl;
  final String? fcmToken;
  final String preferredLanguage;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserProfile({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.phone,
    required this.role,
    required this.status,
    this.avatarUrl,
    this.fcmToken,
    this.preferredLanguage = 'ar',
    required this.createdAt,
    required this.updatedAt,
  });

  String get fullName => '$firstName $lastName';

  bool get isPending => status == UserStatus.pending;
  bool get isActive => status == UserStatus.active;
  bool get isSuspended => status == UserStatus.suspended;

  bool get isAdmin => role == UserRole.admin;
  bool get isTeacher => role == UserRole.teacher;
  bool get isStudent => role == UserRole.student;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      email: json['email'] as String,
      firstName: json['first_name'] as String,
      lastName: json['last_name'] as String,
      phone: json['phone'] as String?,
      role: UserRole.values.firstWhere(
        (e) => e.name == json['role'],
        orElse: () => UserRole.student,
      ),
      status: UserStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => UserStatus.pending,
      ),
      avatarUrl: json['avatar_url'] as String?,
      fcmToken: json['fcm_token'] as String?,
      preferredLanguage: json['preferred_language'] as String? ?? 'ar',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'phone': phone,
      'role': role.name,
      'status': status.name,
      'avatar_url': avatarUrl,
      'fcm_token': fcmToken,
      'preferred_language': preferredLanguage,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  UserProfile copyWith({
    String? id,
    String? email,
    String? firstName,
    String? lastName,
    String? phone,
    UserRole? role,
    UserStatus? status,
    String? avatarUrl,
    String? fcmToken,
    String? preferredLanguage,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      status: status ?? this.status,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      fcmToken: fcmToken ?? this.fcmToken,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}