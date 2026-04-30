import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/appointment_provider.dart';
import '../../models/appointment.dart';
import '../../widgets/common/common_widgets.dart';
import '../../config/app_config.dart';

class AppointmentRequests extends ConsumerWidget {
  const AppointmentRequests({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final user = ref.watch(currentUserProvider);
    if (user == null) return const Scaffold(body: AppLoading());

    final pendingAsync = ref.watch(pendingAppointmentsProvider(user.id));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.pendingRequests),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/teacher/dashboard')),
      ),
      body: pendingAsync.when(
        data: (appointments) {
          if (appointments.isEmpty) {
            return AppEmptyState(icon: Icons.check_circle_outline, title: l10n.noAppointments);
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(pendingAppointmentsProvider(user.id)),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: appointments.length,
              itemBuilder: (context, index) {
                final appointment = appointments[index];
                return _AppointmentRequestCard(appointment: appointment, userId: user.id);
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

class _AppointmentRequestCard extends ConsumerWidget {
  final Appointment appointment;
  final String userId;

  const _AppointmentRequestCard({required this.appointment, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppAvatar(name: appointment.student?.fullName ?? '', radius: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(appointment.student?.fullName ?? '', style: Theme.of(context).textTheme.titleMedium),
                    Text('${appointment.requestedDate.day}/${appointment.requestedDate.month}/${appointment.requestedDate.year} - ${appointment.requestedTime}'),
                  ],
                ),
              ),
            ],
          ),
          if (appointment.purpose != null && appointment.purpose!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text('${l10n.purpose}: ${appointment.purpose}'),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _showAmendDialog(context, ref),
                  child: Text(l10n.amend),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _accept(context, ref),
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.successColor),
                  child: Text(l10n.accept),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _reject(context, ref),
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
                  child: Text(l10n.reject),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _accept(BuildContext context, WidgetRef ref) async {
    await ref.read(teacherAppointmentNotifierProvider(userId).notifier).acceptAppointment(appointment.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.appointmentAccepted), backgroundColor: Colors.green));
    }
  }

  Future<void> _reject(BuildContext context, WidgetRef ref) async {
    await ref.read(teacherAppointmentNotifierProvider(userId).notifier).rejectAppointment(appointment.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.appointmentRejected), backgroundColor: Colors.orange));
    }
  }

  void _showAmendDialog(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    DateTime selectedDate = appointment.requestedDate;
    TimeOfDay selectedTime = TimeOfDay.now();
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.amend),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(l10n.selectDate),
              subtitle: Text('${selectedDate.day}/${selectedDate.month}/${selectedDate.year}'),
              onTap: () async {
                final date = await showDatePicker(context: ctx, initialDate: selectedDate, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
                if (date != null) selectedDate = date;
              },
            ),
            ListTile(
              title: Text(l10n.selectTime),
              subtitle: Text('${selectedTime.hour}:${selectedTime.minute}'),
              onTap: () async {
                final time = await showTimePicker(context: ctx, initialTime: selectedTime);
                if (time != null) selectedTime = time;
              },
            ),
            TextField(controller: notesController, decoration: InputDecoration(labelText: l10n.teacherNotes), maxLines: 2),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
          ElevatedButton(
            onPressed: () async {
              await ref.read(teacherAppointmentNotifierProvider(userId).notifier).amendAppointment(
                    appointment.id,
                    amendedDate: selectedDate,
                    amendedTime: '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}',
                    teacherNotes: notesController.text.isNotEmpty ? notesController.text : null,
                  );
              if (context.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.appointmentAmended), backgroundColor: Colors.green));
              }
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }
}