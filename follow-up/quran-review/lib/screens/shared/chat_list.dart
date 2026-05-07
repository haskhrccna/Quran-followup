import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/message_provider.dart';
import '../../widgets/common/common_widgets.dart';

class ChatList extends ConsumerWidget {
  const ChatList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final user = ref.watch(currentUserProvider);
    if (user == null) return const Scaffold(body: AppLoading());

    final conversationsAsync = ref.watch(conversationsProvider(user.id));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.messages),
      ),
      body: conversationsAsync.when(
        data: (conversations) {
          if (conversations.isEmpty) return AppEmptyState(icon: Icons.message_outlined, title: l10n.noMessages);
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(conversationsProvider(user.id)),
            child: ListView.builder(
              itemCount: conversations.length,
              itemBuilder: (context, index) {
                final conv = conversations[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.2),
                    child: Text(conv.otherUser.fullName[0], style: TextStyle(color: Theme.of(context).primaryColor)),
                  ),
                  title: Text(conv.otherUser.fullName),
                  subtitle: Text(conv.lastMessage.content ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: conv.unreadCount > 0
                      ? Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(color: Theme.of(context).primaryColor, shape: BoxShape.circle),
                          child: Text('$conv.unreadCount', style: const TextStyle(color: Colors.white, fontSize: 12)),
                        )
                      : null,
                  onTap: () => context.go('/chat/${conv.otherUser.id}'),
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