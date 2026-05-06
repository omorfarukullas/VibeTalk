import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:vibetalk/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vibetalk/features/auth/presentation/bloc/auth_state.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final FocusNode _nameFocus = FocusNode();
  final FocusNode _bioFocus = FocusNode();
  final ImagePicker _picker = ImagePicker();

  File? _selectedImage;
  String? _uploadedAvatarUrl;
  bool _isNameValid = false;

  static const int _maxBioLength = 150;
  static const int _maxNameLength = 50;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(() {
      final trimmed = _nameController.text.trim();
      setState(
        () => _isNameValid = trimmed.length >= 2 && trimmed.length <= _maxNameLength,
      );
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _nameFocus.dispose();
    _bioFocus.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    Navigator.pop(context); // close bottom sheet
    final picked = await _picker.pickImage(
      source: source,
      imageQuality: 90,
      maxWidth: 1200,
    );
    if (picked != null && mounted) {
      setState(() => _selectedImage = File(picked.path));
    }
  }

  void _showImagePicker() {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Icon(Icons.camera_alt_rounded, color: theme.colorScheme.primary),
              title: const Text('Take Photo'),
              onTap: () => _pickImage(ImageSource.camera),
            ),
            ListTile(
              leading: Icon(Icons.photo_library_rounded, color: theme.colorScheme.primary),
              title: const Text('Choose from Gallery'),
              onTap: () => _pickImage(ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _onDone() {
    if (!_isNameValid) return;
    FocusScope.of(context).unfocus();

    // TODO: Implement update profile in Sprint 2
    // context.read<AuthBloc>().add(
    //       UpdateProfileEvent(
    //         name: _nameController.text.trim(),
    //         bio: _bioController.text.trim().isEmpty ? null : _bioController.text.trim(),
    //         imageFile: _selectedImage,
    //       ),
    //     );
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: theme.colorScheme.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      },
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Set Up Profile'),
            automaticallyImplyLeading: false,
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 24),

                  // Avatar section
                  Center(
                    child: GestureDetector(
                      onTap: _showImagePicker,
                      child: Stack(
                        children: [
                          Container(
                            width: 112,
                            height: 112,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: primary.withOpacity(0.12),
                              border: Border.all(
                                color: primary.withOpacity(0.3),
                                width: 2,
                              ),
                            ),
                            child: ClipOval(
                              child: _selectedImage != null
                                  ? Image.file(
                                      _selectedImage!,
                                      fit: BoxFit.cover,
                                    )
                                  : Icon(
                                      Icons.person_rounded,
                                      size: 56,
                                      color: primary.withOpacity(0.6),
                                    ),
                            ),
                          ),

                          // Camera overlay
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: primary,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: theme.scaffoldBackgroundColor,
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                Icons.camera_alt_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  Center(
                    child: Text(
                      'Tap to add photo',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Name field
                  TextField(
                    controller: _nameController,
                    focusNode: _nameFocus,
                    textCapitalization: TextCapitalization.words,
                    maxLength: _maxNameLength,
                    decoration: InputDecoration(
                      labelText: 'Display Name *',
                      hintText: 'Your name',
                      prefixIcon: const Icon(Icons.person_outline_rounded),
                      counterText: '',
                      suffixIcon: _isNameValid
                          ? Icon(Icons.check_circle_rounded,
                              color: Colors.green.shade400, size: 20)
                          : null,
                    ),
                    onSubmitted: (_) => _bioFocus.requestFocus(),
                  ),

                  const SizedBox(height: 16),

                  // Bio field
                  ValueListenableBuilder<TextEditingValue>(
                    valueListenable: _bioController,
                    builder: (context, value, _) {
                      return TextField(
                        controller: _bioController,
                        focusNode: _bioFocus,
                        maxLines: 3,
                        maxLength: _maxBioLength,
                        decoration: InputDecoration(
                          labelText: 'Bio (optional)',
                          hintText: 'Tell people about yourself…',
                          prefixIcon: const Padding(
                            padding: EdgeInsets.only(bottom: 40),
                            child: Icon(Icons.info_outline_rounded),
                          ),
                          counterText: '${value.text.length}/$_maxBioLength',
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 32),

                  // Done button
                  BlocBuilder<AuthBloc, AuthState>(
                    builder: (context, state) {
                      final isLoading = state is AuthLoading;
                      return AnimatedOpacity(
                        opacity: _isNameValid ? 1.0 : 0.4,
                        duration: const Duration(milliseconds: 200),
                        child: ElevatedButton(
                          onPressed: (_isNameValid && !isLoading) ? _onDone : null,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Get Started →'),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
