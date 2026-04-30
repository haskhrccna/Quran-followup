import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../providers/user_provider.dart';
import '../../widgets/common/common_widgets.dart';

class TeacherProgress extends ConsumerWidget {
  const TeacherProgress({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final teachersAsync = ref.watch(teachersProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.teacherProgress),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/admin/dashboard')),
      ),
      body: teachersAsync.when(
        data: (teachers) {
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: teachers.length,
            itemBuilder: (context, index) {
              final teacher = teachers[index];
              return AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        AppAvatar(name: teacher.fullName, radius: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(teacher.fullName, style: Theme.of(context).textTheme.titleMedium),
                              Text(teacher.email, style: Theme.of(context).textTheme.bodySmall),
                            ],
                          ),
                        ),
                        IconButton(icon: const Icon(Icons.chevron_right), onPressed: () {}),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildStat(context, l10n.studentCount, '0', Icons.people),
                        const SizedBox(width: 16),
                        _buildStat(context, 'Appointments', '0', Icons.event),
                        const SizedBox(width: 16),
                        _buildStat(context, 'Grades', '0', Icons.grade),
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
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: Colors.grey.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
        child: Column(
          children: [
            Icon(icon, size: 20, color: Colors.grey),
            const SizedBox(height: 4),
            Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            Text(label, style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class AppAvatar extends StatelessWidget {
  final String name;
  final double radius;
  const AppAvatar({super.key, required this.name, this.radius = 24});

  @override
  Widget build(BuildContext context) {
    final initials = name.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join();
    return CircleAvatar(radius: radius, backgroundColor: Colors.blue.withOpacity(0.2), child: Text(initials, style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)));
  }
}