import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/grade_provider.dart';
import '../../models/grade.dart';
import '../../widgets/common/common_widgets.dart';

class GradeStudent extends ConsumerStatefulWidget {
  const GradeStudent({super.key});

  @override
  ConsumerState<GradeStudent> createState() => _GradeStudentState();
}

class _GradeStudentState extends ConsumerState<GradeStudent> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedStudentId;
  final _subjectController = TextEditingController();
  final _gradeController = TextEditingController();
  final _commentsController = TextEditingController();
  GradeType _selectedType = GradeType.exam;
  bool _isLoading = false;

  @override
  void dispose() {
    _subjectController.dispose();
    _gradeController.dispose();
    _commentsController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final user = ref.read(currentUserProvider);
    if (user == null || _selectedStudentId == null) return;

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await ref.read(teacherGradeNotifierProvider(user.id).notifier).giveGrade(
            studentId: _selectedStudentId!,
            teacherId: user.id,
            subject: _subjectController.text.trim(),
            gradeValue: double.parse(_gradeController.text.trim()),
            gradeType: _selectedType,
            comments: _commentsController.text.isNotEmpty ? _commentsController.text.trim() : null,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.gradeAdded), backgroundColor: Colors.green));
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
        title: Text(l10n.giveGrade),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/teacher/dashboard')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              studentsAsync.when(
                data: (students) => DropdownButtonFormField<String>(
                  decoration: InputDecoration(labelText: l10n.selectStudent),
                  value: _selectedStudentId,
                  items: students.map((s) => DropdownMenuItem(value: s.id, child: Text(s.fullName))).toList(),
                  onChanged: (v) => setState(() => _selectedStudentId = v),
                  validator: (v) => v == null ? l10n.requiredField : null,
                ),
                loading: () => const AppLoading(),
                error: (e, _) => Text('Error: $e'),
              ),
              const SizedBox(height: 16),
              AppInput(label: l10n.subject, hint: l10n.subject, controller: _subjectController, validator: (v) => v == null || v.isEmpty ? l10n.requiredField : null),
              const SizedBox(height: 16),
              DropdownButtonFormField<GradeType>(
                decoration: InputDecoration(labelText: l10n.gradeType),
                value: _selectedType,
                items: GradeType.values.map((t) => DropdownMenuItem(value: t, child: Text(_getGradeTypeText(t, l10n)))).toList(),
                onChanged: (v) => setState(() => _selectedType = v!),
              ),
              const SizedBox(height: 16),
              AppInput(label: l10n.gradeValue, hint: '0-100', controller: _gradeController, keyboardType: TextInputType.number, validator: (v) {
                if (v == null || v.isEmpty) return l10n.requiredField;
                final grade = double.tryParse(v);
                if (grade == null || grade < 0 || grade > 100) return 'Enter value between 0-100';
                return null;
              }),
              const SizedBox(height: 16),
              AppInput(label: l10n.comments, hint: l10n.comments, controller: _commentsController, maxLines: 3),
              const SizedBox(height: 24),
              AppButton(text: l10n.save, onPressed: _submit, isLoading: _isLoading, isFullWidth: true),
            ],
          ),
        ),
      ),
    );
  }

  String _getGradeTypeText(GradeType type, AppLocalizations l10n) {
    switch (type) {
      case GradeType.exam:
        return l10n.exam;
      case GradeType.quiz:
        return l10n.quiz;
      case GradeType.assignment:
        return l10n.assignment;
      case GradeType.project:
        return l10n.project;
      case GradeType.finalExam:
        return l10n.final;
    }
  }
}