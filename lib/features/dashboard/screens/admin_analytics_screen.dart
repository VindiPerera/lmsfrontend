import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:provider/provider.dart';

import 'package:lms/core/constants/app_colors.dart';
import 'package:lms/core/constants/app_text_styles.dart';
import 'package:lms/core/services/firestore_service.dart';
import 'package:lms/features/auth/models/user_model.dart';
import 'package:lms/features/auth/providers/auth_provider.dart';
import 'package:lms/features/profile/services/teacher_stats_service.dart';
import 'package:lms/core/providers/theme_provider.dart';

class _AdminColors {
  final bool isDark;
  _AdminColors(this.isDark);
  Color get cardBg => isDark
      ? Colors.white.withValues(alpha: 0.06)
      : Colors.white.withValues(alpha: 0.75);
  Color get cardBorder => isDark
      ? Colors.white.withValues(alpha: 0.10)
      : Colors.white.withValues(alpha: 0.9);
  Color get textPrimary => isDark ? Colors.white : const Color(0xFF1A0845);
  Color get textSecondary =>
      isDark ? const Color(0xFFD4C5FF) : const Color(0xFF5B3D8F);
  Color get textHint =>
      isDark ? Colors.white.withValues(alpha: 0.4) : const Color(0xFF8B7AAD);
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
}

class AdminAnalyticsScreen extends StatefulWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  State<AdminAnalyticsScreen> createState() => _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends State<AdminAnalyticsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final TeacherStatsService _statsService = TeacherStatsService();

  bool _isLoading = true;
  List<UserModel> _allUsers = [];

  int _totalUsers = 0;
  int _totalStudents = 0;
  int _totalTeachers = 0;
  double _totalPayments = 0.0;
  int _pendingSlips = 0;

  @override
  void initState() {
    super.initState();
    _fetchAnalyticsData();
  }

  Future<void> _fetchAnalyticsData() async {
    try {
      final users = await _firestoreService.getAllUsers();
      if (!mounted) return;

      int students = 0;
      int teachers = 0;

      for (var u in users) {
        if (u.role.toLowerCase() == 'student') students++;
        if (u.role.toLowerCase() == 'teacher') teachers++;
      }

      // Sort users by createdAt descending for recent activity
      users.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      final userId = context.read<AuthProvider>().userModel?.uid;
      double payments = 0.0;
      int slips = 0;
      if (userId != null) {
        final stats = await _statsService.getTeacherStats(userId);
        payments = stats['totalPayments'] ?? 0.0;
        slips = stats['pendingSlips'] ?? 0;
      }

      setState(() {
        _allUsers = users;
        _totalUsers = users.length;
        _totalStudents = students;
        _totalTeachers = teachers;
        _totalPayments = payments;
        _pendingSlips = slips;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching analytics: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final c = _AdminColors(isDark);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'System Analytics',
          style: AppTextStyles.heading2.copyWith(color: c.textPrimary),
        ),
        const SizedBox(height: 24),

        // ── Summary Cards ──────────────────────────────────────
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 600;
            return GridView.count(
              crossAxisCount: isWide ? 4 : 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: isWide ? 0.9 : 1.1,
              children: [
                _StatCard(
                  label: 'Total payments',
                  value: '\$${_totalPayments.toStringAsFixed(2)}',
                  icon: Icons.account_balance_wallet_rounded,
                  accentColor: AppColors.primary,
                  c: c,
                ),
                _StatCard(
                  label: 'Pending slips',
                  value: _pendingSlips.toString(),
                  icon: Icons.receipt_long_rounded,
                  accentColor: AppColors.warning,
                  c: c,
                ),
                _StatCard(
                  label: 'Total Users',
                  value: _totalUsers.toString(),
                  icon: Icons.people_alt_rounded,
                  accentColor: AppColors.accent,
                  c: c,
                ),
                _StatCard(
                  label: 'Students',
                  value: _totalStudents.toString(),
                  icon: Icons.school_rounded,
                  accentColor: Colors.blue, // Just an extra modern color
                  c: c,
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 32),

        // ── Charts Row (Stacked on Mobile) ─────────────────────
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 800;
            if (isWide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 2, child: _buildBarChart()),
                  const SizedBox(width: 24),
                  Expanded(flex: 1, child: _buildPieChart()),
                ],
              );
            } else {
              return Column(
                children: [
                  _buildBarChart(),
                  const SizedBox(height: 24),
                  _buildPieChart(),
                ],
              );
            }
          },
        ),
        const SizedBox(height: 32),

        // ── Recent Users ───────────────────────────────────────
        Text('Recent Registrations', style: AppTextStyles.heading3),
        const SizedBox(height: 16),
        _buildRecentUsersList(),
      ],
    );
  }

  // ── Bar Chart (New Regs last 7 days) ───────────────────
  Widget _buildBarChart() {
    // Process data for the last 7 days
    final now = DateTime.now();
    final List<int> dailyCounts = List.filled(7, 0);
    final List<String> daysLabels = [];

    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      daysLabels.add(DateFormat('E').format(date)); // e.g., Mon, Tue

      final count = _allUsers.where((u) {
        return u.createdAt.year == date.year &&
            u.createdAt.month == date.month &&
            u.createdAt.day == date.day;
      }).length;
      dailyCounts[6 - i] = count;
    }

    final double maxY = (dailyCounts.reduce((a, b) => a > b ? a : b) + 2)
        .toDouble();

    return Container(
      height: 300,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'New Registrations (Last 7 Days)',
            style: AppTextStyles.heading3,
          ),
          const SizedBox(height: 24),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxY,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            daysLabels[value.toInt()],
                            style: AppTextStyles.caption.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        if (value % 1 != 0) return const SizedBox.shrink();
                        return Text(
                          value.toInt().toString(),
                          style: AppTextStyles.caption,
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: AppColors.textHint.withValues(alpha: 0.1),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: dailyCounts.asMap().entries.map((e) {
                  return BarChartGroupData(
                    x: e.key,
                    barRods: [
                      BarChartRodData(
                        toY: e.value.toDouble(),
                        color: AppColors.primary,
                        width: 16,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(4),
                          topRight: Radius.circular(4),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Pie Chart (Students vs Teachers) ─────────────────────
  Widget _buildPieChart() {
    int students = _totalStudents;
    int teachers = _totalTeachers;
    if (students == 0 && teachers == 0) {
      students = 1; // Fake data to show empty grey chart
    }

    return Container(
      height: 300,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('User Distribution', style: AppTextStyles.heading3),
          const SizedBox(height: 24),
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    sectionsSpace: 4,
                    centerSpaceRadius: 50,
                    startDegreeOffset: -90,
                    sections: [
                      PieChartSectionData(
                        color: _totalStudents == 0 && _totalTeachers == 0
                            ? AppColors.textHint.withValues(alpha: 0.2)
                            : AppColors.accent,
                        value: students.toDouble(),
                        title: _totalStudents == 0 && _totalTeachers == 0
                            ? ''
                            : '${((students / (students + teachers)) * 100).toStringAsFixed(0)}%',
                        radius: 30,
                        titleStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      if (_totalTeachers > 0)
                        PieChartSectionData(
                          color: AppColors.warning,
                          value: teachers.toDouble(),
                          title:
                              '${((teachers / (students + teachers)) * 100).toStringAsFixed(0)}%',
                          radius: 30,
                          titleStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                    ],
                  ),
                ),
                Text(
                  '${_totalStudents + _totalTeachers}\nTotal',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.heading2,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _Indicator(color: AppColors.accent, text: 'Students'),
              const SizedBox(width: 16),
              _Indicator(color: AppColors.warning, text: 'Teachers'),
            ],
          ),
        ],
      ),
    );
  }

  // ── Recent Users List ────────────────────────────────────
  Widget _buildRecentUsersList() {
    final recentUsers = _allUsers.take(5).toList();

    if (recentUsers.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Text('No users found.', style: AppTextStyles.bodyMedium),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: recentUsers.length,
        separatorBuilder: (context, index) => Divider(
          color: AppColors.textHint.withValues(alpha: 0.1),
          height: 1,
        ),
        itemBuilder: (context, index) {
          final u = recentUsers[index];
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 8,
            ),
            leading: CircleAvatar(
              backgroundColor: _roleColor(u.role).withValues(alpha: 0.1),
              child: Icon(
                u.role.toLowerCase() == 'teacher'
                    ? Icons.cast_for_education
                    : Icons.person,
                color: _roleColor(u.role),
              ),
            ),
            title: Text(u.name, style: AppTextStyles.bodyLarge),
            subtitle: Text(
              u.role.toUpperCase(),
              style: AppTextStyles.caption.copyWith(color: _roleColor(u.role)),
            ),
            trailing: Text(
              timeago.format(u.createdAt, locale: 'en_short'),
              style: AppTextStyles.caption,
            ),
          );
        },
      ),
    );
  }

  Color _roleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return AppColors.error;
      case 'teacher':
        return AppColors.warning;
      default:
        return AppColors.accent;
    }
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color accentColor;
  final _AdminColors c;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.accentColor,
    required this.c,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: c.cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: c.cardBorder, width: 1.5),
        boxShadow: c.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: accentColor, size: 28),
              ),
              Icon(Icons.arrow_outward_rounded, color: c.textHint, size: 24),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: c.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: c.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _Indicator extends StatelessWidget {
  final Color color;
  final String text;

  const _Indicator({required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 8),
        Text(text, style: AppTextStyles.caption),
      ],
    );
  }
}
