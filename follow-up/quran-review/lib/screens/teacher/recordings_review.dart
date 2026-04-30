import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../providers/auth_provider.dart';
import '../../providers/recording_provider.dart';
import '../../widgets/common/common_widgets.dart';
import '../../config/app_config.dart';

class RecordingsReview extends ConsumerWidget {
  const RecordingsReview({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final user = ref.watch(currentUserProvider);
    if (user == null) return const Scaffold(body: AppLoading());

    final recordingsAsync = ref.watch(teacherRecordingsProvider(user.id));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.review),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/teacher/dashboard')),
      ),
      body: recordingsAsync.when(
        data: (recordings) {
          if (recordings.isEmpty) return AppEmptyState(icon: Icons.mic_off, title: l10n.noRecordings);
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(teacherRecordingsProvider(user.id)),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: recordings.length,
              itemBuilder: (context, index) {
                final recording = recordings[index];
                return AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          AppAvatar(name: recording.student?.fullName ?? '', radius: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(recording.student?.fullName ?? '', style: Theme.of(context).textTheme.titleSmall),
                                Text('${recording.fileSizeFormatted} • ${recording.createdAt.day}/${recording.createdAt.month}', style: Theme.of(context).textTheme.bodySmall),
                              ],
                            ),
                          ),
                          AppBadge(
                            text: recording.isReviewed ? l10n.review : l10n.notReviewed,
                            color: recording.isReviewed ? AppTheme.successColor.withOpacity(0.2) : AppTheme.warningColor.withOpacity(0.2),
                          ),
                        ],
                      ),
                      if (recording.description != null && recording.description!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(recording.description!, style: Theme.of(context).textTheme.bodySmall),
                      ],
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          if (recording.isAudio)
                            IconButton(icon: const Icon(Icons.play_circle), onPressed: () {}, color: AppTheme.primaryColor),
                          IconButton(icon: const Icon(Icons.download), onPressed: () {}),
                          if (!recording.isReviewed)
                            IconButton(
                              icon: const Icon(Icons.check),
                              onPressed: () async {
                                await ref.read(teacherRecordingNotifierProvider(user.id).notifier).markAsReviewed(recording.id, user.id);
                                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.recordingMarkedReviewed), backgroundColor: Colors.green));
                              },
                              color: AppTheme.successColor,
                            ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => _confirmDelete(context, ref, recording.id, l10n),
                            color: AppTheme.errorColor,
                          ),
                        ],
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
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, String id, AppLocalizations l10n) {
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
              await ref.read(teacherRecordingNotifierProvider(ref.read(currentUserProvider)!.id).notifier).deleteRecording(id);
              if (context.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.recordingDeleted), backgroundColor: Colors.orange));
              }
            },
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
  }
}