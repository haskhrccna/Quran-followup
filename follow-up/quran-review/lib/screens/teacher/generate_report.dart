import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../services/report_service.dart';
import '../../widgets/common/common_widgets.dart';
import '../../config/app_config.dart';

class GenerateReport extends ConsumerStatefulWidget {
  const GenerateReport({super.key});

  @override
  ConsumerState<GenerateReport> createState() => _GenerateReportState();
}

class _GenerateReportState extends ConsumerState<GenerateReport> {
  final _titleController = TextEditingController();
  String? _selectedStudentId;
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    final user = ref.read(currentUserProvider);
    if (user == null || _selectedStudentId == null) return;

    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please enter a title'), backgroundColor: Colors.red));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final reportService = ReportService(ref.read(supabaseProvider));
      await reportService.generateStudentReport(
        teacherId: user.id,
        studentId: _selectedStudentId!,
        title: _titleController.text.trim(),
        grades: [],
        appointments: [],
        averageGrade: 0.0,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.reportGenerated), backgroundColor: Colors.green));
        context.go('/teacher/dashboard');
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final user = ref.watch(currentUserProvider);
    if (user == null) return const Scaffold(body: AppLoading());

    final studentsAsync = ref.watch(assignedStudentsProvider(user.id));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.generatePdf),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/teacher/dashboard')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            studentsAsync.when(
              data: (students) => DropdownButtonFormField<String>(
                decoration: InputDecoration(labelText: l10n.selectStudent),
                value: _selectedStudentId,
                items: students.map((s) => DropdownMenuItem(value: s.id, child: Text(s.fullName))).toList(),
                onChanged: (v) => setState(() => _selectedStudentId = v),
              ),
              loading: () => const AppLoading(),
              error: (e, _) => Text('Error: $e'),
            ),
            const SizedBox(height: 16),
            AppInput(label: l10n.title, hint: l10n.title, controller: _titleController),
            const SizedBox(height: 24),
            AppButton(text: l10n.generatePdf, onPressed: _generate, isLoading: _isLoading, isFullWidth: true, icon: Icons.picture_as_pdf),
          ],
        ),
      ),
    );
  }
}