import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/common_widgets.dart';
import '../../config/app_config.dart';

class TeacherProfile extends ConsumerWidget {
  const TeacherProfile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final user = ref.watch(currentUserProvider);
    if (user == null) return const Scaffold(body: AppLoading());

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.profile),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/teacher/dashboard')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            AppAvatar(name: user.fullName, radius: 50),
            const SizedBox(height: 16),
            Text(user.fullName, style: Theme.of(context).textTheme.headlineSmall),
            Text(user.email, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary)),
            const SizedBox(height: 32),
            ListTile(leading: const Icon(Icons.edit), title: Text(l10n.editProfile), onTap: () {}),
            ListTile(leading: const Icon(Icons.lock), title: Text(l10n.changePassword), onTap: () {}),
            ListTile(leading: const Icon(Icons.language), title: Text(l10n.changeLanguage), onTap: () {}),
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

