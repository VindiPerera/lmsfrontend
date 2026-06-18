import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lms/core/constants/app_text_styles.dart';
import 'package:lms/core/models/lecture_model.dart';
import 'package:lms/core/models/progress_model.dart';
import 'package:lms/core/services/lecture_service.dart';
import 'package:lms/core/services/progress_service.dart';
import 'package:lms/features/courses/screens/lecture_details_screen.dart';
import 'package:lms/features/auth/providers/auth_provider.dart';
import 'package:lms/features/auth/screens/login_screen.dart';
import 'package:lms/core/providers/theme_provider.dart';

// ── Theme-aware color helper ─────────────────────────────────────────────────
class _CourseColors {
  final bool isDark;
  _CourseColors(this.isDark);

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

class AllCoursesScreen extends StatefulWidget {
  const AllCoursesScreen({super.key});

  @override
  State<AllCoursesScreen> createState() => _AllCoursesScreenState();
}

class _AllCoursesScreenState extends State<AllCoursesScreen> {
  final LectureService _lectureService = LectureService();
  final ProgressService _progressService = ProgressService();
  String _searchQuery = '';

  Widget _buildRealAvatar(String url) {
    return CircleAvatar(
      radius: 12,
      backgroundColor: Colors.white,
      child: CircleAvatar(
        radius: 10,
        backgroundImage: CachedNetworkImageProvider(url),
      ),
    );
  }

  Widget _buildLectureCard(
    BuildContext context,
    LectureModel l,
    bool isEnrolled,
    dynamic user,
    _CourseColors c,
  ) {
    return GestureDetector(
      onTap: () {
        if (!isEnrolled && user != null) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => LectureDetailsScreen(lecture: l)),
          );
        } else if (isEnrolled) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => LectureDetailsScreen(lecture: l)),
          );
        } else if (user == null) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          );
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: c.cardBg,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: c.cardBorder, width: 1.5),
          boxShadow: c.cardShadow,
        ),
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Hero(
              tag: 'lecture_all_${l.id}',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  color: c.isDark
                      ? Colors.black.withValues(alpha: 0.3)
                      : Colors.white.withValues(alpha: 0.5),
                  height: 180,
                  width: double.infinity,
                  child: l.thumbnailUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: l.thumbnailUrl,
                          fit: BoxFit.cover,
                        )
                      : Icon(
                          Icons.image_outlined,
                          color: c.accentPale,
                          size: 40,
                        ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l.title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: c.textPrimary,
                letterSpacing: -0.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: c.accentPrimary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    l.categoryName,
                    style: TextStyle(
                      fontSize: 10,
                      color: c.accentBright,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  l.isPaid ? '\$${l.price}' : 'Free',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    color: c.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                SizedBox(
                  width: 50,
                  height: 24,
                  child: Stack(
                    children: l.enrolledStudentAvatars.isNotEmpty
                        ? [
                            for (
                              int i = 0;
                              i < l.enrolledStudentAvatars.length && i < 3;
                              i++
                            )
                              Positioned(
                                left: i * 14.0,
                                child: _buildRealAvatar(
                                  l.enrolledStudentAvatars[i],
                                ),
                              ),
                          ]
                        : [],
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: c.accentPrimary,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    children: [
                      Text(
                        isEnrolled ? "Continue" : "Enroll now",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white,
                        size: 14,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().userModel;
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final c = _CourseColors(isDark);

    return Scaffold(
      backgroundColor: c.bgColor1,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: c.textPrimary),
        title: Text(
          'All Courses',
          style: AppTextStyles.heading2.copyWith(color: c.textPrimary),
        ),
        centerTitle: true,
      ),
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

          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: c.cardBg,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: c.cardBorder, width: 1.5),
                      boxShadow: c.isDark
                          ? [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 20,
                              ),
                            ]
                          : [],
                    ),
                    child: TextField(
                      style: TextStyle(color: c.textPrimary),
                      onChanged: (val) {
                        setState(() {
                          _searchQuery = val.toLowerCase();
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Search courses...',
                        hintStyle: TextStyle(color: c.textSecondary),
                        border: InputBorder.none,
                        icon: Icon(Icons.search, color: c.textSecondary),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: StreamBuilder<List<LectureModel>>(
                    stream: _lectureService.getPublishedLecturesStream(),
                    builder: (context, lectureSnapshot) {
                      if (lectureSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return Center(
                          child: CircularProgressIndicator(
                            color: c.accentPrimary,
                          ),
                        );
                      }
                      if (lectureSnapshot.hasError) {
                        return Center(
                          child: Text(
                            'Error: ${lectureSnapshot.error}',
                            style: TextStyle(color: c.textPrimary),
                          ),
                        );
                      }

                      final lectures = lectureSnapshot.data ?? [];
                      final filtered = lectures
                          .where(
                            (l) => l.title.toLowerCase().contains(_searchQuery),
                          )
                          .toList();

                      if (filtered.isEmpty) {
                        return Center(
                          child: Text(
                            'No courses found.',
                            style: TextStyle(
                              color: c.textPrimary,
                              fontSize: 16,
                            ),
                          ),
                        );
                      }

                      if (user == null) {
                        return ListView.builder(
                          padding: const EdgeInsets.only(bottom: 24),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            return _buildLectureCard(
                              context,
                              filtered[index],
                              false,
                              user,
                              c,
                            );
                          },
                        );
                      }

                      return StreamBuilder<List<ProgressModel>>(
                        stream: _progressService.getAllProgressStream(user.uid),
                        builder: (context, progressSnapshot) {
                          final enrolledLectureIds =
                              (progressSnapshot.data ?? [])
                                  .map((p) => p.lectureId)
                                  .toSet();

                          return ListView.builder(
                            padding: const EdgeInsets.only(bottom: 24),
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final l = filtered[index];
                              final isEnrolled = enrolledLectureIds.contains(
                                l.id,
                              );
                              return _buildLectureCard(
                                context,
                                l,
                                isEnrolled,
                                user,
                                c,
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
