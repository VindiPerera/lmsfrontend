import 'package:cached_network_image/cached_network_image.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lms/core/constants/app_colors.dart';
import 'package:lms/features/auth/providers/auth_provider.dart';
import 'package:lms/core/providers/theme_provider.dart';
import 'package:lms/core/providers/navigation_provider.dart';
import 'package:lms/features/dashboard/screens/teacher_dashboard.dart';
import 'package:lms/features/profile/screens/edit_profile_screen.dart';
import 'package:lms/features/profile/screens/legal_policy_screen.dart';
import 'package:lms/features/profile/screens/my_purchased_courses_screen.dart';
import 'package:lms/features/profile/screens/help_screen.dart';
import 'package:lms/features/profile/services/teacher_stats_service.dart';
import 'package:lms/core/providers/cart_provider.dart';

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

  double get orbOpacity => isDark ? 0.22 : 0.10;
}

class TeacherProfileView extends StatefulWidget {
  const TeacherProfileView({super.key});

  @override
  State<TeacherProfileView> createState() => _TeacherProfileViewState();
}

class _TeacherProfileViewState extends State<TeacherProfileView> {
  final TeacherStatsService _statsService = TeacherStatsService();
  bool _isLoading = true;
  int _totalStudents = 0;
  double _averageRating = 0.0;
  int _totalLectures = 0;
  double _totalPayments = 0.0;
  int _pendingSlips = 0;

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    final userId = context.read<AuthProvider>().userModel?.uid;
    if (userId != null) {
      final stats = await _statsService.getTeacherStats(userId);
      if (mounted) {
        setState(() {
          _totalStudents = stats['totalStudents'] ?? 0;
          _averageRating = stats['averageRating'] ?? 0.0;
          _totalLectures = stats['totalLectures'] ?? 0;
          _totalPayments = stats['totalPayments'] ?? 0.0;
          _pendingSlips = stats['pendingSlips'] ?? 0;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSignOutConfirm(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.3),
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Dialog(
          backgroundColor: Colors.white.withValues(alpha: 0.85),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(
              color: Colors.white.withValues(alpha: 0.5),
              width: 1.5,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.logout_rounded,
                    color: Colors.red,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Log Out',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Are you sure you want to log out of your account?',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, color: Colors.black87),
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          backgroundColor: Colors.grey.withValues(alpha: 0.2),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            color: Colors.black87,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          context.read<CartProvider>().clearCart();
                          context.read<NavigationProvider>().setIndex(0);
                          context.read<AuthProvider>().signOut();
                          Navigator.of(
                            context,
                          ).popUntil((route) => route.isFirst);
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Log Out',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDeleteAccountConfirm(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.3),
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Dialog(
          backgroundColor: Colors.white.withValues(alpha: 0.85),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(
              color: Colors.white.withValues(alpha: 0.5),
              width: 1.5,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.delete_outline_rounded,
                    color: Colors.red,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Delete Account',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Are you absolutely sure you want to permanently delete your account?\n\n'
                  'All your data, progress, and profile images will be wiped from the system. '
                  'This action cannot be undone.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, color: Colors.black87),
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          backgroundColor: Colors.grey.withValues(alpha: 0.2),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            color: Colors.black87,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(ctx);
                          final auth = context.read<AuthProvider>();
                          final status = await auth.deleteAccount();

                          if (!context.mounted) return;

                          if (status == DeleteAccountStatus.success) {
                            context.read<CartProvider>().clearCart();
                            context.read<NavigationProvider>().setIndex(0);
                            Navigator.of(
                              context,
                            ).popUntil((route) => route.isFirst);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Account successfully deleted.'),
                                backgroundColor: AppColors.success,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          } else if (status ==
                              DeleteAccountStatus.requiresRecentLogin) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Please sign out and sign in again to delete your account.',
                                ),
                                backgroundColor: AppColors.error,
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Delete',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userModel = context.watch<AuthProvider>().userModel;
    if (userModel == null) return const SizedBox.shrink();
    final hasImage = userModel.profileImageUrl.isNotEmpty;
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 120),
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
                              padding: const EdgeInsets.only(
                                left: 8,
                                right: 12,
                              ),
                              constraints: const BoxConstraints(),
                              icon: Icon(
                                Icons.arrow_back_ios_new,
                                color: c.textSecondary,
                                size: 20,
                              ),
                              onPressed: () {
                                try {
                                  context.read<NavigationProvider>().setIndex(
                                    0,
                                  );
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
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Avatar
                  Container(
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
                    child: CircleAvatar(
                      radius: 56,
                      backgroundColor: c.bgColor2,
                      backgroundImage: hasImage
                          ? CachedNetworkImageProvider(
                              userModel.profileImageUrl,
                            )
                          : null,
                      child: !hasImage
                          ? Icon(Icons.person, size: 50, color: c.accentPale)
                          : null,
                    ),
                  ),

                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 32,
                      ), // Balances the verified icon nicely
                      Flexible(
                        child: Text(
                          userModel.name.isNotEmpty
                              ? userModel.name
                              : 'Unknown',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: c.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.verified, color: c.accentBright, size: 24),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    userModel.role.isNotEmpty
                        ? '${userModel.role[0].toUpperCase()}${userModel.role.substring(1)}'
                        : 'Instructor',
                    style: TextStyle(
                      fontSize: 15,
                      color: c.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 24),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const TeacherDashboard(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: c.accentPrimary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 0,
                          side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.2),
                            width: 1.5,
                          ),
                        ),
                        child: const Text(
                          'Instructor Dashboard',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Options List
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: c.cardBg,
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(color: c.cardBorder, width: 1.5),
                        boxShadow: c.cardShadow,
                      ),
                      child: Column(
                        children: [
                          const SizedBox(height: 8),
                          _buildOptionTile(
                            c: c,
                            icon: Icons.person_outline,
                            title: 'Edit profile',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const EditProfileScreen(),
                                ),
                              );
                            },
                          ),
                          _buildOptionTile(
                            c: c,
                            icon: Icons.lock_outline,
                            title: 'Password & security',
                            onTap: () {},
                          ),
                          _buildOptionTile(
                            c: c,
                            icon: Icons.shopping_bag_outlined,
                            title: 'My Purchased Courses',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const MyPurchasedCoursesScreen(),
                                ),
                              );
                            },
                          ),
                          _buildOptionTile(
                            c: c,
                            icon: Icons.credit_card,
                            title: 'Card settings',
                            onTap: () {},
                          ),
                          _buildOptionTile(
                            c: c,
                            icon: Icons.notifications_none,
                            title: 'Notification settings',
                            onTap: () {},
                          ),
                          _buildDarkThemeToggle(context, c),
                          _buildOptionTile(
                            c: c,
                            icon: Icons.privacy_tip_outlined,
                            title: 'Terms & privacy policy',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const LegalPolicyScreen(),
                                ),
                              );
                            },
                          ),
                          _buildOptionTile(
                            c: c,
                            icon: Icons.help_outline,
                            title: 'Help',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const HelpScreen(),
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
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
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
                              padding: const EdgeInsets.symmetric(vertical: 16),
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
                            onPressed: () => _showDeleteAccountConfirm(context),
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
    );
  }

  Widget _buildWideStatCard({
    required _ProfileColors c,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: BoxDecoration(
        color: c.cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: c.cardBorder, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: c.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: c.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionTile({
    required _ProfileColors c,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
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

  Widget _buildDarkThemeToggle(BuildContext context, _ProfileColors c) {
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
