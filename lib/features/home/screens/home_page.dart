import 'dart:math' as math;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lms/core/constants/app_colors.dart';
import 'package:lms/core/constants/app_text_styles.dart';
import 'package:lms/core/providers/theme_provider.dart';
import 'package:lms/features/auth/providers/auth_provider.dart';
import 'package:lms/features/profile/screens/profile_screen.dart';
import 'package:lms/features/auth/screens/login_screen.dart';
import 'package:lms/core/services/lecture_service.dart';
import 'package:lms/core/services/progress_service.dart';
import 'package:lms/core/models/lecture_model.dart';
import 'package:lms/core/models/category_model.dart';
import 'package:lms/core/models/progress_model.dart';
import 'package:lms/features/courses/screens/lecture_details_screen.dart';
import 'package:lms/core/providers/navigation_provider.dart';
import 'package:lms/features/categories/screens/categories_page.dart';
import 'package:lms/features/categories/screens/category_lectures_screen.dart';
import 'package:lms/features/courses/screens/ongoing_courses_screen.dart';
import 'package:lms/features/courses/screens/all_courses_screen.dart';
import 'package:lms/shared/widgets/skeleton_loaders.dart';

// ── Theme-aware color helper ─────────────────────────────────────────────────
class _HomeColors {
  final bool isDark;
  _HomeColors(this.isDark);

  // Background
  Color get bgColor1 =>
      isDark ? const Color(0xFF080510) : const Color(0xFFF8F5FF);
  Color get bgColor2 =>
      isDark ? const Color(0xFF150C2E) : const Color(0xFFEDE5FF);
  Color get bgColor3 =>
      isDark ? const Color(0xFF1A1242) : const Color(0xFFE0D4F7);
  Color get bgColor4 =>
      isDark ? const Color(0xFF0D0820) : const Color(0xFFF2EEFF);

  // Card glass
  Color get cardBg => isDark
      ? Colors.white.withValues(alpha: 0.06)
      : Colors.white.withValues(alpha: 0.75);
  Color get cardBorder => isDark
      ? Colors.white.withValues(alpha: 0.10)
      : Colors.white.withValues(alpha: 0.9);
  Color get cardGlassHigh => isDark
      ? Colors.white.withValues(alpha: 0.08)
      : Colors.white.withValues(alpha: 0.85);

  // Accent
  Color get accentPrimary => const Color(0xFF7C3AED);
  Color get accentBright => const Color(0xFFA855F7);
  Color get accentPale =>
      isDark ? const Color(0xFFC084FC) : const Color(0xFF6D28D9);
  Color get accentGlow =>
      isDark ? const Color(0xFF7C3AED) : const Color(0xFF9333EA);

  // Text
  Color get textPrimary => isDark ? Colors.white : const Color(0xFF1A0845);
  Color get textSecondary =>
      isDark ? const Color(0xFFD4C5FF) : const Color(0xFF5B3D8F);
  Color get textMuted =>
      isDark ? Colors.white.withValues(alpha: 0.5) : const Color(0xFF8B7AAD);
  Color get textOnAccent => Colors.white;

  // Shadows
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

  // Gradient for CTA buttons
  LinearGradient get ctaGradient =>
      const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFFA855F7)]);

  // Orb opacity
  double get orbOpacity => isDark ? 0.22 : 0.10;
}

/// Unified Home Page for all roles (Student, Teacher, Guest)
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final LectureService _lectureService = LectureService();
  final ProgressService _progressService = ProgressService();
  Stream<List<LectureModel>>? _latestLecturesStream;
  Stream<List<CategoryModel>>? _categoriesStream;

  Stream<List<ProgressModel>>? _progressStream;
  String? _lastUserId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final user = context.watch<AuthProvider>().userModel;
    if (user?.uid != _lastUserId) {
      _lastUserId = user?.uid;
      _progressStream = _lastUserId != null
          ? _progressService.getAllProgressStream(_lastUserId!)
          : Stream.value([]);
    }
    // Initialize streams if null
    _latestLecturesStream ??= _lectureService.getPublishedLecturesStream();
    _categoriesStream ??= _lectureService.getCategoriesStream();
  }

  @override
  Future<void> _enrollInCourse(LectureModel lecture, String userId) async {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => LectureDetailsScreen(lecture: lecture)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.userModel;
    final isGuest = !authProvider.isAuthenticated;
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final c = _HomeColors(isDark);

    // Greeting Name Logic
    String greetingName = 'Guest';
    if (!isGuest && user != null && user.name.isNotEmpty) {
      greetingName = user.name.split(' ').first;
    }

    return Scaffold(
      backgroundColor: c.bgColor1,
      body: StreamBuilder<List<ProgressModel>>(
        stream: _progressStream ?? Stream.value([]),
        builder: (context, progressSnapshot) {
          final allProgress = progressSnapshot.data ?? [];
          final ongoingList = allProgress.toList();
          final enrolledLectureIds = allProgress
              .map((p) => p.lectureId)
              .toSet();

          return Stack(
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

              // ── Scrollable Content ──────────────────────────────────────
              SafeArea(
                child: RefreshIndicator(
                  color: c.accentBright,
                  onRefresh: () async {
                    setState(() {
                      if (_lastUserId != null) {
                        _progressStream = _progressService.getAllProgressStream(
                          _lastUserId!,
                        );
                      }
                      _latestLecturesStream = _lectureService
                          .getPublishedLecturesStream();
                      _categoriesStream = _lectureService.getCategoriesStream();
                    });
                    await Future.delayed(const Duration(seconds: 1));
                  },
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    padding: const EdgeInsets.only(bottom: 120),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── 1. Top Header ───────────────────────────────
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      if (isGuest) {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => const LoginScreen(),
                                          ),
                                        );
                                      } else {
                                        context
                                            .read<NavigationProvider>()
                                            .setIndex(4);
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(3),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: c.ctaGradient,
                                        boxShadow: [
                                          BoxShadow(
                                            color: c.accentGlow.withValues(
                                              alpha: 0.4,
                                            ),
                                            blurRadius: 12,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: CircleAvatar(
                                        radius: 22,
                                        backgroundColor: c.bgColor1,
                                        backgroundImage:
                                            (user?.profileImageUrl != null &&
                                                user!
                                                    .profileImageUrl
                                                    .isNotEmpty)
                                            ? NetworkImage(user.profileImageUrl)
                                            : null,
                                        child:
                                            (user?.profileImageUrl == null ||
                                                user!.profileImageUrl.isEmpty)
                                            ? Icon(
                                                Icons.person_outline_rounded,
                                                color: c.accentPale,
                                                size: 26,
                                              )
                                            : null,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Hello, $greetingName',
                                        style: AppTextStyles.heading2.copyWith(
                                          color: c.textPrimary,
                                          fontSize: 22,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        isGuest
                                            ? 'Explore courses'
                                            : 'Welcome back!',
                                        style: AppTextStyles.caption.copyWith(
                                          color: c.textSecondary,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
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
                                    Icons.notifications_none_rounded,
                                    color: c.textSecondary,
                                  ),
                                  onPressed: () {},
                                ),
                              ),
                            ],
                          ),
                        ),

                        // ── 2. Progress / Guest Card ───────────────────────────────
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: isGuest
                              ? _buildGuestWelcomeCard(c)
                              : _buildProgressHeaderCard(ongoingList, c),
                        ),
                        const SizedBox(height: 32),

                        // ── 3. Categories ───────────────────────────────
                        CategorySectionWidget(
                          lectureService: _lectureService,
                          orangeAction: c.accentBright,
                          categoriesStream: _categoriesStream,
                          lecturesStream: _latestLecturesStream,
                          colors: c,
                        ),
                        const SizedBox(height: 32),

                        // ── 4. Latest Lectures ─────────────────────────
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Latest Courses',
                                style: AppTextStyles.heading2.copyWith(
                                  color: c.textPrimary,
                                ),
                              ),
                              GestureDetector(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const AllCoursesScreen(),
                                  ),
                                ),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: c.cardBg,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: c.cardBorder),
                                  ),
                                  child: Text(
                                    'See All',
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: c.accentPale,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 300,
                          child: StreamBuilder<List<LectureModel>>(
                            stream: _latestLecturesStream,
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) {
                                return ListView.separated(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 8,
                                  ),
                                  clipBehavior: Clip.none,
                                  scrollDirection: Axis.horizontal,
                                  itemCount: 3,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(width: 16),
                                  itemBuilder: (_, __) =>
                                      const SkeletonLectureCard(),
                                );
                              }
                              final lectures = snapshot.data!;
                              if (lectures.isEmpty) {
                                return Center(
                                  child: Text(
                                    "No courses available",
                                    style: TextStyle(color: c.textMuted),
                                  ),
                                );
                              }
                              return ListView.separated(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 8,
                                ),
                                clipBehavior: Clip.none,
                                scrollDirection: Axis.horizontal,
                                itemCount: lectures.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(width: 20),
                                itemBuilder: (context, index) {
                                  final l = lectures[index];
                                  final isEnrolled = enrolledLectureIds
                                      .contains(l.id);
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
                          ),
                        ),
                        const SizedBox(height: 32),

                        // ── 5. Ongoing Courses ─────────────────────────────────
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Ongoing Courses',
                                style: AppTextStyles.heading2.copyWith(
                                  color: c.textPrimary,
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  if (ongoingList.isNotEmpty) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => OngoingCoursesScreen(
                                          progressList: ongoingList,
                                        ),
                                      ),
                                    );
                                  }
                                },
                                style: TextButton.styleFrom(
                                  foregroundColor: c.accentPale,
                                ),
                                child: Text(
                                  'See All',
                                  style: AppTextStyles.label.copyWith(
                                    color: c.accentPale,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!isGuest) ...[
                          if (!progressSnapshot.hasData)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 8,
                              ),
                              child: Column(
                                children: List.generate(
                                  3,
                                  (index) => const SkeletonOngoingCard(),
                                ),
                              ),
                            )
                          else if (ongoingList.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                              ),
                              child: Text(
                                "No ongoing courses yet.",
                                style: TextStyle(color: c.textMuted),
                              ),
                            )
                          else
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 8,
                              ),
                              child: Column(
                                children: ongoingList
                                    .map(
                                      (p) => CachedOngoingCard(
                                        key: ValueKey(p.lectureId),
                                        progressModel: p,
                                        orangeAction: c.accentBright,
                                        lectureService: _lectureService,
                                        colors: c,
                                      ),
                                    )
                                    .toList(),
                              ),
                            ),
                        ] else ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 8,
                            ),
                            child: GestureDetector(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const LoginScreen(),
                                ),
                              ),
                              child: Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: c.cardBg,
                                  borderRadius: BorderRadius.circular(28),
                                  border: Border.all(
                                    color: c.cardBorder,
                                    width: 1.5,
                                  ),
                                  boxShadow: c.cardShadow,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            c.accentPrimary.withValues(
                                              alpha: 0.3,
                                            ),
                                            c.accentBright.withValues(
                                              alpha: 0.15,
                                            ),
                                          ],
                                        ),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.lock_outline_rounded,
                                        color: c.accentPale,
                                        size: 28,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Sign in to track progress',
                                            style: AppTextStyles.bodyLarge
                                                .copyWith(
                                                  fontWeight: FontWeight.bold,
                                                  color: c.textPrimary,
                                                ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Save your courses and pick up where you left off.',
                                            style: AppTextStyles.caption
                                                .copyWith(
                                                  color: c.textSecondary,
                                                  height: 1.3,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ── Helper Widgets ─────────────────────────────────────────────────────────

  Widget _buildGuestWelcomeCard(_HomeColors c) {
    return _AnimatedGuestWelcomeCard(colors: c);
  }

  Widget _buildProgressHeaderCard(
    List<ProgressModel> progressList,
    _HomeColors c,
  ) {
    return StreamBuilder<List<LectureModel>>(
      stream: _lectureService.getAllLecturesStream(),
      builder: (context, lectureSnap) {
        double overall = 0.0;
        int percentInt = 0;
        List<ProgressModel> validProgress = progressList;

        if (lectureSnap.hasData) {
          final validLectureIds = lectureSnap.data!.map((l) => l.id).toSet();
          validProgress = progressList
              .where((p) => validLectureIds.contains(p.lectureId))
              .toList();
        }
        if (validProgress.isNotEmpty) {
          overall =
              validProgress.fold(
                0.0,
                (sum, p) => sum + p.completionPercentage.clamp(0.0, 1.0),
              ) /
              validProgress.length;
        }
        percentInt = (overall * 100).toInt();

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                c.accentPrimary.withValues(alpha: c.isDark ? 0.25 : 0.12),
                c.cardBg,
              ],
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: c.cardBorder, width: 1.5),
            boxShadow: c.cardShadow,
          ),
          child: Stack(
            children: [
              // ── Decorative background elements ──
              Positioned(
                right: -15,
                bottom: -15,
                child: Icon(
                  Icons.auto_graph_rounded,
                  size: 120,
                  color: c.accentPrimary.withValues(alpha: 0.04),
                ),
              ),
              Positioned(
                left: 20,
                top: 15,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: c.accentBright.withValues(alpha: 0.3),
                  ),
                ),
              ),
              Positioned(
                right: 50,
                top: 25,
                child: Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: c.accentPale.withValues(alpha: 0.3),
                  ),
                ),
              ),
              // ── Content ──
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                gradient: c.ctaGradient,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.trending_up_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              "Learned today",
                              style: AppTextStyles.bodyMedium.copyWith(
                                fontWeight: FontWeight.w700,
                                color: c.textPrimary,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                        InkWell(
                          onTap: () {},
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              gradient: c.ctaGradient,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: c.accentGlow.withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Text(
                              "My courses",
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // ── Circular progress + stats row ──
                    Row(
                      children: [
                        // Circular Progress Gauge
                        SizedBox(
                          width: 90,
                          height: 90,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                width: 90,
                                height: 90,
                                child: CircularProgressIndicator(
                                  value: overall.clamp(0.0, 1.0),
                                  strokeWidth: 8,
                                  strokeCap: StrokeCap.round,
                                  backgroundColor: c.isDark
                                      ? Colors.white.withValues(alpha: 0.08)
                                      : Colors.white.withValues(alpha: 0.6),
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                        Color(0xFFA855F7),
                                      ),
                                ),
                              ),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    "${percentInt}%",
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w900,
                                      color: c.textPrimary,
                                      letterSpacing: -1,
                                    ),
                                  ),
                                  Text(
                                    "Done",
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: c.textSecondary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 24),
                        // Stats column
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildMiniStat(
                                c,
                                Icons.menu_book_rounded,
                                "${validProgress.length} Courses",
                                "enrolled",
                              ),
                              const SizedBox(height: 10),
                              _buildMiniStat(
                                c,
                                Icons.timer_rounded,
                                "Keep going!",
                                "consistency",
                              ),
                              const SizedBox(height: 14),
                              // Gradient Progress Bar
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Stack(
                                  children: [
                                    Container(
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: c.isDark
                                            ? Colors.white.withValues(
                                                alpha: 0.08,
                                              )
                                            : Colors.white.withValues(
                                                alpha: 0.6,
                                              ),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                    ),
                                    FractionallySizedBox(
                                      widthFactor: overall.clamp(0.01, 1.0),
                                      child: Container(
                                        height: 8,
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [
                                              Color(0xFF6D28D9),
                                              Color(0xFFA855F7),
                                              Color(0xFFC084FC),
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(
                                                0xFFA855F7,
                                              ).withValues(alpha: 0.5),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
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
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMiniStat(
    _HomeColors c,
    IconData icon,
    String value,
    String label,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: c.accentPrimary.withValues(alpha: c.isDark ? 0.15 : 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: c.accentBright),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: c.textPrimary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLectureCard(
    BuildContext context,
    LectureModel l,
    bool isEnrolled,
    dynamic user,
    _HomeColors c,
  ) {
    return GestureDetector(
      onTap: () {
        if (!isEnrolled && user != null) {
          _enrollInCourse(l, user.uid);
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
        width: 260,
        decoration: BoxDecoration(
          color: c.cardBg,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: c.cardBorder, width: 1.5),
          boxShadow: c.cardShadow,
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Hero(
              tag: 'lecture_${l.id}',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  color: c.isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.grey.withValues(alpha: 0.1),
                  height: 130,
                  width: double.infinity,
                  child: l.thumbnailUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: l.thumbnailUrl,
                          fit: BoxFit.cover,
                        )
                      : Icon(
                          Icons.image_outlined,
                          color: c.accentBright.withValues(alpha: 0.5),
                          size: 40,
                        ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              l.title,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: c.textPrimary,
                letterSpacing: -0.3,
              ),
              maxLines: 1,
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
                    color: c.accentPrimary.withValues(
                      alpha: c.isDark ? 0.2 : 0.1,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: c.accentPrimary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    l.categoryName,
                    style: TextStyle(
                      fontSize: 10,
                      color: c.accentPale,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  l.isPaid ? '\$${l.price}' : 'Free',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: c.textSecondary,
                  ),
                ),
              ],
            ),
            const Spacer(),
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
                                  c,
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
                    gradient: c.ctaGradient,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: c.accentGlow.withValues(alpha: 0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
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

  Widget _buildRealAvatar(String url, _HomeColors c) {
    return CircleAvatar(
      radius: 12,
      backgroundColor: c.isDark ? const Color(0xFF2D1B69) : Colors.white,
      child: CircleAvatar(
        radius: 10,
        backgroundImage: CachedNetworkImageProvider(url),
      ),
    );
  }

  Widget _buildOngoingCard(
    BuildContext context,
    LectureModel l,
    ProgressModel p,
    _HomeColors c,
  ) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => LectureDetailsScreen(lecture: l)),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: c.cardBg,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: c.cardBorder, width: 1.5),
          boxShadow: c.cardShadow,
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: 100,
                height: 70,
                color: c.isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.grey[200],
                child: l.thumbnailUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: l.thumbnailUrl,
                        fit: BoxFit.cover,
                      )
                    : Icon(Icons.image, color: c.accentPale),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: c.textPrimary,
                    ),
                    maxLines: 1,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        "${l.lessons.length} Lessons",
                        style: TextStyle(fontSize: 12, color: c.textSecondary),
                      ),
                      const SizedBox(width: 4),
                      Text("|", style: TextStyle(color: c.accentPrimary)),
                      const SizedBox(width: 4),
                      Text(
                        "${l.resources.length} PDFs",
                        style: TextStyle(fontSize: 12, color: c.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Stack(
                    alignment: Alignment.centerLeft,
                    children: [
                      Container(
                        height: 6,
                        decoration: BoxDecoration(
                          color: c.isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : const Color(0xFFE0E7FF),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: p.completionPercentage.clamp(0.01, 1.0),
                        child: Container(
                          height: 6,
                          decoration: BoxDecoration(
                            gradient: c.ctaGradient,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "${(p.completionPercentage.clamp(0.0, 1.0) * 100).toInt()}% Done",
                  style: TextStyle(
                    fontSize: 10,
                    color: c.accentPale,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: c.accentPrimary.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: c.accentPale,
                    size: 14,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Category Icons mapping ──────────────────────────────────────────────────
IconData _getCategoryIcon(String name) {
  final lower = name.toLowerCase();
  if (lower.contains('grammar')) return Icons.spellcheck_rounded;
  if (lower.contains('ielts')) return Icons.language_rounded;
  if (lower.contains('speak')) return Icons.mic_rounded;
  if (lower.contains('write') || lower.contains('writing'))
    return Icons.edit_note_rounded;
  if (lower.contains('read')) return Icons.chrome_reader_mode_rounded;
  if (lower.contains('listen')) return Icons.headphones_rounded;
  if (lower.contains('vocab')) return Icons.abc_rounded;
  if (lower.contains('math')) return Icons.calculate_rounded;
  if (lower.contains('science')) return Icons.science_rounded;
  if (lower.contains('code') || lower.contains('program'))
    return Icons.code_rounded;
  return Icons.school_rounded;
}

// ── Category gradient colors ────────────────────────────────────────────────
List<Color> _getCategoryGradient(int index) {
  const gradients = [
    [Color(0xFF7C3AED), Color(0xFF9333EA)],
    [Color(0xFF6D28D9), Color(0xFF7C3AED)],
    [Color(0xFF8B5CF6), Color(0xFFA855F7)],
    [Color(0xFF5B21B6), Color(0xFF7C3AED)],
    [Color(0xFF6366F1), Color(0xFF8B5CF6)],
    [Color(0xFF9333EA), Color(0xFFC084FC)],
  ];
  return gradients[index % gradients.length];
}

class CategorySectionWidget extends StatefulWidget {
  final LectureService lectureService;
  final Color orangeAction;
  final Stream<List<CategoryModel>>? categoriesStream;
  final Stream<List<LectureModel>>? lecturesStream;
  final _HomeColors colors;

  const CategorySectionWidget({
    Key? key,
    required this.lectureService,
    required this.orangeAction,
    this.categoriesStream,
    this.lecturesStream,
    required this.colors,
  }) : super(key: key);

  @override
  State<CategorySectionWidget> createState() => _CategorySectionWidgetState();
}

class _CategorySectionWidgetState extends State<CategorySectionWidget> {
  String _selectedCategoryId = 'all';

  @override
  Widget build(BuildContext context) {
    final c = widget.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Categories',
                style: AppTextStyles.heading2.copyWith(
                  fontSize: 20,
                  color: c.textPrimary,
                ),
              ),
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CategoriesPage()),
                ),
                child: Text(
                  'See All',
                  style: TextStyle(
                    color: c.accentPale,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        StreamBuilder<List<CategoryModel>>(
          stream:
              widget.categoriesStream ??
              widget.lectureService.getCategoriesStream(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Column(
                children: [
                  SizedBox(
                    height: 40,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      children: List.generate(
                        4,
                        (index) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Container(
                            width: 80,
                            decoration: BoxDecoration(
                              color: c.cardBg,
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 250,
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                      clipBehavior: Clip.none,
                      scrollDirection: Axis.horizontal,
                      itemCount: 3,
                      separatorBuilder: (_, __) => const SizedBox(width: 16),
                      itemBuilder: (_, __) => const SkeletonCategoryCard(),
                    ),
                  ),
                ],
              );
            }
            final categories = snapshot.data!;
            return StreamBuilder<List<LectureModel>>(
              stream:
                  widget.lecturesStream ??
                  widget.lectureService.getPublishedLecturesStream(),
              builder: (context, lectureSnapshot) {
                final publishedLectures =
                    lectureSnapshot.data ?? const <LectureModel>[];
                final totalsByCategory = <String, Map<String, int>>{};

                for (final lecture in publishedLectures) {
                  final totals = totalsByCategory.putIfAbsent(
                    lecture.categoryId,
                    () => {
                      'lectureCount': 0,
                      'lessonCount': 0,
                      'resourceCount': 0,
                    },
                  );
                  totals['lectureCount'] = (totals['lectureCount'] ?? 0) + 1;
                  totals['lessonCount'] =
                      (totals['lessonCount'] ?? 0) + lecture.lessons.length;
                  totals['resourceCount'] =
                      (totals['resourceCount'] ?? 0) + lecture.resources.length;
                }

                return Column(
                  children: [
                    SizedBox(
                      height: 40,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        children: [
                          _buildCategoryChip(
                            c,
                            'All',
                            _selectedCategoryId == 'all',
                            () => setState(() => _selectedCategoryId = 'all'),
                          ),
                          const SizedBox(width: 8),
                          ...categories.map(
                            (cat) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: _buildCategoryChip(
                                c,
                                cat.name,
                                _selectedCategoryId == cat.id,
                                () => setState(
                                  () => _selectedCategoryId = cat.id,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 250,
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                        clipBehavior: Clip.none,
                        scrollDirection: Axis.horizontal,
                        itemCount: categories.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 16),
                        itemBuilder: (context, index) {
                          final cat = categories[index];
                          if (_selectedCategoryId != 'all' &&
                              cat.id != _selectedCategoryId) {
                            return const SizedBox.shrink();
                          }

                          final totals = totalsByCategory[cat.id];
                          final lectureCount =
                              totals?['lectureCount'] ?? cat.lectureCount;
                          final lessonCount = totals?['lessonCount'] ?? 0;
                          final resourceCount = totals?['resourceCount'] ?? 0;

                          return _buildCategoryStatCard(
                            context,
                            cat,
                            c,
                            index,
                            lectureCount: lectureCount,
                            lessonCount: lessonCount,
                            resourceCount: resourceCount,
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildCategoryChip(
    _HomeColors c,
    String label,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: isSelected ? c.ctaGradient : null,
          color: isSelected ? null : c.cardBg,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isSelected ? Colors.transparent : c.cardBorder,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: c.accentGlow.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : c.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryStatCard(
    BuildContext context,
    CategoryModel cat,
    _HomeColors c,
    int index, {
    required int lectureCount,
    required int lessonCount,
    required int resourceCount,
  }) {
    final gradientColors = _getCategoryGradient(index);
    final categoryIcon = _getCategoryIcon(cat.name);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CategoryLecturesScreen(
              categoryId: cat.id,
              categoryName: cat.name,
            ),
          ),
        );
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 235,
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: c.isDark
                    ? [
                        gradientColors[0].withValues(alpha: 0.25),
                        gradientColors[1].withValues(alpha: 0.08),
                      ]
                    : [
                        gradientColors[0].withValues(alpha: 0.12),
                        Colors.white.withValues(alpha: 0.9),
                      ],
              ),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: c.cardBorder, width: 1.5),
              boxShadow: c.cardShadow,
            ),
            child: Stack(
              children: [
                // ── Large decorative icon in background ──
                Positioned(
                  right: -10,
                  bottom: -10,
                  child: Icon(
                    categoryIcon,
                    size: 80,
                    color: gradientColors[0].withValues(
                      alpha: c.isDark ? 0.08 : 0.06,
                    ),
                  ),
                ),
                // ── Content ──
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category icon badge + name
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: gradientColors),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: gradientColors[0].withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Icon(
                            categoryIcon,
                            size: 18,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            cat.name,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: c.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$lectureCount',
                                style: TextStyle(
                                  fontSize: 40,
                                  height: 0.95,
                                  fontWeight: FontWeight.w800,
                                  color: c.accentPale,
                                ),
                              ),
                              Text(
                                'Courses',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: c.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildCategoryMetric(
                              c,
                              Icons.smart_display_outlined,
                              '$lessonCount Lessons',
                            ),
                            const SizedBox(height: 8),
                            _buildCategoryMetric(
                              c,
                              Icons.description_outlined,
                              '$resourceCount Resources',
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
          Positioned(
            right: 16,
            bottom: 16,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: gradientColors),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: gradientColors[0].withValues(alpha: 0.5),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(
                Icons.arrow_forward_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryMetric(_HomeColors c, IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: c.accentPale),
        const SizedBox(width: 7),
        Text(
          text,
          style: TextStyle(
            fontSize: 13,
            color: c.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class CachedOngoingCard extends StatefulWidget {
  final ProgressModel progressModel;
  final Color orangeAction;
  final LectureService lectureService;
  final _HomeColors? colors;

  const CachedOngoingCard({
    Key? key,
    required this.progressModel,
    required this.orangeAction,
    required this.lectureService,
    this.colors,
  }) : super(key: key);

  @override
  State<CachedOngoingCard> createState() => _CachedOngoingCardState();
}

class _CachedOngoingCardState extends State<CachedOngoingCard> {
  Future<LectureModel?>? _future;

  @override
  void initState() {
    super.initState();
    _future = widget.lectureService.getLecture(widget.progressModel.lectureId);
  }

  @override
  void didUpdateWidget(CachedOngoingCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progressModel.lectureId != widget.progressModel.lectureId) {
      _future = widget.lectureService.getLecture(
        widget.progressModel.lectureId,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final c = widget.colors ?? _HomeColors(isDark);
    return FutureBuilder<LectureModel?>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const SkeletonOngoingCard();
        }
        if (snap.hasError || snap.data == null) {
          return const SizedBox.shrink();
        }
        final l = snap.data!;
        final p = widget.progressModel;
        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => LectureDetailsScreen(lecture: l)),
          ),
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [c.cardGlassHigh, c.cardBg],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: c.cardBorder, width: 1.5),
              boxShadow: c.cardShadow,
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: 100,
                    height: 70,
                    color: c.isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.grey[200],
                    child: l.thumbnailUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: l.thumbnailUrl,
                            fit: BoxFit.cover,
                          )
                        : Icon(Icons.image, color: c.accentPale),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: c.textPrimary,
                        ),
                        maxLines: 1,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            "${l.lessons.length} Lessons",
                            style: TextStyle(
                              fontSize: 12,
                              color: c.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text("|", style: TextStyle(color: c.accentPrimary)),
                          const SizedBox(width: 4),
                          Text(
                            "${l.resources.length} PDFs",
                            style: TextStyle(
                              fontSize: 12,
                              color: c.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Stack(
                        alignment: Alignment.centerLeft,
                        children: [
                          Container(
                            height: 6,
                            decoration: BoxDecoration(
                              color: c.isDark
                                  ? Colors.white.withValues(alpha: 0.08)
                                  : Colors.white.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          FractionallySizedBox(
                            widthFactor: p.completionPercentage.clamp(
                              0.01,
                              1.0,
                            ),
                            child: Container(
                              height: 6,
                              decoration: BoxDecoration(
                                gradient: c.ctaGradient,
                                borderRadius: BorderRadius.circular(3),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFFA855F7,
                                    ).withValues(alpha: 0.4),
                                    blurRadius: 6,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "${(p.completionPercentage.clamp(0.0, 1.0) * 100).toInt()}% Done",
                      style: TextStyle(
                        fontSize: 12,
                        color: c.accentPale,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: c.accentPrimary.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: c.accentPale,
                        size: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AnimatedGuestWelcomeCard extends StatefulWidget {
  final _HomeColors colors;
  const _AnimatedGuestWelcomeCard({super.key, required this.colors});

  @override
  State<_AnimatedGuestWelcomeCard> createState() =>
      _AnimatedGuestWelcomeCardState();
}

class _AnimatedGuestWelcomeCardState extends State<_AnimatedGuestWelcomeCard> {
  int _currentIndex = 0;
  // Modern, high-quality educational / interactive abstract stock images
  final List<String> _images = [
    'https://images.unsplash.com/photo-1516321318423-f06f85e504b3?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80',
    'https://images.unsplash.com/photo-1522202176988-66273c2fd55f?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80',
    'https://images.unsplash.com/photo-1501504905252-473c47e087f8?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80',
    'https://images.unsplash.com/photo-1434030216411-0b793f4b4173?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80',
  ];

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    Future.delayed(const Duration(seconds: 6), () {
      if (mounted) {
        setState(() {
          _currentIndex = (_currentIndex + 1) % _images.length;
        });
        _startTimer();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.colors;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: c.cardBorder, width: 1.5),
        boxShadow: c.cardShadow,
      ),
      child: Stack(
        children: [
          // Background Crossfade Image Slider
          Positioned.fill(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 1500),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(opacity: animation, child: child);
              },
              child: CachedNetworkImage(
                key: ValueKey<int>(_currentIndex),
                imageUrl: _images[_currentIndex],
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                placeholder: (context, url) => Container(color: c.cardBg),
                errorWidget: (context, url, error) =>
                    Container(color: c.cardBg),
              ),
            ),
          ),

          // Gradient Glass Overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    c.cardBg.withValues(
                      alpha: 0.98,
                    ), // High opacity near the reading text
                    c.cardBg.withValues(alpha: 0.65), // Medium opacity center
                    c.accentPrimary.withValues(
                      alpha: 0.40,
                    ), // Colorful tint at the bottom right
                  ],
                  stops: const [0.0, 0.55, 1.0],
                ),
              ),
            ),
          ),

          // The Original Custom Content
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: c.ctaGradient,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.waving_hand_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  "Welcome to FaceTalk!",
                  style: AppTextStyles.heading2.copyWith(
                    fontSize: 22,
                    color: c.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Sign in to access your modules and track progress.",
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: c.textSecondary,
                  ),
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      gradient: c.ctaGradient,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: c.accentGlow.withValues(alpha: 0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "Login / Register",
                          style: AppTextStyles.label.copyWith(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          size: 18,
                          color: Colors.white,
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
}
