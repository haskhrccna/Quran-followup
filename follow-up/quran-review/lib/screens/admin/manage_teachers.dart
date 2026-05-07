import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/user_provider.dart';
import '../../widgets/common/common_widgets.dart';
import '../../config/app_config.dart';

class ManageTeachers extends ConsumerStatefulWidget {
  const ManageTeachers({super.key});

  @override
  ConsumerState<ManageTeachers> createState() => _ManageTeachersState();
}

class _ManageTeachersState extends ConsumerState<ManageTeachers> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final teachersAsync = ref.watch(teachersProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.addTeacher),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/admin/dashboard')),
      ),
      body: teachersAsync.when(
        data: (teachers) {
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(teachersProvider),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: teachers.length,
              itemBuilder: (context, index) {
                final teacher = teachers[index];
                return AppCard(
                  child: Row(
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
                      IconButton(icon: const Icon(Icons.edit, color: AppTheme.infoColor), onPressed: () => _showEditDialog(context, teacher.id, teacher.fullName)),
                      IconButton(icon: const Icon(Icons.lock_reset, color: AppTheme.warningColor), onPressed: () => _resetPassword(context, teacher.id)),
                      IconButton(icon: const Icon(Icons.delete, color: AppTheme.errorColor), onPressed: () => _confirmDelete(context, teacher.id, l10n)),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context, l10n),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddDialog(BuildContext context, AppLocalizations l10n) {
    final firstNameController = TextEditingController();
    final lastNameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.addTeacher),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: firstNameController, decoration: InputDecoration(labelText: l10n.firstName)),
              const SizedBox(height: 8),
              TextField(controller: lastNameController, decoration: InputDecoration(labelText: l10n.lastName)),
              const SizedBox(height: 8),
              TextField(controller: emailController, decoration: InputDecoration(labelText: l10n.email), keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 8),
              TextField(controller: passwordController, decoration: InputDecoration(labelText: l10n.password), obscureText: true),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
          ElevatedButton(
            onPressed: () async {
              try {
                await ref.read(userNotifierProvider.notifier).createTeacher(
                      email: emailController.text.trim(),
                      password: passwordController.text,
                      firstName: firstNameController.text.trim(),
                      lastName: lastNameController.text.trim(),
                    );
                ref.invalidate(teachersProvider);
                if (context.mounted) Navigator.pop(ctx);
              } catch (e) {
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
              }
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, String id, String currentName) {
    final parts = currentName.split(' ');
    final firstNameController = TextEditingController(text: parts.isNotEmpty ? parts[0] : '');
    final lastNameController = TextEditingController(text: parts.length > 1 ? parts[1] : '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Teacher'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: firstNameController, decoration: const InputDecoration(labelText: 'First Name')),
            const SizedBox(height: 8),
            TextField(controller: lastNameController, decoration: const InputDecoration(labelText: 'Last Name')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await ref.read(userNotifierProvider.notifier).updateUser(id, {
                'first_name': firstNameController.text.trim(),
                'last_name': lastNameController.text.trim(),
              });
              ref.invalidate(teachersProvider);
              if (context.mounted) Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _resetPassword(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Password'),
        content: const Text('Enter new password for this teacher'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await ref.read(userNotifierProvider.notifier).resetPassword(id, 'newPassword123');
              if (context.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password reset to: newPassword123'), backgroundColor: Colors.green));
              }
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, String id, AppLocalizations l10n) {
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
              ref.invalidate(teachersProvider);
              if (context.mounted) Navigator.pop(ctx);
            },
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
  }
}

