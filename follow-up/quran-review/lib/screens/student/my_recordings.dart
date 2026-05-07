import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/recording_provider.dart';
import '../../widgets/common/common_widgets.dart';
import '../../config/app_config.dart';

class MyRecordings extends ConsumerWidget {
  const MyRecordings({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final user = ref.watch(currentUserProvider);

    if (user == null) return const Scaffold(body: AppLoading());

    final recordingsAsync = ref.watch(studentRecordingsProvider(user.id));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.myRecordings),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/student/dashboard')),
      ),
      body: recordingsAsync.when(
        data: (recordings) {
          if (recordings.isEmpty) {
            return AppEmptyState(
              icon: Icons.mic_none,
              title: l10n.noRecordings,
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(studentRecordingsProvider(user.id)),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: recordings.length,
              itemBuilder: (context, index) {
                final recording = recordings[index];
                return AppCard(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          recording.isAudio ? Icons.mic : Icons.insert_drive_file,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(recording.fileName, style: Theme.of(context).textTheme.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 4),
                            Text(
                              '${recording.fileSizeFormatted} • ${recording.createdAt.day}/${recording.createdAt.month}/${recording.createdAt.year}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      AppBadge(
                        text: recording.isReviewed ? l10n.review : l10n.notReviewed,
                        color: recording.isReviewed ? AppTheme.successColor.withValues(alpha: 0.2) : AppTheme.warningColor.withValues(alpha: 0.2),
                      ),
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
        onPressed: () => context.go('/student/upload'),
        child: const Icon(Icons.add),
      ),
    );
  }
}