import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/appointment_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/common/common_widgets.dart';
import '../../config/app_config.dart';

class TeacherDashboard extends ConsumerWidget {
  const TeacherDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final user = ref.watch(currentUserProvider);

    if (user == null) return const Scaffold(body: AppLoading());

    final todaysAsync = ref.watch(todaysAppointmentsProvider(user.id));
    final pendingAsync = ref.watch(pendingAppointmentsProvider(user.id));
    final studentsAsync = ref.watch(assignedStudentsProvider(user.id));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.dashboard),
        actions: [
          IconButton(icon: const Icon(Icons.message_outlined), onPressed: () => context.go('/messages')),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(todaysAppointmentsProvider(user.id));
          ref.invalidate(pendingAppointmentsProvider(user.id));
          ref.invalidate(assignedStudentsProvider(user.id));
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppCard(
                color: AppTheme.primaryColor,
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${l10n.welcome}، ${user.firstName}', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(user.fullName, style: const TextStyle(color: Colors.white70)),
                        ],
                      ),
                    ),
                    const Icon(Icons.school, color: Colors.white, size: 48),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              studentsAsync.when(
                data: (students) => _buildStatsRow(context, l10n.totalStudents, students.length.toString(), Icons.people),
                loading: () => const AppLoading(),
                error: (_, __) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 16),
              pendingAsync.when(
                data: (pending) => _buildStatsRow(context, l10n.pendingRequests, pending.length.toString(), Icons.pending_actions),
                loading: () => const AppLoading(),
                error: (_, __) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 24),
              _buildQuickActions(context, l10n),
              const SizedBox(height: 24),
              Text(l10n.pendingRequests, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              pendingAsync.when(
                data: (appointments) {
                  if (appointments.isEmpty) {
                    return AppEmptyState(icon: Icons.check_circle_outline, title: l10n.noAppointments);
                  }
                  return Column(
                    children: appointments.take(3).map((a) => AppCard(
                      child: Row(
                        children: [
                          AppAvatar(name: a.student?.fullName ?? '', radius: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(a.student?.fullName ?? '', style: Theme.of(context).textTheme.titleSmall),
                                Text('${a.requestedDate.day}/${a.requestedDate.month} - ${a.requestedTime}'),
                              ],
                            ),
                          ),
                          TextButton(onPressed: () => context.go('/teacher/appointment-requests'), child: Text(l10n.review)),
                        ],
                      ),
                    )).toList(),
                  );
                },
                loading: () => const AppLoading(),
                error: (e, _) => Text('Error: $e'),
              ),
              const SizedBox(height: 24),
              Text(l10n.todaysSchedule, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              todaysAsync.when(
                data: (appointments) {
                  if (appointments.isEmpty) {
                    return AppEmptyState(icon: Icons.event_available, title: l10n.noAppointments);
                  }
                  return Column(
                    children: appointments.map((a) => AppCard(
                      child: Row(
                        children: [
                          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppTheme.primaryColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: Text(a.requestedTime, style: const TextStyle(fontWeight: FontWeight.bold))),
                          const SizedBox(width: 12),
                          Expanded(child: Text(a.student?.fullName ?? '')),
                          AppBadge(text: a.status.name, color: _getStatusColor(a.status.name)),
                        ],
                      ),
                    )).toList(),
                  );
                },
                loading: () => const AppLoading(),
                error: (e, _) => Text('Error: $e'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsRow(BuildContext context, String title, String value, IconData icon) {
    return AppCard(
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppTheme.primaryColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: AppTheme.primaryColor)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(value, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            Text(title, style: Theme.of(context).textTheme.bodySmall),
          ])),
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
        _buildQuickActionCard(context, l10n.pendingRequests, Icons.pending_actions, () => context.go('/teacher/appointment-requests')),
        _buildQuickActionCard(context, l10n.giveGrade, Icons.grade, () => context.go('/teacher/grade-student')),
        _buildQuickActionCard(context, 'Students', Icons.people, () => context.go('/teacher/student-list')),
        _buildQuickActionCard(context, l10n.review, Icons.rate_review, () => context.go('/teacher/recordings-review')),
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

  Color _getStatusColor(String status) {
    switch (status) {
      case 'accepted':
        return AppTheme.successColor.withValues(alpha: 0.2);
      case 'rejected':
        return AppTheme.errorColor.withValues(alpha: 0.2);
      case 'amended':
        return AppTheme.warningColor.withValues(alpha: 0.2);
      default:
        return AppTheme.infoColor.withValues(alpha: 0.2);
    }
  }
}