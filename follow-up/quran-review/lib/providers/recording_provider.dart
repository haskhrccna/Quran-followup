import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/recording.dart';
import '../services/recording_service.dart';
import 'auth_provider.dart';

final recordingServiceProvider = Provider<RecordingService>((ref) {
  return RecordingService(ref.watch(supabaseProvider));
});

final studentRecordingsProvider = FutureProvider.family<List<Recording>, String>((ref, studentId) async {
  return ref.watch(recordingServiceProvider).getStudentRecordings(studentId);
});

final teacherRecordingsProvider = FutureProvider.family<List<Recording>, String>((ref, teacherId) async {
  return ref.watch(recordingServiceProvider).getTeacherRecordings(teacherId);
});

final pendingReviewRecordingsProvider = FutureProvider.family<List<Recording>, String>((ref, teacherId) async {
  return ref.watch(recordingServiceProvider).getPendingReviewRecordings(teacherId);
});

final allRecordingsProvider = FutureProvider<List<Recording>>((ref) async {
  return ref.watch(recordingServiceProvider).getAllRecordings();
});

class RecordingNotifier extends StateNotifier<AsyncValue<List<Recording>>> {
  final RecordingService _service;
  final String? _teacherId;
  final String? _studentId;

  RecordingNotifier(this._service, this._teacherId, this._studentId) : super(const AsyncValue.loading()) {
    refresh();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      List<Recording> recordings;
      if (_teacherId != null) {
        recordings = await _service.getTeacherRecordings(_teacherId);
      } else if (_studentId != null) {
        recordings = await _service.getStudentRecordings(_studentId);
      } else {
        recordings = await _service.getAllRecordings();
      }
      state = AsyncValue.data(recordings);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<Recording> uploadRecording({
    required String studentId,
    required String teacherId,
    required String filePath,
    required String fileName,
    required String fileType,
    int? fileSize,
    String? description,
  }) async {
    final recording = await _service.uploadRecording(
      studentId: studentId,
      teacherId: teacherId,
      filePath: filePath,
      fileName: fileName,
      fileType: fileType,
      fileSize: fileSize,
      description: description,
    );
    await refresh();
    return recording;
  }

  Future<Recording> markAsReviewed(String id, String reviewedBy) async {
    final recording = await _service.markAsReviewed(id, reviewedBy);
    await refresh();
    return recording;
  }

  Future<void> deleteRecording(String id) async {
    await _service.deleteRecording(id);
    await refresh();
  }
}

final teacherRecordingNotifierProvider = StateNotifierProvider.family<
    RecordingNotifier, AsyncValue<List<Recording>>, String>((ref, teacherId) {
  return RecordingNotifier(
    ref.watch(recordingServiceProvider),
    teacherId: teacherId,
    studentId: null,
  );
});

final studentRecordingNotifierProvider = StateNotifierProvider.family<
    RecordingNotifier, AsyncValue<List<Recording>>, String>((ref, studentId) {
  return RecordingNotifier(
    ref.watch(recordingServiceProvider),
    teacherId: null,
    studentId: studentId,
  );
});