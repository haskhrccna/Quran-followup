import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/app_localizations.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/common/common_widgets.dart';
import '../../config/app_config.dart';

class AdminDashboard extends ConsumerWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final user = ref.watch(currentUserProvider);
    if (user == null) return const Scaffold(body: AppLoading());

    final teachersAsync = ref.watch(teachersProvider);
    final studentsAsync = ref.watch(studentsProvider(null));
    final pendingAsync = ref.watch(pendingStudentCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.dashboard),
        actions: [
          IconButton(icon: const Icon(Icons.message_outlined), onPressed: () => context.go('/messages')),
          IconButton(icon: const Icon(Icons.settings), onPressed: () => context.go('/admin/settings')),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(teachersProvider);
          ref.invalidate(studentsProvider(null));
          ref.invalidate(pendingStudentCountProvider);
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
                    const Icon(Icons.admin_panel_settings, color: Colors.white, size: 48),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              teachersAsync.when(
                data: (teachers) => _buildStatCard(context, l10n.totalTeachers, teachers.length.toString(), Icons.school, AppTheme.infoColor),
                loading: () => const AppLoading(),
                error: (_, __) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 12),
              studentsAsync.when(
                data: (students) => _buildStatCard(context, l10n.totalStudents, students.length.toString(), Icons.people, AppTheme.successColor),
                loading: () => const AppLoading(),
                error: (_, __) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 12),
              pendingAsync.when(
                data: (count) => _buildStatCard(context, l10n.pendingApprovals, count.toString(), Icons.pending_actions, AppTheme.warningColor),
                loading: () => const AppLoading(),
                error: (_, __) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 24),
              Text(l10n.recentActivity, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              _buildQuickActions(context, l10n),
              const SizedBox(height: 24),
              SizedBox(height: 200, child: _buildChart()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value, IconData icon, Color color) {
    return AppCard(
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: color)),
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
        _buildActionCard(context, l10n.addTeacher, Icons.person_add, () => context.go('/admin/manage-teachers')),
        _buildActionCard(context, l10n.manageStudents, Icons.people, () => context.go('/admin/manage-students')),
        _buildActionCard(context, l10n.assignTeacher, Icons.assignment_ind, () => context.go('/admin/assign-teachers')),
        _buildActionCard(context, l10n.teacherProgress, Icons.trending_up, () => context.go('/admin/teacher-progress')),
      ],
    );
  }

  Widget _buildActionCard(BuildContext context, String title, IconData icon, VoidCallback onTap) {
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

  Widget _buildChart() {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 10,
        barGroups: [
          BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: 5)]),
          BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: 8)]),
          BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: 3)]),
        ],
      ),
    );
  }
}