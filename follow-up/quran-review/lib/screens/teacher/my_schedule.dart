import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../providers/auth_provider.dart';
import '../../providers/appointment_provider.dart';
import '../../widgets/common/common_widgets.dart';
import '../../config/app_config.dart';

class MySchedule extends ConsumerWidget {
  const MySchedule({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final user = ref.watch(currentUserProvider);
    if (user == null) return const Scaffold(body: AppLoading());

    final appointmentsAsync = ref.watch(teacherAppointmentsProvider(user.id));
    DateTime _focusedDay = DateTime.now();
    DateTime? _selectedDay;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.mySchedule),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/teacher/dashboard')),
      ),
      body: appointmentsAsync.when(
        data: (appointments) {
          final filtered = _selectedDay != null
              ? appointments.where((a) => a.requestedDate.year == _selectedDay!.year && a.requestedDate.month == _selectedDay!.month && a.requestedDate.day == _selectedDay!.day).toList()
              : appointments;
          return Column(
            children: [
              TableCalendar(
                firstDay: DateTime.now().subtract(const Duration(days: 365)),
                lastDay: DateTime.now().add(const Duration(days: 365)),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                onDaySelected: (selectedDay, focusedDay) {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                },
                eventLoader: (day) => appointments.where((a) => a.requestedDate.year == day.year && a.requestedDate.month == day.month && a.requestedDate.day == day.day).toList(),
                calendarStyle: CalendarStyle(
                  selectedDecoration: BoxDecoration(color: AppTheme.primaryColor, shape: BoxShape.circle),
                  todayDecoration: BoxDecoration(color: AppTheme.primaryColor.withOpacity(0.5), shape: BoxShape.circle),
                  markerDecoration: BoxDecoration(color: AppTheme.secondaryColor, shape: BoxShape.circle),
                ),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? AppEmptyState(icon: Icons.event_available, title: l10n.noAppointments)
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final a = filtered[index];
                          return AppCard(
                            child: Row(
                              children: [
                                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppTheme.primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Text(a.requestedTime, style: const TextStyle(fontWeight: FontWeight.bold))),
                                const SizedBox(width: 12),
                                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(a.student?.fullName ?? '', style: Theme.of(context).textTheme.titleSmall),
                                  if (a.purpose != null) Text(a.purpose!, style: Theme.of(context).textTheme.bodySmall),
                                ])),
                                AppBadge(text: a.status.name, color: _getStatusColor(a.status.name)),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
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
        return AppTheme.successColor.withOpacity(0.2);
      case 'rejected':
        return AppTheme.errorColor.withOpacity(0.2);
      default:
        return AppTheme.infoColor.withOpacity(0.2);
    }
  }
}