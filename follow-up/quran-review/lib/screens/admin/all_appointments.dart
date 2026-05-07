import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/appointment_provider.dart';
import '../../widgets/common/common_widgets.dart';

class AllAppointments extends ConsumerWidget {
  const AllAppointments({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final appointmentsAsync = ref.watch(allAppointmentsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.allAppointments),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/admin/dashboard')),
      ),
      body: appointmentsAsync.when(
        data: (appointments) {
          if (appointments.isEmpty) return AppEmptyState(icon: Icons.event_busy, title: l10n.noAppointments);
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(allAppointmentsProvider),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: appointments.length,
              itemBuilder: (context, index) {
                final a = appointments[index];
                return AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          AppAvatar(name: a.student?.fullName ?? '', radius: 20),
                          const SizedBox(width: 8),
                          Expanded(child: Text(a.student?.fullName ?? '', style: Theme.of(context).textTheme.titleSmall)),
                          AppBadge(text: a.status.name, color: _getStatusColor(a.status.name)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.school, size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(a.teacher?.fullName ?? '', style: Theme.of(context).textTheme.bodySmall),
                          const Spacer(),
                          Text('${a.requestedDate.day}/${a.requestedDate.month} - ${a.requestedTime}', style: Theme.of(context).textTheme.bodySmall),
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

  Color _getStatusColor(String status) {
    switch (status) {
      case 'accepted':
        return Colors.green.withValues(alpha: 0.2);
      case 'rejected':
        return Colors.red.withValues(alpha: 0.2);
      default:
        return Colors.blue.withValues(alpha: 0.2);
    }
  }
}

