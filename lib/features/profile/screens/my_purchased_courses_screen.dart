import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lms/features/auth/providers/auth_provider.dart';
import 'package:lms/core/services/course_access_service.dart';
import 'package:lms/core/services/lecture_service.dart';
import 'package:lms/core/services/package_service.dart';
import 'package:lms/core/models/purchase_model.dart';
import 'package:lms/core/models/lecture_model.dart';
import 'package:lms/core/models/package_model.dart';
import 'package:lms/features/courses/screens/lecture_details_screen.dart';
import 'package:lms/core/providers/theme_provider.dart';

// ── Theme-aware color helper ──────────────────────────────────────────────────
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
}

class MyPurchasedCoursesScreen extends StatefulWidget {
  const MyPurchasedCoursesScreen({super.key});

  @override
  State<MyPurchasedCoursesScreen> createState() =>
      _MyPurchasedCoursesScreenState();
}

class _MyPurchasedCoursesScreenState extends State<MyPurchasedCoursesScreen> {
  final CourseAccessService _courseAccessService = CourseAccessService();
  final LectureService _lectureService = LectureService();
  final PackageService _packageService = PackageService();

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().userModel;
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final c = _CourseColors(isDark);

    return Scaffold(
      backgroundColor: c.bgColor1,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'My Purchased Courses',
          style: TextStyle(color: c.textPrimary, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: c.textPrimary),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [c.bgColor1, c.bgColor2, c.bgColor3, c.bgColor4],
            stops: const [0.0, 0.3, 0.65, 1.0],
          ),
        ),
        child: user == null
            ? Center(
                child: Text(
                  "Please log in first",
                  style: TextStyle(color: c.textPrimary),
                ),
              )
            : SafeArea(
                child: StreamBuilder<List<PurchaseModel>>(
                  stream: _courseAccessService.getUserPurchasesStream(user.uid),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(
                        child: CircularProgressIndicator(color: c.textPrimary),
                      );
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          "Error fetching purchases",
                          style: TextStyle(color: c.textPrimary),
                        ),
                      );
                    }

                    final purchases = snapshot.data ?? [];
                    if (purchases.isEmpty) {
                      return Center(
                        child: Text(
                          "No purchased courses.",
                          style: TextStyle(
                            color: c.textSecondary,
                            fontSize: 16,
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: purchases.length,
                      itemBuilder: (context, index) {
                        return _buildPurchaseItem(purchases[index], c);
                      },
                    );
                  },
                ),
              ),
      ),
    );
  }

  Widget _buildPurchaseItem(PurchaseModel purchase, _CourseColors c) {
    if (purchase.itemType == 'lecture') {
      return FutureBuilder<LectureModel?>(
        future: _lectureService.getLecture(purchase.itemId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return SizedBox(
              height: 100,
              child: Center(
                child: CircularProgressIndicator(
                  color: c.textPrimary.withValues(alpha: 0.5),
                ),
              ),
            );
          }
          final lecture = snapshot.data;
          if (lecture == null) return const SizedBox.shrink();

          return _buildGlassCard(
            c: c,
            title: lecture.title,
            subtitle: "Purchase active • ${lecture.categoryName}",
            imageUrl: lecture.thumbnailUrl,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => LectureDetailsScreen(lecture: lecture),
                ),
              );
            },
          );
        },
      );
    } else if (purchase.itemType == 'package') {
      return FutureBuilder<PackageModel?>(
        future: _packageService.getPackage(purchase.itemId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return SizedBox(
              height: 100,
              child: Center(
                child: CircularProgressIndicator(
                  color: c.textPrimary.withValues(alpha: 0.5),
                ),
              ),
            );
          }
          final package = snapshot.data;
          if (package == null) return const SizedBox.shrink();

          return _buildGlassCard(
            c: c,
            title: package.title,
            subtitle: "Package • Active",
            imageUrl: package.thumbnailUrl,
            onTap: () {}, // Optional
          );
        },
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildGlassCard({
    required _CourseColors c,
    required String title,
    required String subtitle,
    required String imageUrl,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: c.cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: c.cardBorder, width: 1.5),
        boxShadow: c.cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: imageUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: imageUrl,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            width: 80,
                            height: 80,
                            color: c.textPrimary.withValues(alpha: 0.05),
                          ),
                          errorWidget: (context, url, error) => Container(
                            width: 80,
                            height: 80,
                            color: c.textPrimary.withValues(alpha: 0.05),
                            child: Icon(Icons.error, color: c.textSecondary),
                          ),
                        )
                      : Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.school_rounded,
                            color: Colors.orange,
                            size: 40,
                          ),
                        ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: c.textPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        style: TextStyle(fontSize: 13, color: c.textSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: c.textPrimary.withValues(alpha: 0.05),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: c.textPrimary,
                    size: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
