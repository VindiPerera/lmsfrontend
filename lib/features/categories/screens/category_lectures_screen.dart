import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lms/core/providers/theme_provider.dart';
import 'package:lms/core/services/lecture_service.dart';
import 'package:lms/core/models/lecture_model.dart';
import 'package:lms/features/dashboard/widgets/lecture_card.dart';
import 'package:lms/features/courses/screens/lecture_details_screen.dart';

// ── Theme-aware color helper ─────────────────────────────────────────────────
class _CatLecturesColors {
  final bool isDark;
  _CatLecturesColors(this.isDark);

  Color get bgColor1 =>
      isDark ? const Color(0xFF080510) : const Color(0xFFF8F5FF);
  Color get bgColor2 =>
      isDark ? const Color(0xFF150C2E) : const Color(0xFFEDE5FF);
  Color get bgColor3 =>
      isDark ? const Color(0xFF1A1242) : const Color(0xFFE0D4F7);
  Color get bgColor4 =>
      isDark ? const Color(0xFF0D0820) : const Color(0xFFF2EEFF);

  Color get textPrimary => isDark ? Colors.white : const Color(0xFF1A0845);
  double get orbOpacity => isDark ? 0.22 : 0.10;
}

class CategoryLecturesScreen extends StatefulWidget {
  final String categoryId;
  final String categoryName;

  const CategoryLecturesScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  State<CategoryLecturesScreen> createState() => _CategoryLecturesScreenState();
}

class _CategoryLecturesScreenState extends State<CategoryLecturesScreen> {
  final LectureService _lectureService = LectureService();

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final c = _CatLecturesColors(isDark);

    return Scaffold(
      backgroundColor: c.bgColor1,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          widget.categoryName,
          style: TextStyle(color: c.textPrimary, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: c.textPrimary),
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
            child: StreamBuilder<List<LectureModel>>(
              stream: _lectureService.getLecturesByCategoryStream(
                widget.categoryId,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: const Color(0xFF7C3AED),
                    ),
                  );
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error: ${snapshot.error}',
                      style: TextStyle(color: c.textPrimary),
                    ),
                  );
                }

                final lectures = snapshot.data ?? [];

                if (lectures.isEmpty) {
                  return Center(
                    child: Text(
                      'No courses found in this category.',
                      style: TextStyle(color: c.textPrimary),
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 24,
                  ),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: lectures.length,
                  itemBuilder: (context, index) {
                    final lecture = lectures[index];
                    return LectureCard(
                      lecture: lecture,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              LectureDetailsScreen(lecture: lecture),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
