import 'dart:io';
import 'dart:ui';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/report.dart';
import '../models/grade.dart';
import '../models/appointment.dart';

class ReportService {
  final SupabaseClient _supabase;

  ReportService(this._supabase);

  Future<Report> generateStudentReport({
    required String teacherId,
    required String studentId,
    required String title,
    required List<Grade> grades,
    required List<Appointment> appointments,
    required double averageGrade,
  }) async {
    final pdfBytes = await _createPdf(
      studentName: await _getUserName(studentId),
      teacherName: await _getUserName(teacherId),
      grades: grades,
      appointments: appointments,
      averageGrade: averageGrade,
    );

    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/report_$studentId.pdf');
    await file.writeAsBytes(pdfBytes);

    final fileUrl = await _uploadPdf(file.path, studentId);

    final response = await _supabase.from('reports').insert({
      'teacher_id': teacherId,
      'student_id': studentId,
      'pdf_url': fileUrl,
      'title': title,
    }).select('''
      *,
      teacher:profiles!teacher_id(*),
      student:profiles!student_id(*)
    ''').single();

    return Report.fromJson(response);
  }

  Future<List<Report>> getStudentReports(String studentId) async {
    final response = await _supabase
        .from('reports')
        .select('''
          *,
          teacher:profiles!teacher_id(*),
          student:profiles!student_id(*)
        ''')
        .eq('student_id', studentId)
        .order('created_at', ascending: false);

    return (response as List).map((e) => Report.fromJson(e)).toList();
  }

  Future<List<Report>> getTeacherReports(String teacherId) async {
    final response = await _supabase
        .from('reports')
        .select('''
          *,
          teacher:profiles!teacher_id(*),
          student:profiles!student_id(*)
        ''')
        .eq('teacher_id', teacherId)
        .order('created_at', ascending: false);

    return (response as List).map((e) => Report.fromJson(e)).toList();
  }

  Future<List<Report>> getAllReports() async {
    final response = await _supabase
        .from('reports')
        .select('''
          *,
          teacher:profiles!teacher_id(*),
          student:profiles!student_id(*)
        ''')
        .order('created_at', ascending: false);

    return (response as List).map((e) => Report.fromJson(e)).toList();
  }

  Future<String> _getUserName(String userId) async {
    final response = await _supabase
        .from('profiles')
        .select('first_name, last_name')
        .eq('id', userId)
        .single();

    return '${response['first_name']} ${response['last_name']}';
  }

  Future<List<int>> _createPdf({
    required String studentName,
    required String teacherName,
    required List<Grade> grades,
    required List<Appointment> appointments,
    required double averageGrade,
  }) async {
    final PdfDocument document = PdfDocument();

    final page = document.pages.add();
    final brush = PdfSolidBrush(PdfColor(0, 0, 0));
    final font = PdfStandardFont(PdfFontFamily.helvetica, 12);
    final titleFont = PdfStandardFont(PdfFontFamily.helvetica, 18, style: PdfFontStyle.bold);
    final headerFont = PdfStandardFont(PdfFontFamily.helvetica, 14, style: PdfFontStyle.bold);

    page.graphics.drawString(
      'Student Progress Report',
      titleFont,
      brush: brush,
      bounds: const Rect.fromLTWH(0, 0, 400, 30),
    );

    page.graphics.drawString(
      'Student: $studentName',
      font,
      brush: brush,
      bounds: const Rect.fromLTWH(0, 40, 400, 20),
    );

    page.graphics.drawString(
      'Teacher: $teacherName',
      font,
      brush: brush,
      bounds: const Rect.fromLTWH(0, 60, 400, 20),
    );

    page.graphics.drawString(
      'Date: ${DateTime.now().toString().split(' ')[0]}',
      font,
      brush: brush,
      bounds: const Rect.fromLTWH(0, 80, 400, 20),
    );

    page.graphics.drawString(
      'Grades Summary',
      headerFont,
      brush: brush,
      bounds: const Rect.fromLTWH(0, 120, 400, 25),
    );

    page.graphics.drawString(
      'Average Grade: ${averageGrade.toStringAsFixed(2)}',
      font,
      brush: brush,
      bounds: const Rect.fromLTWH(0, 150, 400, 20),
    );

    page.graphics.drawString(
      'Total Grades: ${grades.length}',
      font,
      brush: brush,
      bounds: const Rect.fromLTWH(0, 170, 400, 20),
    );

    var yOffset = 200.0;

    if (grades.isNotEmpty) {
      page.graphics.drawString(
        'Detailed Grades:',
        headerFont,
        brush: brush,
        bounds: Rect.fromLTWH(0, yOffset, 400, 25),
      );
      yOffset += 30;

      for (final grade in grades) {
        page.graphics.drawString(
          '${grade.subject} - ${grade.gradeType.name}: ${grade.gradeValue}',
          font,
          brush: brush,
          bounds: Rect.fromLTWH(0, yOffset, 400, 20),
        );
        yOffset += 20;
      }
    }

    yOffset += 20;
    page.graphics.drawString(
      'Appointments Summary',
      headerFont,
      brush: brush,
      bounds: Rect.fromLTWH(0, yOffset, 400, 25),
    );
    yOffset += 30;

    page.graphics.drawString(
      'Total Appointments: ${appointments.length}',
      font,
      brush: brush,
      bounds: Rect.fromLTWH(0, yOffset, 400, 20),
    );
    yOffset += 20;

    final completed = appointments.where((a) => a.isCompleted).length;
    page.graphics.drawString(
      'Completed: $completed',
      font,
      brush: brush,
      bounds: Rect.fromLTWH(0, yOffset, 400, 20),
    );

    final List<int> bytes = document.saveSync();
    document.dispose();

    return bytes;
  }

  Future<String> _uploadPdf(String filePath, String studentId) async {
    final fileName = 'report_${studentId}_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final bytes = await File(filePath).readAsBytes();

    await _supabase.storage.from('report-pdfs').uploadBinary(
          '$studentId/$fileName',
          bytes,
        );

    return _supabase.storage.from('report-pdfs').getPublicUrl(
          '$studentId/$fileName',
        );
  }
}