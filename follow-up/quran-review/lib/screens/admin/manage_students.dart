import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/common/common_widgets.dart';
import '../../config/app_config.dart';

class ManageStudents extends ConsumerWidget {
  const ManageStudents({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final user = ref.watch(currentUserProvider);
    if (user == null) return const Scaffold(body: AppLoading());

    final pendingAsync = ref.watch(pendingStudentsProvider);
    final activeAsync = ref.watch(studentsProvider('active'));

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.manageStudents),
          leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/admin/dashboard')),
          bottom: TabBar(
            tabs: [
              Tab(text: l10n.pendingApproval),
              Tab(text: l10n.accountActive),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            pendingAsync.when(
              data: (students) {
                if (students.isEmpty) return AppEmptyState(icon: Icons.check_circle, title: l10n.noAppointments);
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: students.length,
                  itemBuilder: (context, index) => _StudentCard(student: students[index], isPending: true, adminId: user.id),
                );
              },
              loading: () => const AppLoading(),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
            activeAsync.when(
              data: (students) {
                if (students.isEmpty) return AppEmptyState(icon: Icons.people_outline, title: l10n.noAppointments);
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: students.length,
                  itemBuilder: (context, index) => _StudentCard(student: students[index], isPending: false, adminId: user.id),
                );
              },
              loading: () => const AppLoading(),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ],
        ),
      ),
    );
  }
}

class _StudentCard extends ConsumerWidget {
  final dynamic student;
  final bool isPending;
  final String adminId;

  const _StudentCard({required this.student, required this.isPending, required this.adminId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final teachersAsync = ref.watch(teachersProvider);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppAvatar(name: student.fullName, radius: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(student.fullName, style: Theme.of(context).textTheme.titleMedium),
                    Text(student.email, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
            ],
          ),
          if (isPending) ...[
            const SizedBox(height: 12),
            teachersAsync.when(
              data: (teachers) => DropdownButtonFormField<String>(
                decoration: InputDecoration(labelText: l10n.assignTeacher, isDense: true),
                items: teachers.map((t) => DropdownMenuItem(value: t.id, child: Text(t.fullName))).toList(),
                onChanged: (teacherId) async {
                  if (teacherId != null) {
                    await ref.read(userNotifierProvider.notifier).acceptStudent(student.id, teacherId, adminId);
                    ref.invalidate(pendingStudentsProvider);
                    ref.invalidate(studentsProvider('active'));
                    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.studentAccepted), backgroundColor: Colors.green));
                  }
                },
              ),
              loading: () => const CircularProgressIndicator(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ] else ...[
            const SizedBox(height: 8),
            Row(
              children: [
                IconButton(icon: const Icon(Icons.assignment_ind, color: AppTheme.infoColor), onPressed: () => context.go('/admin/assign-teachers')),
                IconButton(icon: const Icon(Icons.edit, color: AppTheme.warningColor), onPressed: () {}),
                IconButton(icon: const Icon(Icons.delete, color: AppTheme.errorColor), onPressed: () => _confirmDelete(context, ref, student.id, l10n)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, String id, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteConfirm),
        content: Text(l10n.cannotUndoAction),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
            onPressed: () async {
              await ref.read(userNotifierProvider.notifier).deleteUser(id);
              ref.invalidate(studentsProvider('active'));
              ref.invalidate(pendingStudentsProvider);
              if (context.mounted) Navigator.pop(ctx);
            },
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
  }
}

