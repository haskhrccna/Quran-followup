import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import 'package:quran_tutor_app/core/constants/app_constants.dart';
import 'package:quran_tutor_app/core/theme/app_colors.dart';
import 'package:quran_tutor_app/core/utils/validators/arabic_validators.dart';
import 'package:quran_tutor_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:quran_tutor_app/features/auth/presentation/bloc/auth_event.dart';
import 'package:quran_tutor_app/features/profile/domain/entities/user_profile.dart';
import 'package:quran_tutor_app/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:quran_tutor_app/features/profile/presentation/bloc/profile_event.dart';
import 'package:quran_tutor_app/features/profile/presentation/bloc/profile_state.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isEditing = false;

  final _formKey = GlobalKey<FormState>();
  final _arabicNameController = TextEditingController();
  final _englishNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _bioController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<ProfileBloc>().add(const LoadProfile());
  }

  @override
  void dispose() {
    _arabicNameController.dispose();
    _englishNameController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _setControllers(UserProfile profile) {
    _arabicNameController.text = profile.arabicName ?? '';
    _englishNameController.text = profile.displayName ?? '';
    _phoneController.text = profile.phoneNumber ?? '';
    _bioController.text = profile.bio ?? '';
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (picked != null && mounted) {
      context.read<ProfileBloc>().add(UploadAvatar(File(picked.path)));
    }
  }

  void _saveProfile(UserProfile current) {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    context.read<ProfileBloc>().add(UpdateProfile(
          arabicName: _arabicNameController.text.trim(),
          englishName: _englishNameController.text.trim(),
          phoneNumber: _phoneController.text.trim(),
          bio: _bioController.text.trim(),
        ));
    setState(() => _isEditing = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الملف الشخصي'),
        actions: [
          BlocBuilder<ProfileBloc, ProfileState>(
            builder: (context, state) {
              if (state.status != ProfileStatus.loaded ||
                  state.profile == null) {
                return const SizedBox.shrink();
              }
              return IconButton(
                icon: Icon(_isEditing ? Icons.close : Icons.edit),
                onPressed: () {
                  setState(() {
                    _isEditing = !_isEditing;
                    if (_isEditing) _setControllers(state.profile!);
                  });
                },
              );
            },
          ),
        ],
      ),
      body: BlocConsumer<ProfileBloc, ProfileState>(
        listener: (context, state) {
          if (state.status == ProfileStatus.error &&
              state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.errorMessage!)),
            );
          }
        },
        builder: (context, state) {
          if (state.status == ProfileStatus.loading ||
              state.status == ProfileStatus.initial) {
            return const Center(child: CircularProgressIndicator());
          }

          final profile = state.profile;
          if (profile == null) {
            return const Center(child: Text('لم يتم العثور على الملف الشخصي'));
          }

          if (_isEditing) {
            return _buildEditForm(profile);
          }

          return _buildProfileView(profile, state);
        },
      ),
    );
  }

  Widget _buildProfileView(UserProfile profile, ProfileState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _AvatarSection(
            profile: profile,
            isUploading: state.status == ProfileStatus.uploading,
            onPickAvatar: _pickAvatar,
            onDeleteAvatar: () =>
                context.read<ProfileBloc>().add(const DeleteAvatar()),
          ),
          const SizedBox(height: 24),
          _InfoCard(
            title: 'المعلومات الشخصية',
            children: [
              _InfoRow(
                  icon: Icons.person,
                  label: 'الاسم بالعربية',
                  value: profile.arabicName ?? '-'),
              _InfoRow(
                  icon: Icons.person_outline,
                  label: 'الاسم بالإنجليزية',
                  value: profile.displayName ?? '-'),
              _InfoRow(
                  icon: Icons.email,
                  label: 'البريد الإلكتروني',
                  value: profile.email),
              _InfoRow(
                  icon: Icons.phone,
                  label: 'رقم الجوال',
                  value: profile.phoneNumber ?? '-'),
              if (profile.bio != null && profile.bio!.isNotEmpty)
                _InfoRow(
                    icon: Icons.info_outline,
                    label: 'نبذة',
                    value: profile.bio!),
            ],
          ),
          const SizedBox(height: 16),
          _InfoCard(
            title: 'معلومات الحساب',
            children: [
              _InfoRow(
                icon: Icons.verified_user,
                label: 'الدور',
                value: _roleText(profile.role),
              ),
              _InfoRow(
                icon: Icons.flag,
                label: 'الحالة',
                value: _statusText(profile.status),
              ),
              if (profile.dateOfBirth != null)
                _InfoRow(
                  icon: Icons.cake,
                  label: 'تاريخ الميلاد',
                  value:
                      '${profile.dateOfBirth!.day}/${profile.dateOfBirth!.month}/${profile.dateOfBirth!.year}',
                ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => context
                  .read<AuthBloc>()
                  .add(const SignOutRequested()),
              icon: const Icon(Icons.logout),
              label: const Text('تسجيل الخروج'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditForm(UserProfile profile) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            TextFormField(
              controller: _arabicNameController,
              decoration: const InputDecoration(
                labelText: 'الاسم بالعربية',
                prefixIcon: Icon(Icons.person),
              ),
              textDirection: TextDirection.rtl,
              validator: ArabicValidators.validateArabicName,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _englishNameController,
              decoration: const InputDecoration(
                labelText: 'الاسم بالإنجليزية',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: ArabicValidators.validateEnglishName,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'رقم الجوال',
                prefixIcon: Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
              validator: ArabicValidators.validatePhone,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _bioController,
              decoration: const InputDecoration(
                labelText: 'نبذة',
                prefixIcon: Icon(Icons.info_outline),
              ),
              maxLines: 3,
              textDirection: TextDirection.rtl,
              validator: ArabicValidators.validateBio,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _saveProfile(profile),
                icon: const Icon(Icons.save),
                label: const Text('حفظ التغييرات'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _roleText(UserRole role) {
    switch (role) {
      case UserRole.student:
        return 'طالب';
      case UserRole.teacher:
        return 'معلم';
      case UserRole.admin:
        return 'مدير';
    }
  }

  String _statusText(UserStatus status) {
    switch (status) {
      case UserStatus.pending:
        return 'قيد الانتظار';
      case UserStatus.approved:
        return 'تم القبول';
      case UserStatus.rejected:
        return 'مرفوض';
      case UserStatus.suspended:
        return 'موقوف';
    }
  }
}

class _AvatarSection extends StatelessWidget {
  const _AvatarSection({
    required this.profile,
    required this.isUploading,
    required this.onPickAvatar,
    required this.onDeleteAvatar,
  });

  final UserProfile profile;
  final bool isUploading;
  final VoidCallback onPickAvatar;
  final VoidCallback onDeleteAvatar;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        children: [
          CircleAvatar(
            radius: 60,
            backgroundColor: AppColors.primaryContainer,
            backgroundImage:
                profile.hasAvatar ? NetworkImage(profile.photoUrl!) : null,
            child: !profile.hasAvatar
                ? Text(
                    profile.initials,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: AppColors.onPrimaryContainer,
                        ),
                  )
                : null,
          ),
          if (isUploading)
            const Positioned.fill(
              child: CircularProgressIndicator(),
            ),
          Positioned(
            bottom: 0,
            right: 0,
            child: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'change') onPickAvatar();
                if (value == 'delete') onDeleteAvatar();
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                    value: 'change', child: Text('تغيير الصورة')),
                if (profile.hasAvatar)
                  const PopupMenuItem(
                      value: 'delete', child: Text('حذف الصورة')),
              ],
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child:
                    const Icon(Icons.camera_alt, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const Divider(),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(
      {required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                ),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
