import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/common/common_widgets.dart';

class AssignTeachers extends ConsumerWidget {
  const AssignTeachers({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final user = ref.watch(currentUserProvider);
    if (user == null) return const Scaffold(body: AppLoading());

    final studentsAsync = ref.watch(studentsProvider('active'));
    final teachersAsync = ref.watch(teachersProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.assignTeacher),
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
                child: Row(
                  children: [
                    AppAvatar(name: student.fullName, radius: 24),
                    const SizedBox(width: 12),
                    Expanded(child: Text(student.fullName, style: Theme.of(context).textTheme.titleMedium)),
                    teachersAsync.when(
                      data: (teachers) => DropdownButton<String>(
                        hint: Text(l10n.selectTeacher),
                        value: null,
                        items: teachers.map((t) => DropdownMenuItem(value: t.id, child: Text(t.fullName))).toList(),
                        onChanged: (teacherId) async {
                          if (teacherId != null) {
                            await ref.read(userNotifierProvider.notifier).assignTeacher(student.id, teacherId, user.id);
                            if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.assignedSuccessfully), backgroundColor: Colors.green));
                          }
                        },
                      ),
                      loading: () => const CircularProgressIndicator(),
                      error: (_, __) => const SizedBox.shrink(),
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
}

