import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lms/core/constants/app_colors.dart';
import 'package:lms/features/auth/providers/auth_provider.dart';
import 'package:lms/core/providers/theme_provider.dart';
import 'package:lms/core/services/file_upload_service.dart';

// ── Theme-aware color helper ─────────────────────────────────────────────────
class _EditProfileColors {
  final bool isDark;
  _EditProfileColors(this.isDark);

  Color get bgColor1 =>
      isDark ? const Color(0xFF080510) : const Color(0xFFF8F5FF);
  Color get bgColor2 =>
      isDark ? const Color(0xFF150C2E) : const Color(0xFFEDE5FF);
  Color get bgColor3 =>
      isDark ? const Color(0xFF1A1242) : const Color(0xFFE0D4F7);
  Color get bgColor4 =>
      isDark ? const Color(0xFF0D0820) : const Color(0xFFF2EEFF);

  Color get cardBg => isDark
      ? Colors.white.withValues(alpha: 0.06)
      : Colors.white.withValues(alpha: 0.75);
  Color get cardBorder => isDark
      ? Colors.white.withValues(alpha: 0.10)
      : Colors.white.withValues(alpha: 0.9);

  Color get accentPrimary => const Color(0xFF7C3AED);
  Color get accentBright => const Color(0xFFA855F7);
  Color get accentPale =>
      isDark ? const Color(0xFFC084FC) : const Color(0xFF6D28D9);

  Color get textPrimary => isDark ? Colors.white : const Color(0xFF1A0845);
  Color get textSecondary =>
      isDark ? const Color(0xFFD4C5FF) : const Color(0xFF5B3D8F);

  List<BoxShadow> get cardShadow => isDark
      ? [
          BoxShadow(
            color: const Color(0xFF7C3AED).withValues(alpha: 0.15),
            blurRadius: 30,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ]
      : [
          BoxShadow(
            color: const Color(0xFF7C3AED).withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ];

  double get orbOpacity => isDark ? 0.22 : 0.10;
}

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final FileUploadService _fileUploadService = FileUploadService();

  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _roleController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;

  bool _isSaving = false;
  bool _isUploadingProfilePic = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().userModel;

    // Split name
    final nameParts = (user?.name ?? '').split(' ');
    final firstName = nameParts.isNotEmpty ? nameParts.first : '';
    final lastName = nameParts.length > 1 ? nameParts.skip(1).join(' ') : '';

    _firstNameController = TextEditingController(text: firstName);
    _lastNameController = TextEditingController(text: lastName);
    _roleController = TextEditingController(text: user?.role ?? '');
    _phoneController = TextEditingController(text: user?.phoneNumber ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _roleController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleImageUpload() async {
    final oldProfileImageUrl = context
        .read<AuthProvider>()
        .userModel
        ?.profileImageUrl;
    setState(() => _isUploadingProfilePic = true);

    try {
      final file = await _fileUploadService.pickImage();
      if (file == null) {
        setState(() => _isUploadingProfilePic = false);
        return;
      }
      final url = await _fileUploadService.uploadFile(
        file,
        folderType: 'profiles',
      );
      if (url == null) throw Exception('Image upload failed');

      if (oldProfileImageUrl != null && oldProfileImageUrl.isNotEmpty) {
        _fileUploadService.deleteFile(oldProfileImageUrl).ignore();
      }
      if (!mounted) return;
      await context.read<AuthProvider>().updateProfileImage(url);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile image updated successfully!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Upload failed'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
    } finally {
      if (mounted) setState(() => _isUploadingProfilePic = false);
    }
  }

  void _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSaving = true);

      try {
        final newName =
            '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}'
                .trim();
        final newPhone = _phoneController.text.trim();
        // Use the existing role from userModel — never allow role changes from client
        final existingRole = context.read<AuthProvider>().userModel?.role ?? _roleController.text.trim();

        await context.read<AuthProvider>().updateProfileDetails(
          name: newName,
          phoneNumber: newPhone,
          role: existingRole,
        );

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Profile updated successfully!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        Navigator.pop(context);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } finally {
        if (mounted) setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userModel = context.watch<AuthProvider>().userModel;
    final hasImage = userModel?.profileImageUrl.isNotEmpty == true;
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final c = _EditProfileColors(isDark);

    return Scaffold(
      backgroundColor: c.bgColor1,
      body: SizedBox.expand(
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // ── Background Gradient ──────────────────────────────────────
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [c.bgColor1, c.bgColor2, c.bgColor3, c.bgColor4],
                    stops: const [0.0, 0.3, 0.65, 1.0],
                  ),
                ),
              ),
            ),

            // ── Decorative Mesh Orbs ─────────────────────────────────────
            Positioned(
              top: -80,
              right: -60,
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF7C3AED).withValues(alpha: c.orbOpacity),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 400,
              left: -80,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(
                        0xFFA855F7,
                      ).withValues(alpha: c.orbOpacity * 0.6),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 200,
              right: -40,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(
                        0xFF6D28D9,
                      ).withValues(alpha: c.orbOpacity * 0.7),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 16.0,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Edit profile',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: c.textPrimary,
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: c.cardBg,
                              shape: BoxShape.circle,
                              border: Border.all(color: c.cardBorder),
                            ),
                            child: IconButton(
                              icon: Icon(
                                Icons.close_rounded,
                                color: c.textPrimary,
                                size: 20,
                              ),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // Avatar with camera icon
                      GestureDetector(
                        onTap: _isUploadingProfilePic
                            ? null
                            : _handleImageUpload,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: c.cardBg,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: c.cardBorder,
                                  width: 2,
                                ),
                                boxShadow: c.isDark
                                    ? [
                                        BoxShadow(
                                          color: c.accentPrimary.withValues(
                                            alpha: 0.3,
                                          ),
                                          blurRadius: 15,
                                          offset: const Offset(0, 5),
                                        ),
                                      ]
                                    : [],
                              ),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  CircleAvatar(
                                    radius: 65,
                                    backgroundColor: c.bgColor2,
                                    backgroundImage: hasImage
                                        ? CachedNetworkImageProvider(
                                            userModel!.profileImageUrl,
                                          )
                                        : null,
                                    child: !hasImage
                                        ? Icon(
                                            Icons.person,
                                            size: 60,
                                            color: c.accentPale,
                                          )
                                        : null,
                                  ),
                                  if (_isUploadingProfilePic)
                                    const CircularProgressIndicator(
                                      color: Colors.white,
                                    ),
                                ],
                              ),
                            ),
                            Positioned(
                              bottom: 4,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: c.accentPrimary,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.6),
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: c.accentPrimary.withValues(
                                        alpha: 0.3,
                                      ),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.camera_alt_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 48),

                      // Input Fields
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _firstNameController,
                              hintText: 'e.g. John',
                              label: 'FIRST NAME',
                              c: c,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildTextField(
                              controller: _lastNameController,
                              hintText: 'e.g. Doe',
                              label: 'LAST NAME',
                              c: c,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _buildTextField(
                        controller: _roleController,
                        hintText: 'Student / Teacher',
                        label: 'ROLE',
                        c: c,
                        readOnly: true,
                      ),
                      const SizedBox(height: 20),
                      _buildTextField(
                        controller: _phoneController,
                        hintText: 'e.g. +1 234 567 890',
                        label: 'PHONE NUMBER',
                        c: c,
                      ),
                      const SizedBox(height: 20),
                      _buildTextField(
                        controller: _emailController,
                        hintText: 'e.g. user@example.com',
                        label: 'EMAIL ADDRESS',
                        c: c,
                        readOnly: true,
                      ),

                      const SizedBox(height: 40),

                      // Save Button
                      SizedBox(
                        width: double.infinity,
                        height: 60,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _saveProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: c.accentPrimary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            elevation: 0,
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Save Changes',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required String label,
    required _EditProfileColors c,
    bool readOnly = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label,
            style: TextStyle(
              color: c.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: c.isDark
                ? Colors.black.withValues(alpha: 0.2)
                : Colors.white.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: c.cardBorder, width: 1.5),
            boxShadow: c.isDark
                ? []
                : [
                    BoxShadow(
                      color: const Color(0xFF7C3AED).withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: TextFormField(
            controller: controller,
            readOnly: readOnly,
            style: TextStyle(color: c.textPrimary, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: TextStyle(
                color: c.textSecondary.withValues(alpha: 0.5),
                fontWeight: FontWeight.normal,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
              border: InputBorder.none,
              // don't show edit icon if readonly
              suffixIcon: readOnly
                  ? null
                  : Icon(
                      Icons.edit_rounded,
                      color: c.textSecondary.withValues(alpha: 0.5),
                      size: 18,
                    ),
            ),
          ),
        ),
      ],
    );
  }
}
