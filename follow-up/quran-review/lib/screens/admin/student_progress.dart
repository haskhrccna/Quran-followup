import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../providers/user_provider.dart';
import '../../widgets/common/common_widgets.dart';

class StudentProgress extends ConsumerWidget {
  const StudentProgress({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final studentsAsync = ref.watch(studentsProvider('active'));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.studentProgress),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/admin/dashboard')),
      ),
      body: studentsAsync.when(
        data: (students) {
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: students.length,
            itemBuilder: (context, index) {
              final student = students[index];
              return AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        AppAvatar(name: student.fullName, radius: 24),
                        const SizedBox(width: 12),
                        Expanded(child: Text(student.fullName, style: Theme.of(context).textTheme.titleMedium)),
                        IconButton(icon: const Icon(Icons.chevron_right), onPressed: () {}),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildStat(context, 'Teacher', '--', Icons.school),
                        _buildStat(context, 'Grades', '0', Icons.grade),
                        _buildStat(context, 'Avg', '0', Icons.trending_up),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const AppLoading(),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildStat(BuildContext context, String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: Colors.grey.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
        child: Column(
          children: [
            Icon(icon, size: 20, color: Colors.grey),
            const SizedBox(height: 4),
            Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

