import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../config/app_config.dart';

class StudentProfile extends ConsumerWidget {
  const StudentProfile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final user = ref.watch(currentUserProvider);

    if (user == null) return const Scaffold(body: AppLoading());

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.profile),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/student/dashboard')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            AppAvatar(name: user.fullName, radius: 50),
            const SizedBox(height: 16),
            Text(user.fullName, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text(user.email, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary)),
            const SizedBox(height: 32),
            _buildMenuItem(context, l10n.editProfile, Icons.edit, () {}),
            _buildMenuItem(context, l10n.changePassword, Icons.lock, () {}),
            _buildMenuItem(context, l10n.changeLanguage, Icons.language, () {}),
            _buildMenuItem(context, l10n.notifications, Icons.notifications, () {}),
            _buildMenuItem(context, l10n.logout, Icons.logout, () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            }, isDestructive: true),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, String title, IconData icon, VoidCallback onTap, {bool isDestructive = false}) {
    return ListTile(
      leading: Icon(icon, color: isDestructive ? Colors.red : null),
      title: Text(title, style: TextStyle(color: isDestructive ? Colors.red : null)),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}