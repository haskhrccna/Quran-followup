import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/appointment_provider.dart';
import '../../models/appointment.dart';
import '../../widgets/common/common_widgets.dart';
import '../../config/app_config.dart';

class MyAppointments extends ConsumerWidget {
  const MyAppointments({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final user = ref.watch(currentUserProvider);

    if (user == null) return const Scaffold(body: AppLoading());

    final appointmentsAsync = ref.watch(studentAppointmentsProvider(user.id));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.myAppointments),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/student/dashboard')),
      ),
      body: appointmentsAsync.when(
        data: (appointments) {
          if (appointments.isEmpty) {
            return AppEmptyState(
              icon: Icons.event_busy,
              title: l10n.noAppointments,
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(studentAppointmentsProvider(user.id)),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: appointments.length,
              itemBuilder: (context, index) {
                final appointment = appointments[index];
                return _AppointmentCard(appointment: appointment);
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

class _AppointmentCard extends StatelessWidget {
  final Appointment appointment;

  const _AppointmentCard({required this.appointment});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppAvatar(name: appointment.teacher?.fullName ?? 'Teacher', radius: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(appointment.teacher?.fullName ?? '', style: Theme.of(context).textTheme.titleMedium),
                    Text(
                      '${appointment.requestedDate.day}/${appointment.requestedDate.month}/${appointment.requestedDate.year}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              AppBadge(text: _getStatusText(appointment.status, l10n), color: _getStatusColor(appointment.status)),
            ],
          ),
          if (appointment.purpose != null && appointment.purpose!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text('${l10n.purpose}: ${appointment.purpose}'),
          ],
          if (appointment.teacherNotes != null && appointment.teacherNotes!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('${l10n.teacherNotes}: ${appointment.teacherNotes}', style: const TextStyle(fontStyle: FontStyle.italic)),
            ),
          ],
        ],
      ),
    );
  }

  String _getStatusText(AppointmentStatus status, AppLocalizations l10n) {
    switch (status) {
      case AppointmentStatus.requested:
        return l10n.requested;
      case AppointmentStatus.accepted:
        return l10n.accepted;
      case AppointmentStatus.amended:
        return l10n.amended;
      case AppointmentStatus.rejected:
        return l10n.rejected;
      case AppointmentStatus.completed:
        return l10n.completed;
      case AppointmentStatus.cancelled:
        return l10n.cancelled;
    }
  }

  Color _getStatusColor(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.accepted:
        return AppTheme.successColor.withOpacity(0.2);
      case AppointmentStatus.rejected:
        return AppTheme.errorColor.withOpacity(0.2);
      case AppointmentStatus.amended:
        return AppTheme.warningColor.withOpacity(0.2);
      case AppointmentStatus.completed:
        return AppTheme.primaryColor.withOpacity(0.2);
      default:
        return AppTheme.infoColor.withOpacity(0.2);
    }
  }
}