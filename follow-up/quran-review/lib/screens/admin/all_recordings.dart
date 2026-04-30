import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../providers/recording_provider.dart';
import '../../widgets/common/common_widgets.dart';

class AllRecordings extends ConsumerWidget {
  const AllRecordings({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final recordingsAsync = ref.watch(allRecordingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.allRecordings),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/admin/dashboard')),
      ),
      body: recordingsAsync.when(
        data: (recordings) {
          if (recordings.isEmpty) return AppEmptyState(icon: Icons.mic_off, title: l10n.noRecordings);
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(allRecordingsProvider),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: recordings.length,
              itemBuilder: (context, index) {
                final r = recordings[index];
                return AppCard(
                  child: Row(
                    children: [
                      Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.mic, color: Colors.blue)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(r.fileName, style: Theme.of(context).textTheme.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                            Text('${r.student?.fullName ?? ''} - ${r.createdAt.day}/${r.createdAt.month}', style: Theme.of(context).textTheme.bodySmall),
                          ],
                        ),
                      ),
                      AppBadge(text: r.isReviewed ? l10n.review : l10n.notReviewed, color: r.isReviewed ? Colors.green.withOpacity(0.2) : Colors.orange.withOpacity(0.2)),
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

class AppAvatar extends StatelessWidget {
  final String name;
  final double radius;
  const AppAvatar({super.key, required this.name, this.radius = 24});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(radius: radius, backgroundColor: Colors.blue.withOpacity(0.2));
  }
}