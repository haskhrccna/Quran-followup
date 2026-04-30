import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/user_profile.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/student/student_dashboard.dart';
import '../screens/student/schedule_appointment.dart';
import '../screens/student/my_appointments.dart';
import '../screens/student/my_grades.dart';
import '../screens/student/upload_center.dart';
import '../screens/student/my_recordings.dart';
import '../screens/student/my_reports.dart';
import '../screens/student/student_profile.dart';
import '../screens/teacher/teacher_dashboard.dart';
import '../screens/teacher/appointment_requests.dart';
import '../screens/teacher/my_schedule.dart';
import '../screens/teacher/student_list.dart';
import '../screens/teacher/grade_student.dart';
import '../screens/teacher/recordings_review.dart';
import '../screens/teacher/generate_report.dart';
import '../screens/teacher/teacher_profile.dart';
import '../screens/admin/admin_dashboard.dart';
import '../screens/admin/manage_teachers.dart';
import '../screens/admin/manage_students.dart';
import '../screens/admin/assign_teachers.dart';
import '../screens/admin/all_appointments.dart';
import '../screens/admin/all_grades.dart';
import '../screens/admin/all_recordings.dart';
import '../screens/admin/all_reports.dart';
import '../screens/admin/teacher_progress.dart';
import '../screens/admin/student_progress.dart';
import '../screens/admin/admin_settings.dart';
import '../screens/shared/chat_list.dart';
import '../screens/shared/chat_detail.dart';
import '../screens/shared/profile_screen.dart';

class AppRouter {
  final UserProfile? currentUser;

  AppRouter({this.currentUser});

  late final GoRouter router = GoRouter(
    initialLocation: currentUser != null ? _getInitialLocation() : '/login',
    redirect: (context, state) {
      final isLoggedIn = currentUser != null;
      final isAuthRoute = state.matchedLocation == '/login' || state.matchedLocation == '/register';

      if (!isLoggedIn && !isAuthRoute) {
        return '/login';
      }
      if (isLoggedIn && isAuthRoute) {
        return _getInitialLocation();
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child, currentUser: currentUser),
        routes: [
          ..._buildStudentRoutes(),
          ..._buildTeacherRoutes(),
          ..._buildAdminRoutes(),
          ..._buildSharedRoutes(),
        ],
      ),
    ],
  );

  String _getInitialLocation() {
    if (currentUser == null) return '/login';

    switch (currentUser!.role) {
      case UserRole.admin:
        return '/admin/dashboard';
      case UserRole.teacher:
        return '/teacher/dashboard';
      case UserRole.student:
        return '/student/dashboard';
    }
  }

  List<GoRoute> _buildStudentRoutes() {
    return [
      GoRoute(
        path: '/student/dashboard',
        builder: (context, state) => const StudentDashboard(),
      ),
      GoRoute(
        path: '/student/schedule-appointment',
        builder: (context, state) => const ScheduleAppointment(),
      ),
      GoRoute(
        path: '/student/my-appointments',
        builder: (context, state) => const MyAppointments(),
      ),
      GoRoute(
        path: '/student/my-grades',
        builder: (context, state) => const MyGrades(),
      ),
      GoRoute(
        path: '/student/upload',
        builder: (context, state) => const UploadCenter(),
      ),
      GoRoute(
        path: '/student/my-recordings',
        builder: (context, state) => const MyRecordings(),
      ),
      GoRoute(
        path: '/student/my-reports',
        builder: (context, state) => const MyReports(),
      ),
      GoRoute(
        path: '/student/profile',
        builder: (context, state) => const StudentProfile(),
      ),
    ];
  }

  List<GoRoute> _buildTeacherRoutes() {
    return [
      GoRoute(
        path: '/teacher/dashboard',
        builder: (context, state) => const TeacherDashboard(),
      ),
      GoRoute(
        path: '/teacher/appointment-requests',
        builder: (context, state) => const AppointmentRequests(),
      ),
      GoRoute(
        path: '/teacher/my-schedule',
        builder: (context, state) => const MySchedule(),
      ),
      GoRoute(
        path: '/teacher/student-list',
        builder: (context, state) => const StudentList(),
      ),
      GoRoute(
        path: '/teacher/grade-student',
        builder: (context, state) => const GradeStudent(),
      ),
      GoRoute(
        path: '/teacher/recordings-review',
        builder: (context, state) => const RecordingsReview(),
      ),
      GoRoute(
        path: '/teacher/generate-report',
        builder: (context, state) => const GenerateReport(),
      ),
      GoRoute(
        path: '/teacher/profile',
        builder: (context, state) => const TeacherProfile(),
      ),
    ];
  }

  List<GoRoute> _buildAdminRoutes() {
    return [
      GoRoute(
        path: '/admin/dashboard',
        builder: (context, state) => const AdminDashboard(),
      ),
      GoRoute(
        path: '/admin/manage-teachers',
        builder: (context, state) => const ManageTeachers(),
      ),
      GoRoute(
        path: '/admin/manage-students',
        builder: (context, state) => const ManageStudents(),
      ),
      GoRoute(
        path: '/admin/assign-teachers',
        builder: (context, state) => const AssignTeachers(),
      ),
      GoRoute(
        path: '/admin/all-appointments',
        builder: (context, state) => const AllAppointments(),
      ),
      GoRoute(
        path: '/admin/all-grades',
        builder: (context, state) => const AllGrades(),
      ),
      GoRoute(
        path: '/admin/all-recordings',
        builder: (context, state) => const AllRecordings(),
      ),
      GoRoute(
        path: '/admin/all-reports',
        builder: (context, state) => const AllReports(),
      ),
      GoRoute(
        path: '/admin/teacher-progress',
        builder: (context, state) => const TeacherProgress(),
      ),
      GoRoute(
        path: '/admin/student-progress',
        builder: (context, state) => const StudentProgress(),
      ),
      GoRoute(
        path: '/admin/settings',
        builder: (context, state) => const AdminSettings(),
      ),
    ];
  }

  List<GoRoute> _buildSharedRoutes() {
    return [
      GoRoute(
        path: '/messages',
        builder: (context, state) => const ChatList(),
      ),
      GoRoute(
        path: '/chat/:userId',
        builder: (context, state) => ChatDetail(
          otherUserId: state.pathParameters['userId']!,
        ),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
    ];
  }
}

class MainShell extends StatelessWidget {
  final Widget child;
  final UserProfile? currentUser;

  const MainShell({super.key, required this.child, this.currentUser});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: currentUser != null
          ? _buildBottomNav(context)
          : null,
    );
  }

  Widget? _buildBottomNav(BuildContext context) {
    if (currentUser == null) return null;

    final location = GoRouterState.of(context).matchedLocation;

    int currentIndex = 0;
    if (location.startsWith('/student')) {
      currentIndex = 0;
    } else if (location.startsWith('/teacher')) {
      currentIndex = 0;
    } else if (location.startsWith('/admin')) {
      currentIndex = 0;
    }

    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: (index) {
        if (currentUser!.role == UserRole.admin) {
          switch (index) {
            case 0:
              context.go('/admin/dashboard');
              break;
            case 1:
              context.go('/messages');
              break;
            case 2:
              context.go('/admin/settings');
              break;
          }
        } else if (currentUser!.role == UserRole.teacher) {
          switch (index) {
            case 0:
              context.go('/teacher/dashboard');
              break;
            case 1:
              context.go('/messages');
              break;
            case 2:
              context.go('/teacher/profile');
              break;
          }
        } else {
          switch (index) {
            case 0:
              context.go('/student/dashboard');
              break;
            case 1:
              context.go('/messages');
              break;
            case 2:
              context.go('/student/profile');
              break;
          }
        }
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.message),
          label: 'Messages',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }
}