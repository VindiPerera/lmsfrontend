import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:lms/core/constants/app_colors.dart';
import 'package:lms/core/constants/app_text_styles.dart';
import 'package:lms/features/auth/providers/auth_provider.dart';
import 'package:lms/features/dashboard/screens/admin_analytics_screen.dart';
import 'package:lms/features/profile/screens/profile_screen.dart';
import 'package:lms/core/services/lecture_service.dart';
import 'package:lms/core/services/package_service.dart';
import 'package:lms/features/courses/screens/add_lecture_screen.dart';
import 'package:lms/features/courses/screens/add_package_screen.dart';
import 'package:lms/core/models/lecture_model.dart';
import 'package:lms/core/models/package_model.dart';
import 'package:lms/features/tasks/screens/submissions_view.dart';
import 'package:lms/core/providers/theme_provider.dart';
import 'package:lms/features/dashboard/screens/manage_policy_screen.dart';
import 'package:lms/features/dashboard/screens/manage_help_screen.dart';
import 'package:lms/features/dashboard/screens/students_directory_tab.dart';

// ── Theme-aware color helper ─────────────────────────────────────────────────
class _DashboardColors {
  final bool isDark;
  _DashboardColors(this.isDark);

  Color get bgColor1 => isDark ? const Color(0xFF080510) : const Color(0xFFF8F5FF);
  Color get bgColor2 => isDark ? const Color(0xFF150C2E) : const Color(0xFFEDE5FF);
  Color get bgColor3 => isDark ? const Color(0xFF1A1242) : const Color(0xFFE0D4F7);
  Color get bgColor4 => isDark ? const Color(0xFF0D0820) : const Color(0xFFF2EEFF);

  Color get cardBg => isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white.withValues(alpha: 0.75);
  Color get cardBorder => isDark ? Colors.white.withValues(alpha: 0.10) : Colors.white.withValues(alpha: 0.9);

  Color get accentPrimary => const Color(0xFF7C3AED);

  Color get textPrimary => isDark ? Colors.white : const Color(0xFF1A0845);
  Color get textSecondary => isDark ? const Color(0xFFD4C5FF) : const Color(0xFF5B3D8F);
  Color get textHint => isDark ? Colors.white.withValues(alpha: 0.5) : const Color(0xFF8B7AAD);
  
  List<BoxShadow> get cardShadow => isDark
      ? [
          BoxShadow(color: const Color(0xFF7C3AED).withValues(alpha: 0.15), blurRadius: 30, offset: const Offset(0, 8)),
          BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, 10)),
        ]
      : [
          BoxShadow(color: const Color(0xFF7C3AED).withValues(alpha: 0.08), blurRadius: 24, offset: const Offset(0, 12)),
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 6)),
        ];
}

/// Responsive Teacher Dashboard – sidebar nav on wide screens, bottom nav on mobile.
/// Serves as the master dashboard for the app owner/instructor.
class TeacherDashboard extends StatefulWidget {
  const TeacherDashboard({super.key});

  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  int _selectedIndex = 0;

  final List<_NavDestination> _navItems = const [
    _NavDestination(icon: Icons.dashboard_rounded, label: 'Dashboard'),
    _NavDestination(icon: Icons.people_rounded, label: 'Students'),
    _NavDestination(icon: Icons.school_rounded, label: 'Courses'),
    _NavDestination(icon: Icons.assignment_turned_in_rounded, label: 'Submissions'),
    _NavDestination(icon: Icons.settings_rounded, label: 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    // ── Role guard ──────────────────────────────────────────────────────────
    final userModel = context.watch<AuthProvider>().userModel;
    final userRole = userModel?.role.toLowerCase() ?? '';
    if (userRole != 'teacher' && userRole != 'instructor' && userRole != 'admin') {
      // Unauthorized — bounce back
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Access denied. Teacher privileges required.'),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final width = MediaQuery.of(context).size.width;
    final isWide = width >= 768;
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final c = _DashboardColors(isDark);

    return Scaffold(
      extendBody: true,
      backgroundColor: c.bgColor1,
      body: Stack(
        children: [
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
          Positioned.fill(
            child: isWide ? _buildWideLayout(c) : _buildNarrowLayout(c),
          ),
        ],
      ),
      bottomNavigationBar: isWide ? null : _buildBottomNav(c),
      floatingActionButton: _selectedIndex == 2
          ? FloatingActionButton.extended(
              onPressed: () {
                _showAddContentOptions(context, c);
              },
              backgroundColor: c.accentPrimary,
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: Text(
                'Create',
                style: AppTextStyles.label.copyWith(color: Colors.white),
              ),
            )
          : null,
    );
  }

  void _showAddContentOptions(BuildContext context, _DashboardColors c) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: c.cardBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: c.cardBorder),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Create New Content', style: AppTextStyles.heading3.copyWith(color: c.textPrimary)),
            const SizedBox(height: 16),
            ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: c.accentPrimary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.video_library_rounded,
                  color: c.accentPrimary,
                ),
              ),
              title: Text('New Course', style: TextStyle(color: c.textPrimary)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddLectureScreen()),
                );
              },
            ),
            const SizedBox(height: 8),
            ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.inventory_2_rounded,
                  color: AppColors.accent,
                ),
              ),
              title: Text('New Package', style: TextStyle(color: c.textPrimary)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddPackageScreen()),
                );
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ── Wide (Tablet / Web) ───────────────────────────────
  Widget _buildWideLayout(_DashboardColors c) {
    return Row(
      children: [
        // Sidebar
        Container(
          width: 260,
          decoration: BoxDecoration(
            color: c.cardBg,
            border: Border(
              right: BorderSide(
                color: c.cardBorder,
                width: 1,
              ),
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 32),
                // Brand
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: c.accentPrimary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.cast_for_education_rounded,
                        color: c.accentPrimary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text('Instructor', style: AppTextStyles.heading3.copyWith(color: c.textPrimary)),
                  ],
                ),
                const SizedBox(height: 40),
                // Nav items
                ..._navItems.asMap().entries.map((entry) {
                  final i = entry.key;
                  final item = entry.value;
                  final selected = i == _selectedIndex;
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    child: Material(
                      color: selected
                          ? c.accentPrimary.withValues(alpha: 0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => setState(() => _selectedIndex = i),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                item.icon,
                                color: selected
                                    ? c.accentPrimary
                                    : c.textHint,
                                size: 22,
                              ),
                              const SizedBox(width: 14),
                              Text(
                                item.label,
                                style: AppTextStyles.label.copyWith(
                                  color: selected
                                      ? c.accentPrimary
                                      : c.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
                const Spacer(),
                // Sign out
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => context.read<AuthProvider>().signOut(),
                      icon: Icon(
                        Icons.logout_rounded,
                        color: c.textSecondary,
                        size: 20,
                      ),
                      label: Text('Sign Out', style: AppTextStyles.bodyMedium.copyWith(color: c.textPrimary)),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: c.textHint.withValues(alpha: 0.2),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
        // Content
        Expanded(child: _buildContent(c)),
      ],
    );
  }

  // ── Narrow (Mobile) ───────────────────────────────────
  Widget _buildNarrowLayout(_DashboardColors c) {
    return _buildContent(c);
  }

  Widget _buildBottomNav(_DashboardColors c) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          MediaQuery.sizeOf(context).width * 0.04,
          0,
          MediaQuery.sizeOf(context).width * 0.04,
          20,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(40),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              decoration: BoxDecoration(
                color: c.cardBg, // Reusing existing card bg color
                borderRadius: BorderRadius.circular(40),
                border: Border.all(
                  color: c.cardBorder,
                  width: 1.5,
                ),
                boxShadow: c.cardShadow,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(_navItems.length, (index) {
                  final bool isActive = _selectedIndex == index;
                  return _BottomNavItem(
                    icon: _navItems[index].icon,
                    label: _navItems[index].label,
                    isActive: isActive,
                    isDark: context.read<ThemeProvider>().isDarkMode,
                    onTap: () => setState(() => _selectedIndex = index),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Content Panels ────────────────────────────────────
  Widget _buildContent(_DashboardColors c) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.userModel;

    return Container(
      color: Colors.transparent, // Background now handled by Stack gradient
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with back button for mobile
              if (_selectedIndex != 2) ...[
                Row(
                  children: [
                    if (MediaQuery.of(context).size.width < 768)
                      Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: IconButton(
                          icon: Icon(Icons.arrow_back_ios_new_rounded, color: c.textPrimary),
                          onPressed: () => Navigator.pop(context),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Instructor Dashboard',
                            style: AppTextStyles.heading2.copyWith(color: c.textPrimary),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Welcome back, ${user?.name ?? 'Teacher'}',
                            style: AppTextStyles.bodyMedium.copyWith(color: c.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    if (MediaQuery.of(context).size.width < 768)
                      IconButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ProfileScreen(),
                          ),
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: c.accentPrimary.withValues(
                            alpha: 0.08,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: Icon(
                          Icons.person_rounded,
                          color: c.accentPrimary,
                          size: 22,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 28),
              ],

              // ── Dynamic Content based on selected tab ──
              if (_selectedIndex == 0)
                const AdminAnalyticsScreen()
              else if (_selectedIndex == 1)
                _buildStudentsTab(context, c)
              else if (_selectedIndex == 2)
                _buildCoursesTab(context, c)
              else if (_selectedIndex == 3)
                const SubmissionsView()
              else if (_selectedIndex == 4)
                _buildSettingsTab(context, c)
              else ...[
                Text(
                  _navItems[_selectedIndex].label,
                  style: AppTextStyles.heading2.copyWith(color: c.textPrimary),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    color: c.cardBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: c.cardBorder,
                    ),
                    boxShadow: c.cardShadow,
                  ),
                  child: Column(
                    children: [
                      Icon(
                        _navItems[_selectedIndex].icon,
                        color: c.textHint.withValues(alpha: 0.3),
                        size: 56,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${_navItems[_selectedIndex].label} management coming soon.',
                        style: AppTextStyles.bodyMedium.copyWith(color: c.textSecondary),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ── Courses Tab ───────────────────────────────────────
  Widget _buildCoursesTab(BuildContext context, _DashboardColors c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header for Courses Tab
        Text('Manage Courses', style: AppTextStyles.heading2.copyWith(color: c.textPrimary)),
        const SizedBox(height: 16),

        // Action Buttons
        if (MediaQuery.of(context).size.width >= 768)
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddLectureScreen()),
                ),
                icon: const Icon(Icons.add_box_rounded, size: 18),
                label: const Text('New Course'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: c.accentPrimary,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddPackageScreen()),
                ),
                icon: const Icon(Icons.collections_bookmark_rounded, size: 18),
                label: const Text('New Package'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        const SizedBox(height: 24),

        Text('Active Courses', style: AppTextStyles.heading3.copyWith(color: c.textPrimary)),
        const SizedBox(height: 12),
        StreamBuilder<List<LectureModel>>(
          stream: LectureService().getAllLecturesStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}', style: TextStyle(color: c.textPrimary)));
            }
            final lectures = snapshot.data ?? [];
            if (lectures.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(32),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: c.cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: c.cardBorder,
                  ),
                  boxShadow: c.cardShadow,
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.school_outlined,
                      size: 48,
                      color: c.textHint,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No courses created yet.',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: c.textHint,
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.separated(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: lectures.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final lecture = lectures[index];
                return _buildLectureCard(context, lecture, c);
              },
            );
          },
        ),
        const SizedBox(height: 32),
        Text('Active Packages', style: AppTextStyles.heading3.copyWith(color: c.textPrimary)),
        const SizedBox(height: 12),
        StreamBuilder<List<PackageModel>>(
          stream: PackageService().getAllPackagesStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final packages = snapshot.data ?? [];
            if (packages.isEmpty) return Text('No packages created yet.', style: TextStyle(color: c.textHint));

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: packages.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final p = packages[index];
                return ListTile(
                  tileColor: c.cardBg,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: c.cardBorder,
                    ),
                  ),
                  leading: const Icon(
                    Icons.collections_rounded,
                    color: AppColors.accent,
                  ),
                  title: Text(p.title, style: AppTextStyles.bodyLarge.copyWith(color: c.textPrimary)),
                  subtitle: Text(
                    '${p.includedLectureIds.length} Courses inside',
                    style: TextStyle(color: c.textSecondary),
                  ),
                  trailing: Text(
                    '\$${p.price}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddPackageScreen(existingPackage: p),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildLectureCard(BuildContext context, LectureModel lecture, _DashboardColors c) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AddLectureScreen(existingLecture: lecture),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: c.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: c.cardBorder),
          boxShadow: c.cardShadow,
        ),
        child: Row(
          children: [
            Container(
              height: 60,
              width: 60,
              decoration: BoxDecoration(
                color: c.accentPrimary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                image: (lecture.thumbnailUrl.isNotEmpty) // fixed nullability warning
                    ? DecorationImage(
                        image: NetworkImage(lecture.thumbnailUrl), // fixed warning
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: (lecture.thumbnailUrl.isEmpty) // fixed warning
                  ? Icon(Icons.videocam_rounded, color: c.accentPrimary)
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lecture.title,
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                      color: c.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${lecture.lessons.length} Lessons • ${lecture.enrolledCount} Enrolled • ${lecture.isPaid ? "\$${lecture.price}" : "Free"}',
                    style: AppTextStyles.caption.copyWith(color: c.textSecondary),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: c.textHint),
          ],
        ),
      ),
    );
  }
  // ── Students Tab ──────────────────────────────────────────────────────────
  Widget _buildStudentsTab(BuildContext context, _DashboardColors c) {
    return StudentsDirectoryTab(c: c);
  }

  // ── Settings Tab ──────────────────────────────────────────────────────────
  Widget _buildSettingsTab(BuildContext context, _DashboardColors c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Settings',
          style: AppTextStyles.heading2.copyWith(color: c.textPrimary),
        ),
        const SizedBox(height: 24),
        Container(
          decoration: BoxDecoration(
            color: c.cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: c.cardBorder),
            boxShadow: c.cardShadow,
          ),
          child: Column(
            children: [
              _buildSettingTile(
                context: context,
                c: c,
                title: 'Terms & Privacy Policy',
                subtitle: 'Manage the app legal policies',
                icon: Icons.privacy_tip_outlined,
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ManagePolicyScreen()));
                },
              ),
              Divider(color: c.cardBorder, height: 1),
              _buildSettingTile(
                context: context,
                c: c,
                title: 'Help & FAQs',
                subtitle: 'Manage the help and FAQ section',
                icon: Icons.help_outline_rounded,
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ManageHelpScreen()));
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSettingTile({
    required BuildContext context,
    required _DashboardColors c,
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      title: Text(title, style: AppTextStyles.bodyLarge.copyWith(color: c.textPrimary, fontWeight: FontWeight.w600)),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(subtitle, style: AppTextStyles.bodySmall.copyWith(color: c.textSecondary)),
      ),
      leading: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: c.accentPrimary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: c.accentPrimary),
      ),
      trailing: Icon(Icons.chevron_right_rounded, color: c.textHint),
      onTap: onTap,
    );
  }
}

// ── Nav Item ─────────────────────────────────────────────
class _NavDestination {
  final IconData icon;
  final String label;

  const _NavDestination({required this.icon, required this.label});
}

// ── Interactive Bottom Nav Item ────────────────────────────────
class _BottomNavItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final bool isDark;
  final VoidCallback onTap;

  const _BottomNavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_BottomNavItem> createState() => _BottomNavItemState();
}

class _BottomNavItemState extends State<_BottomNavItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.90).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (!widget.isActive) _animController.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    if (!widget.isActive) {
      _animController.reverse();
      HapticFeedback.lightImpact();
    }
    widget.onTap();
  }

  void _handleTapCancel() {
    if (!widget.isActive) _animController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;

    final activeBg = isDark
        ? const Color(0xFF7C3AED).withValues(alpha: 0.25)
        : const Color(0xFF7C3AED).withValues(alpha: 0.12);
    final activeBorder = isDark
        ? const Color(0xFF7C3AED).withValues(alpha: 0.4)
        : const Color(0xFF7C3AED).withValues(alpha: 0.25);
    final activeShadow = isDark
        ? const Color(0xFF7C3AED).withValues(alpha: 0.3)
        : const Color(0xFF7C3AED).withValues(alpha: 0.15);
    final activeIconColor = isDark
        ? const Color(0xFFC084FC)
        : const Color(0xFF7C3AED);
    final inactiveIconColor = isDark
        ? Colors.white.withValues(alpha: 0.45)
        : const Color(0xFF8B7AAD);
    final activeLabelColor = isDark
        ? const Color(0xFFC084FC)
        : const Color(0xFF7C3AED);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOutCubic,
          padding: EdgeInsets.symmetric(
            horizontal: widget.isActive
                ? MediaQuery.sizeOf(context).width * 0.035
                : MediaQuery.sizeOf(context).width * 0.02,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color: widget.isActive ? activeBg : Colors.transparent,
            borderRadius: BorderRadius.circular(30),
            border: widget.isActive
                ? Border.all(color: activeBorder, width: 1.5)
                : Border.all(color: Colors.transparent, width: 1.5),
            boxShadow: widget.isActive
                ? [
                    BoxShadow(
                      color: activeShadow,
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedScale(
                scale: widget.isActive ? 1.05 : 1.0,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutBack,
                child: Icon(
                  widget.icon,
                  size: MediaQuery.sizeOf(context).width < 380 ? 20 : 22,
                  color: widget.isActive ? activeIconColor : inactiveIconColor,
                ),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOutCubic,
                clipBehavior: Clip.hardEdge,
                child: widget.isActive
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(width: 4),
                          Text(
                            widget.label,
                            maxLines: 1,
                            softWrap: false,
                            overflow: TextOverflow.visible,
                            style: TextStyle(
                              color: activeLabelColor,
                              fontWeight: FontWeight.w800,
                              fontSize: MediaQuery.sizeOf(context).width < 380 ? 10 : 12,
                            ),
                          ),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

