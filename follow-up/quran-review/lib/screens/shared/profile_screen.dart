import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../config/app_config.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final user = ref.watch(currentUserProvider);
    if (user == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.profile)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
              child: Text(user.fullName[0], style: TextStyle(fontSize: 40, color: AppTheme.primaryColor)),
            ),
            const SizedBox(height: 16),
            Text(user.fullName, style: Theme.of(context).textTheme.headlineSmall),
            Text(user.email, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary)),
            const SizedBox(height: 32),
            ListTile(leading: const Icon(Icons.edit), title: Text(l10n.editProfile), trailing: const Icon(Icons.chevron_right), onTap: () {}),
            ListTile(leading: const Icon(Icons.lock), title: Text(l10n.changePassword), trailing: const Icon(Icons.chevron_right), onTap: () {}),
            ListTile(leading: const Icon(Icons.language), title: Text(l10n.changeLanguage), trailing: const Icon(Icons.chevron_right), onTap: () {}),
            ListTile(leading: const Icon(Icons.notifications), title: Text(l10n.notifications), trailing: const Icon(Icons.chevron_right), onTap: () {}),
            const Divider(),
            ListTile(leading: const Icon(Icons.logout, color: Colors.red), title: Text(l10n.logout, style: const TextStyle(color: Colors.red)), onTap: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            }),
          ],
        ),
      ),
    );
  }
}