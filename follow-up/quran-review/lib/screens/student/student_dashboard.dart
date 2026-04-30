import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/appointment_provider.dart';
import '../../providers/grade_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/common/common_widgets.dart';
import '../../config/app_config.dart';

class StudentDashboard extends ConsumerWidget {
  const StudentDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final user = ref.watch(currentUserProvider);

    if (user == null) {
      return const Scaffold(body: AppLoading());
    }

    final appointmentsAsync = ref.watch(studentAppointmentsProvider(user.id));
    final gradesAsync = ref.watch(studentGradesProvider(user.id));
    final averageGradeAsync = ref.watch(studentAverageGradeProvider(user.id));
    final teacherAsync = ref.watch(assignedTeacherProvider(user.id));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.dashboard),
        actions: [
          IconButton(
            icon: const Icon(Icons.message_outlined),
            onPressed: () => context.go('/messages'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(studentAppointmentsProvider(user.id));
          ref.invalidate(studentGradesProvider(user.id));
          ref.invalidate(studentAverageGradeProvider(user.id));
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWelcomeCard(context, user.firstName, user.fullName),
              const SizedBox(height: 24),
              teacherAsync.when(
                data: (teacher) => teacher != null
                    ? _buildTeacherCard(context, teacher.fullName)
                    : _buildNoTeacherCard(context),
                loading: () => const AppCard(child: AppLoading()),
                error: (_, __) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 16),
              _buildQuickActions(context, l10n),
              const SizedBox(height: 24),
              Text(l10n.todaysSchedule, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              appointmentsAsync.when(
                data: (appointments) {
                  final todaysAppointments = appointments.where((a) {
                    final today = DateTime.now();
                    return a.requestedDate.year == today.year &&
                        a.requestedDate.month == today.month &&
                        a.requestedDate.day == today.day;
                  }).toList();

                  if (todaysAppointments.isEmpty) {
                    return AppEmptyState(
                      icon: Icons.calendar_today_outlined,
                      title: l10n.noAppointments,
                    );
                  }

                  return Column(
                    children: todaysAppointments
                        .map((a) => _buildAppointmentCard(context, a.status.name, a.requestedTime))
                        .toList(),
                  );
                },
                loading: () => const AppLoading(),
                error: (e, _) => Text('Error: $e'),
              ),
              const SizedBox(height: 24),
              Text(l10n.recentGrades, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              gradesAsync.when(
                data: (grades) {
                  if (grades.isEmpty) {
                    return AppEmptyState(
                      icon: Icons.grade_outlined,
                      title: l10n.noGrades,
                    );
                  }

                  return Column(
                    children: grades.take(3).map((g) => _buildGradeCard(context, g.subject, g.gradeValue, g.gradeType.name)).toList(),
                  );
                },
                loading: () => const AppLoading(),
                error: (e, _) => Text('Error: $e'),
              ),
              averageGradeAsync.when(
                data: (avg) => avg > 0
                    ? Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: AppCard(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(l10n.averageGrade),
                              Text(
                                avg.toStringAsFixed(2),
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      color: AppTheme.primaryColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeCard(BuildContext context, String firstName, String fullName) {
    return AppCard(
      color: AppTheme.primaryColor,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${AppLocalizations.of(context)!.welcome}، $firstName',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  fullName,
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          const Icon(Icons.menu_book_rounded, color: Colors.white, size: 48),
        ],
      ),
    );
  }

  Widget _buildTeacherCard(BuildContext context, String teacherName) {
    final l10n = AppLocalizations.of(context)!;
    return AppCard(
      child: Row(
        children: [
          AppAvatar(name: teacherName, radius: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.teacherName, style: Theme.of(context).textTheme.bodySmall),
                Text(teacherName, style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.message_outlined),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildNoTeacherCard(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AppCard(
      color: Colors.orange.withOpacity(0.1),
      child: Row(
        children: [
          const Icon(Icons.warning_amber, color: Colors.orange),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              l10n.noTeacherAssigned,
              style: const TextStyle(color: Colors.orange),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, AppLocalizations l10n) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildQuickActionCard(context, l10n.scheduleAppointment, Icons.calendar_month, () => context.go('/student/schedule-appointment')),
        _buildQuickActionCard(context, l10n.uploadRecording, Icons.upload_file, () => context.go('/student/upload')),
        _buildQuickActionCard(context, l10n.myAppointments, Icons.event_available, () => context.go('/student/my-appointments')),
        _buildQuickActionCard(context, l10n.myGrades, Icons.grade, () => context.go('/student/my-grades')),
      ],
    );
  }

  Widget _buildQuickActionCard(BuildContext context, String title, IconData icon, VoidCallback onTap) {
    return AppCard(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 32, color: AppTheme.primaryColor),
          const SizedBox(height: 8),
          Text(title, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleSmall),
        ],
      ),
    );
  }

  Widget _buildAppointmentCard(BuildContext context, String status, String time) {
    final l10n = AppLocalizations.of(context)!;
    return AppCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(time, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(status)),
          AppBadge(text: status, color: _getStatusColor(status)),
        ],
      ),
    );
  }

  Widget _buildGradeCard(BuildContext context, String subject, double value, String type) {
    return AppCard(
      child: Row(
        children: [
          Expanded(child: Text(subject)),
          Text('$value', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppTheme.primaryColor)),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'accepted':
        return AppTheme.successColor.withOpacity(0.2);
      case 'rejected':
        return AppTheme.errorColor.withOpacity(0.2);
      case 'amended':
        return AppTheme.warningColor.withOpacity(0.2);
      default:
        return AppTheme.infoColor.withOpacity(0.2);
    }
  }
}