import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/appointment.dart';
import '../services/appointment_service.dart';
import 'auth_provider.dart';

final appointmentServiceProvider = Provider<AppointmentService>((ref) {
  return AppointmentService(ref.watch(supabaseProvider));
});

final studentAppointmentsProvider = FutureProvider.family<List<Appointment>, String>((ref, studentId) async {
  return ref.watch(appointmentServiceProvider).getStudentAppointments(studentId);
});

final teacherAppointmentsProvider = FutureProvider.family<List<Appointment>, String>((ref, teacherId) async {
  return ref.watch(appointmentServiceProvider).getTeacherAppointments(teacherId);
});

final pendingAppointmentsProvider = FutureProvider.family<List<Appointment>, String>((ref, teacherId) async {
  return ref.watch(appointmentServiceProvider).getPendingAppointments(teacherId);
});

final todaysAppointmentsProvider = FutureProvider.family<List<Appointment>, String>((ref, teacherId) async {
  return ref.watch(appointmentServiceProvider).getTodaysAppointments(teacherId);
});

final allAppointmentsProvider = FutureProvider<List<Appointment>>((ref) async {
  return ref.watch(appointmentServiceProvider).getAllAppointments();
});

class AppointmentNotifier extends StateNotifier<AsyncValue<List<Appointment>>> {
  final AppointmentService _service;
  final String? _teacherId;
  final String? _studentId;

  AppointmentNotifier(this._service, this._teacherId, this._studentId) : super(const AsyncValue.loading()) {
    refresh();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      List<Appointment> appointments;
      if (_teacherId != null) {
        appointments = await _service.getTeacherAppointments(_teacherId!);
      } else if (_studentId != null) {
        appointments = await _service.getStudentAppointments(_studentId!);
      } else {
        appointments = await _service.getAllAppointments();
      }
      state = AsyncValue.data(appointments);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<Appointment> createAppointment({
    required String studentId,
    required String teacherId,
    required DateTime requestedDate,
    required String requestedTime,
    String? purpose,
  }) async {
    final appointment = await _service.createAppointment(
      studentId: studentId,
      teacherId: teacherId,
      requestedDate: requestedDate,
      requestedTime: requestedTime,
      purpose: purpose,
    );
    await refresh();
    return appointment;
  }

  Future<Appointment> acceptAppointment(String id) async {
    final appointment = await _service.updateAppointmentStatus(id, AppointmentStatus.accepted);
    await refresh();
    return appointment;
  }

  Future<Appointment> amendAppointment(
    String id, {
    required DateTime amendedDate,
    required String amendedTime,
    String? teacherNotes,
  }) async {
    final appointment = await _service.updateAppointmentStatus(
      id,
      AppointmentStatus.amended,
      amendedDate: amendedDate,
      amendedTime: amendedTime,
      teacherNotes: teacherNotes,
    );
    await refresh();
    return appointment;
  }

  Future<Appointment> rejectAppointment(String id, {String? teacherNotes}) async {
    final appointment = await _service.updateAppointmentStatus(
      id,
      AppointmentStatus.rejected,
      teacherNotes: teacherNotes,
    );
    await refresh();
    return appointment;
  }

  Future<Appointment> completeAppointment(String id) async {
    final appointment = await _service.updateAppointmentStatus(id, AppointmentStatus.completed);
    await refresh();
    return appointment;
  }

  Future<void> deleteAppointment(String id) async {
    await _service.deleteAppointment(id);
    await refresh();
  }
}

final teacherAppointmentNotifierProvider = StateNotifierProvider.family<
    AppointmentNotifier, AsyncValue<List<Appointment>>, String>((ref, teacherId) {
  return AppointmentNotifier(
    ref.watch(appointmentServiceProvider),
    teacherId,
    null,
  );
});

final studentAppointmentNotifierProvider = StateNotifierProvider.family<
    AppointmentNotifier, AsyncValue<List<Appointment>>, String>((ref, studentId) {
  return AppointmentNotifier(
    ref.watch(appointmentServiceProvider),
    null,
    studentId,
  );
});