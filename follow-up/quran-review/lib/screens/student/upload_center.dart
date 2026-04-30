import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/recording_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/common/common_widgets.dart';

class UploadCenter extends ConsumerStatefulWidget {
  const UploadCenter({super.key});

  @override
  ConsumerState<UploadCenter> createState() => _UploadCenterState();
}

class _UploadCenterState extends ConsumerState<UploadCenter> {
  final _descriptionController = TextEditingController();
  PlatformFile? _selectedFile;
  bool _isLoading = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3', 'wav', 'm4a', 'mp4', 'pdf', 'doc', 'docx'],
    );

    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _selectedFile = result.files.first;
      });
    }
  }

  Future<void> _upload() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final teacherAsync = ref.read(assignedTeacherProvider(user.id));
    final teacher = teacherAsync.valueOrNull;

    if (teacher == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.noTeacherAssigned),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a file'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final extension = _selectedFile!.extension ?? '';
      final fileType = ['mp3', 'wav', 'm4a'].contains(extension) ? 'audio' : ['mp4'].contains(extension) ? 'video' : 'document';

      await ref.read(studentRecordingNotifierProvider(user.id).notifier).uploadRecording(
            studentId: user.id,
            teacherId: teacher.id,
            filePath: _selectedFile!.path ?? '',
            fileName: _selectedFile!.name,
            fileType: fileType,
            fileSize: _selectedFile!.size,
            description: _descriptionController.text.isNotEmpty ? _descriptionController.text : null,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.recordingUploaded),
            backgroundColor: Colors.green,
          ),
        );
        context.go('/student/my-recordings');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.uploadRecording),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/student/dashboard')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppCard(
              onTap: _pickFile,
              child: Column(
                children: [
                  Icon(
                    _selectedFile != null ? Icons.check_circle : Icons.cloud_upload_outlined,
                    size: 64,
                    color: _selectedFile != null ? Colors.green : Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _selectedFile != null ? _selectedFile!.name : l10n.selectFile,
                    style: Theme.of(context).textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  if (_selectedFile != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      '${(_selectedFile!.size / 1024).toStringAsFixed(1)} KB',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
            AppInput(
              label: l10n.description,
              hint: l10n.description,
              controller: _descriptionController,
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            AppButton(
              text: l10n.upload,
              onPressed: _upload,
              isLoading: _isLoading,
              isFullWidth: true,
              icon: Icons.upload,
            ),
          ],
        ),
      ),
    );
  }
}