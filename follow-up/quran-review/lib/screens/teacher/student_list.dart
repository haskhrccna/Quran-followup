import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/common/common_widgets.dart';
import '../../config/app_config.dart';

class StudentList extends ConsumerWidget {
  const StudentList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final user = ref.watch(currentUserProvider);
    if (user == null) return const Scaffold(body: AppLoading());

    final studentsAsync = ref.watch(assignedStudentsProvider(user.id));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.studentName),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/teacher/dashboard')),
      ),
      body: studentsAsync.when(
        data: (students) {
          if (students.isEmpty) {
            return AppEmptyState(icon: Icons.people_outline, title: l10n.noTeacherAssigned);
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(assignedStudentsProvider(user.id)),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: students.length,
              itemBuilder: (context, index) {
                final student = students[index];
                return AppCard(
                  onTap: () => context.go('/chat/${student.id}'),
                  child: Row(
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
                      AppBadge(
                        text: student.isActive ? l10n.accountActive : l10n.accountSuspended,
                        color: student.isActive ? AppTheme.successColor.withValues(alpha: 0.2) : AppTheme.errorColor.withValues(alpha: 0.2),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
        loading: () => const AppLoading(),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}