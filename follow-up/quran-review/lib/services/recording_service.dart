import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/recording.dart';

class RecordingService {
  final SupabaseClient _supabase;

  RecordingService(this._supabase);

  Future<List<Recording>> getStudentRecordings(String studentId) async {
    final response = await _supabase
        .from('recordings')
        .select('''
          *,
          student:profiles!student_id(*),
          teacher:profiles!teacher_id(*)
        ''')
        .eq('student_id', studentId)
        .order('created_at', ascending: false);

    return (response as List).map((e) => Recording.fromJson(e)).toList();
  }

  Future<List<Recording>> getTeacherRecordings(String teacherId) async {
    final response = await _supabase
        .from('recordings')
        .select('''
          *,
          student:profiles!student_id(*),
          teacher:profiles!teacher_id(*)
        ''')
        .eq('teacher_id', teacherId)
        .order('created_at', ascending: false);

    return (response as List).map((e) => Recording.fromJson(e)).toList();
  }

  Future<List<Recording>> getAllRecordings() async {
    final response = await _supabase
        .from('recordings')
        .select('''
          *,
          student:profiles!student_id(*),
          teacher:profiles!teacher_id(*)
        ''')
        .order('created_at', ascending: false);

    return (response as List).map((e) => Recording.fromJson(e)).toList();
  }

  Future<List<Recording>> getPendingReviewRecordings(String teacherId) async {
    final response = await _supabase
        .from('recordings')
        .select('''
          *,
          student:profiles!student_id(*),
          teacher:profiles!teacher_id(*)
        ''')
        .eq('teacher_id', teacherId)
        .eq('reviewed', false)
        .order('created_at');

    return (response as List).map((e) => Recording.fromJson(e)).toList();
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
    final fileBytes = await _readFileBytes(filePath);
    await _supabase.storage.from('recordings').uploadBinary(
      '$studentId/$fileName',
      fileBytes,
    );

    final publicUrl = _supabase.storage.from('recordings').getPublicUrl(
          '$studentId/$fileName',
        );

    final response = await _supabase.from('recordings').insert({
      'student_id': studentId,
      'teacher_id': teacherId,
      'file_url': publicUrl,
      'file_type': fileType,
      'file_name': fileName,
      'file_size': fileSize,
      'description': description,
      'reviewed': false,
    }).select('''
      *,
      student:profiles!student_id(*),
      teacher:profiles!teacher_id(*)
    ''').single();

    return Recording.fromJson(response);
  }

  Future<Recording> markAsReviewed(
    String id,
    String reviewedBy,
  ) async {
    final response = await _supabase
        .from('recordings')
        .update({
          'reviewed': true,
          'reviewed_at': DateTime.now().toIso8601String(),
          'reviewed_by': reviewedBy,
        })
        .eq('id', id)
        .select('''
          *,
          student:profiles!student_id(*),
          teacher:profiles!teacher_id(*)
        ''')
        .single();

    return Recording.fromJson(response);
  }

  Future<void> deleteRecording(String id) async {
    await _supabase.from('recordings').delete().eq('id', id);
  }

  Future<String> uploadFile({
    required String bucket,
    required String path,
    required String fileName,
    required Uint8List bytes,
    String? contentType,
  }) async {
    await _supabase.storage.from(bucket).uploadBinary(
          '$path/$fileName',
          bytes,
          fileOptions: FileOptions(contentType: contentType),
        );

    return _supabase.storage.from(bucket).getPublicUrl('$path/$fileName');
  }

  Future<void> deleteFile(String url) async {
    final uri = Uri.parse(url);
    final path = uri.pathSegments.sublist(2).join('/');
    await _supabase.storage.from('recordings').remove([path]);
  }

  Future<Uint8List> _readFileBytes(String path) async {
    final file = await Future.value(path);
    return Uint8List.fromList(file.codeUnits);
  }
}