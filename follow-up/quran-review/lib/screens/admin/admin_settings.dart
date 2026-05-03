import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/message_provider.dart';
import '../../config/app_config.dart';

class AdminSettings extends ConsumerWidget {
  const AdminSettings({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final locale = ref.watch(localeProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.adminSettings),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/admin/dashboard')),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(l10n.language),
            subtitle: Text(locale.languageCode == 'ar' ? l10n.arabic : l10n.english),
            onTap: () {
              ref.read(localeProvider.notifier).toggleLocale();
            },
          ),
          const Divider(),
          ListTile(leading: const Icon(Icons.broadcast), title: Text(l10n.broadcast), onTap: () => _showBroadcastDialog(context, ref, l10n)),
          const Divider(),
          ListTile(leading: const Icon(Icons.logout, color: Colors.red), title: Text(l10n.logout, style: const TextStyle(color: Colors.red)), onTap: () async {
            await ref.read(authProvider.notifier).logout();
            if (context.mounted) context.go('/login');
          }),
        ],
      ),
    );
  }

  void _showBroadcastDialog(BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    final messageController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.broadcast),
        content: TextField(controller: messageController, decoration: InputDecoration(labelText: l10n.typeMessage), maxLines: 3),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
          ElevatedButton(
            onPressed: () async {
              if (messageController.text.isNotEmpty) {
                final user = ref.read(currentUserProvider);
                if (user != null) {
                  await ref.read(messageNotifierProvider.notifier).sendBroadcast(adminId: user.id, content: messageController.text);
                  if (context.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.broadcastSent), backgroundColor: Colors.green));
                  }
                }
              }
            },
            child: Text(l10n.send),
          ),
        ],
      ),
    );
  }
}