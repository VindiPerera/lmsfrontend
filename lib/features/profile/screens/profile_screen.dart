import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lms/core/constants/app_colors.dart';
import 'package:lms/core/providers/cart_provider.dart';
import 'package:lms/core/services/file_upload_service.dart';
import 'package:lms/features/auth/providers/auth_provider.dart';
import 'package:lms/features/profile/screens/edit_profile_screen.dart';
import 'package:lms/features/profile/screens/teacher_profile_view.dart';
import 'package:lms/core/providers/navigation_provider.dart';
import 'package:lms/core/providers/theme_provider.dart';
import 'package:lms/features/profile/screens/legal_policy_screen.dart';
import 'package:lms/features/profile/screens/help_screen.dart';
import 'package:lms/features/profile/screens/my_purchased_courses_screen.dart';

// ── Theme-aware color helper ─────────────────────────────────────────────────
class _ProfileColors {
  final bool isDark;
  _ProfileColors(this.isDark);

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
  Color get accentGlow =>
      isDark ? const Color(0xFF7C3AED) : const Color(0xFF9333EA);

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

  LinearGradient get ctaGradient =>
      const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFFA855F7)]);
  double get orbOpacity => isDark ? 0.22 : 0.10;
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FileUploadService _fileUploadService = FileUploadService();
  bool _isUploading = false;

  Future<void> _handleImageUpload() async {
    final oldProfileImageUrl = context
        .read<AuthProvider>()
        .userModel
        ?.profileImageUrl;
    setState(() => _isUploading = true);
    try {
      final file = await _fileUploadService.pickImage();
      if (file == null) {
        setState(() => _isUploading = false);
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
          ),
        );
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Upload failed: '),
            backgroundColor: AppColors.error,
          ),
        );
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _showSignOutConfirm(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text(
          'Are you sure you want to log out of your account?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<CartProvider>().clearCart();
              context.read<NavigationProvider>().setIndex(0);
              context.read<AuthProvider>().signOut();
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountConfirm(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Delete Account',
          style: TextStyle(color: AppColors.error),
        ),
        content: const Text(
          'Are you absolutely sure you want to permanently delete your account?\n\nThis action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final status = await context.read<AuthProvider>().deleteAccount();
              if (!context.mounted) return;
              if (status == DeleteAccountStatus.success) {
                context.read<CartProvider>().clearCart();
                context.read<NavigationProvider>().setIndex(0);
                Navigator.of(context).popUntil((route) => route.isFirst);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Account deleted.'),
                    backgroundColor: AppColors.success,
                  ),
                );
              } else if (status == DeleteAccountStatus.requiresRecentLogin) {
                _showReAuthDialog(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );
  }

  void _showReAuthDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Re-authentication Required'),
        content: const Text(
          'Please sign out and sign back in before deleting your account.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().userModel;
    if (user == null) return const SizedBox.shrink();

    if (user.role.toLowerCase() == 'teacher' ||
        user.role.toLowerCase() == 'instructor' ||
        user.role.toLowerCase() == 'admin') {
      return const TeacherProfileView();
    }

    final hasImage = user.profileImageUrl.isNotEmpty;
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final c = _ProfileColors(isDark);

    return Scaffold(
      backgroundColor: c.bgColor1,
      body: Stack(
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
            bottom: false,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(
                    left: 8,
                    right: 24,
                    top: 12,
                    bottom: 12,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              Icons.arrow_back_ios_new,
                              color: c.textSecondary,
                              size: 20,
                            ),
                            padding: const EdgeInsets.only(left: 8, right: 12),
                            constraints: const BoxConstraints(),
                            onPressed: () {
                              try {
                                context.read<NavigationProvider>().setIndex(0);
                              } catch (e) {
                                Navigator.pop(context);
                              }
                            },
                          ),
                          Text(
                            'Profile',
                            style: TextStyle(
                              color: c.textPrimary,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: c.cardBg,
                          shape: BoxShape.circle,
                          border: Border.all(color: c.cardBorder),
                        ),
                        child: IconButton(
                          icon: Icon(
                            Icons.notifications_none,
                            color: c.textSecondary,
                          ),
                          onPressed: () {},
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 120),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),

                        // Avatar & Main Info
                        Center(
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: c.cardBg,
                              shape: BoxShape.circle,
                              border: Border.all(color: c.cardBorder, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: c.accentGlow.withValues(alpha: 0.3),
                                  blurRadius: 15,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                CircleAvatar(
                                  radius: 56,
                                  backgroundColor: c.bgColor2,
                                  backgroundImage: hasImage
                                      ? NetworkImage(user.profileImageUrl)
                                      : null,
                                  child: !hasImage
                                      ? Icon(
                                          Icons.person,
                                          size: 50,
                                          color: c.accentPale,
                                        )
                                      : null,
                                ),
                                if (_isUploading)
                                  const CircularProgressIndicator(
                                    color: Colors.white,
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(width: 32),
                            Flexible(
                              child: Text(
                                user.name.isNotEmpty ? user.name : 'Unknown',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  color: c.textPrimary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.verified,
                              color: c.accentBright,
                              size: 24,
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Center(
                          child: Text(
                            user.studentId ?? 'Student',
                            style: TextStyle(
                              fontSize: 15,
                              color: c.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Main Card Glassmorphic
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Container(
                            decoration: BoxDecoration(
                              color: c.cardBg,
                              borderRadius: BorderRadius.circular(32),
                              border: Border.all(
                                color: c.cardBorder,
                                width: 1.5,
                              ),
                              boxShadow: c.cardShadow,
                            ),
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Premium Member',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: c.textPrimary,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [
                                            Color(0xFFFFB347),
                                            Color(0xFFFFCC33),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: const Row(
                                        children: [
                                          Icon(
                                            Icons.diamond,
                                            size: 12,
                                            color: Colors.white,
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            'PRO',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          _buildStatRow(
                                            c,
                                            Icons.emoji_events_outlined,
                                            '12,450 XP',
                                          ),
                                          const SizedBox(height: 12),
                                          _buildStatRow(
                                            c,
                                            Icons
                                                .local_fire_department_outlined,
                                            '15 days streak',
                                          ),
                                          const SizedBox(height: 12),
                                          _buildStatRow(
                                            c,
                                            Icons.school_outlined,
                                            'Level 4',
                                          ),
                                        ],
                                      ),
                                    ),
                                    Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        SizedBox(
                                          width: 75,
                                          height: 75,
                                          child: CircularProgressIndicator(
                                            value: 0.65,
                                            strokeWidth: 8,
                                            backgroundColor: isDark
                                                ? Colors.white.withValues(
                                                    alpha: 0.08,
                                                  )
                                                : Colors.white.withValues(
                                                    alpha: 0.6,
                                                  ),
                                            valueColor: AlwaysStoppedAnimation(
                                              c.accentBright,
                                            ),
                                            strokeCap: StrokeCap.round,
                                          ),
                                        ),
                                        Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              '65%',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                                color: c.textPrimary,
                                              ),
                                            ),
                                            Text(
                                              'Progress',
                                              style: TextStyle(
                                                fontSize: 8,
                                                color: c.textSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 32),

                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Text(
                            'Achievements',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: c.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            children: [
                              _buildAchievementCard(
                                c,
                                'Fluency Pro',
                                'Attend 20 Live Speaking Workshops.',
                                12,
                                20,
                                '500 XP',
                                c.accentBright,
                              ),
                              const SizedBox(height: 12),
                              _buildAchievementCard(
                                c,
                                'Perfect Score',
                                'Get 100% on any 5 Grammar Quizzes.',
                                2,
                                5,
                                '200 XP',
                                c.accentBright,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Option tiles
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Container(
                            decoration: BoxDecoration(
                              color: c.cardBg,
                              borderRadius: BorderRadius.circular(32),
                              border: Border.all(
                                color: c.cardBorder,
                                width: 1.5,
                              ),
                              boxShadow: c.cardShadow,
                            ),
                            child: Column(
                              children: [
                                const SizedBox(height: 8),
                                _buildOptionTile(
                                  c,
                                  Icons.person_outline,
                                  'Edit profile',
                                  () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const EditProfileScreen(),
                                    ),
                                  ),
                                ),
                                _buildOptionTile(
                                  c,
                                  Icons.lock_outline,
                                  'Password & security',
                                  () {},
                                ),
                                _buildOptionTile(
                                  c,
                                  Icons.shopping_bag_outlined,
                                  'My Purchased Courses',
                                  () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const MyPurchasedCoursesScreen(),
                                    ),
                                  ),
                                ),
                                _buildOptionTile(
                                  c,
                                  Icons.credit_card,
                                  'Card settings',
                                  () {},
                                ),
                                _buildOptionTile(
                                  c,
                                  Icons.notifications_none,
                                  'Notification settings',
                                  () {},
                                ),
                                _buildDarkModeToggle(c),
                                _buildOptionTile(
                                  c,
                                  Icons.privacy_tip_outlined,
                                  'Terms & privacy policy',
                                  () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const LegalPolicyScreen(),
                                      ),
                                    );
                                  },
                                ),
                                _buildOptionTile(
                                  c,
                                  Icons.help_outline,
                                  'Help',
                                  () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const HelpScreen(),
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 8),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            children: [
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () => _showSignOutConfirm(context),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: c.isDark
                                        ? Colors.white.withValues(alpha: 0.1)
                                        : Colors.white.withValues(alpha: 0.4),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(24),
                                      side: BorderSide(
                                        color: c.cardBorder,
                                        width: 1.5,
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    'Logout',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: c.textPrimary,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Center(
                                child: TextButton(
                                  onPressed: () =>
                                      _showDeleteAccountConfirm(context),
                                  child: const Text(
                                    'Delete Account',
                                    style: TextStyle(
                                      color: Color(0xFFD32F2F),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(_ProfileColors c, IconData icon, String text) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: c.accentPrimary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: c.accentPale),
        ),
        const SizedBox(width: 12),
        Text(
          text,
          style: TextStyle(
            fontSize: 14,
            color: c.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildAchievementCard(
    _ProfileColors c,
    String title,
    String subtitle,
    int progress,
    int total,
    String xp,
    Color color,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: c.cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: c.cardBorder, width: 1.5),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: c.accentPrimary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.military_tech, color: color, size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: c.textPrimary,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        border: Border.all(color: color.withValues(alpha: 0.4)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.emoji_events, size: 12, color: color),
                          const SizedBox(width: 4),
                          Text(
                            xp,
                            style: TextStyle(
                              fontSize: 11,
                              color: color,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: c.textSecondary),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: progress / total,
                          backgroundColor: c.isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : Colors.white.withValues(alpha: 0.6),
                          valueColor: AlwaysStoppedAnimation(color),
                          minHeight: 8,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '$progress/$total',
                      style: TextStyle(
                        fontSize: 11,
                        color: c.textSecondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionTile(
    _ProfileColors c,
    IconData icon,
    String title,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: c.accentPrimary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: c.accentPale, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 16,
          color: c.textPrimary,
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios_rounded,
        size: 14,
        color: c.textSecondary,
      ),
      onTap: onTap,
    );
  }

  Widget _buildDarkModeToggle(_ProfileColors c) {
    final themeProvider = context.watch<ThemeProvider>();
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: c.accentPrimary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(Icons.dark_mode_outlined, color: c.accentPale, size: 20),
      ),
      title: Text(
        'Dark mode',
        style: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 16,
          color: c.textPrimary,
        ),
      ),
      trailing: Switch(
        value: themeProvider.isDarkMode,
        activeColor: c.accentBright,
        activeTrackColor: c.isDark
            ? Colors.white.withValues(alpha: 0.2)
            : Colors.white.withValues(alpha: 0.8),
        inactiveTrackColor: c.isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.white.withValues(alpha: 0.2),
        onChanged: (val) {
          themeProvider.toggleTheme(val);
        },
      ),
    );
  }
}
