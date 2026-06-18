import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:lms/core/providers/navigation_provider.dart';
import 'package:lms/core/providers/theme_provider.dart';
import 'package:lms/features/auth/providers/auth_provider.dart';
import 'package:lms/features/home/screens/home_page.dart';
import 'package:lms/features/live_classes/screens/live_classes_page.dart';
import 'package:lms/features/tasks/screens/tasks_page.dart';
import 'package:lms/features/payments/screens/cart_page.dart';
import 'package:lms/features/profile/screens/profile_screen.dart';
import 'package:lms/features/profile/screens/unauthenticated_profile_page.dart';

/// Main navigation shell with a modern floating glass bottom nav bar.
///
/// Tabs: Home • My Courses • Tasks • Cart • Profile
///
/// - Home is the default tab (index 0).
/// - Profile tab (index 4): if not authenticated → shows UnauthenticatedProfilePage.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  static const List<IconData> _navIcons = [
    Icons.home_rounded,
    Icons.ondemand_video_rounded,
    Icons.assignment_rounded,
    Icons.shopping_cart_outlined,
    Icons.person_outline_rounded,
  ];

  static const List<String> _navLabels = [
    'Home',
    'Live class',
    'Tasks',
    'Cart',
    'Profile',
  ];

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final navigationProvider = context.watch<NavigationProvider>();
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final currentIndex = navigationProvider.currentIndex;

    final List<Widget> stackChildren = [
      const HomePage(), // Unified Home Page handles Student/Guest logic
      const LiveClassesPage(),
      const TasksPage(),
      const CartPage(),
      // Profile Tab
      authProvider.isLoading
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : (authProvider.isAuthenticated
                ? const ProfileScreen()
                : const UnauthenticatedProfilePage()),
    ];

    // Theme-aware nav bar colors
    final navBgColor = isDark
        ? const Color(0xFF150C2E).withValues(alpha: 0.85)
        : Colors.white.withValues(alpha: 0.85);
    final navBorderColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.white.withValues(alpha: 0.9);
    final navShadows = isDark
        ? [
            BoxShadow(
              color: const Color(0xFF7C3AED).withValues(alpha: 0.15),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, 15),
            ),
          ]
        : [
            BoxShadow(
              color: const Color(0xFF7C3AED).withValues(alpha: 0.08),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ];

    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: currentIndex, children: stackChildren),
      bottomNavigationBar: SafeArea(
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
                  color: navBgColor,
                  borderRadius: BorderRadius.circular(40),
                  border: Border.all(color: navBorderColor, width: 1.5),
                  boxShadow: navShadows,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(_navIcons.length, (index) {
                    final bool isActive = currentIndex == index;
                    return _NavItem(
                      icon: _navIcons[index],
                      label: _navLabels[index],
                      isActive: isActive,
                      isDark: isDark,
                      onTap: () =>
                          context.read<NavigationProvider>().setIndex(index),
                    );
                  }),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final bool isDark;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem>
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

    // Active item colors
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
                  size: MediaQuery.sizeOf(context).width < 380 ? 22 : 24,
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
                              fontSize: MediaQuery.sizeOf(context).width < 380
                                  ? 11
                                  : 13,
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
