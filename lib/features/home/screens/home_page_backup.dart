import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:provider/provider.dart';
import 'package:lms/core/constants/app_colors.dart';
import 'package:lms/core/constants/app_text_styles.dart';
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

  static final List<BoxShadow> _cardShadow = [
    BoxShadow(
      color: AppColors.primary.withValues(alpha: 0.08),
      blurRadius: 24,
      offset: const Offset(0, 12),
    ),
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.03),
      blurRadius: 8,
      offset: const Offset(0, 4),
    ),
  ];

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

    // Greeting Name Logic
    String greetingName = 'Guest';
    if (!isGuest && user != null && user.name.isNotEmpty) {
      greetingName = user.name.split(' ').first;
    }

    return Scaffold(
      backgroundColor: const Color(0xFF864AFF), // Fallback base color
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
              // ── Modern Light Mesh Gradient Background ─────────────────────────
              Positioned.fill(
                child: Container(
                  color: const Color(0xFFF9F7FF),
                ), // Clean off-white lilac
              ),
              Positioned(
                top: -150,
                right: -100,
                child: Container(
                  width: 400,
                  height: 400,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF9F70FF).withValues(alpha: 0.15),
                  ),
                ),
              ),
              Positioned(
                bottom: 100,
                left: -150,
                child: Container(
                  width: 500,
                  height: 500,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFC7B1FF).withValues(alpha: 0.2),
                  ),
                ),
              ),
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 120, sigmaY: 120),
                  child: Container(color: Colors.transparent),
                ),
              ),

              // ── Scrollable Content ──────────────────────────────────────
              SafeArea(
                child: RefreshIndicator(
                  color: AppColors.primary,
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
                                    child: CircleAvatar(
                                      radius: 24,
                                      backgroundColor: Colors.white24,
                                      backgroundImage:
                                          (user?.profileImageUrl != null &&
                                              user!.profileImageUrl.isNotEmpty)
                                          ? NetworkImage(user.profileImageUrl)
                                          : null,
                                      child:
                                          (user?.profileImageUrl == null ||
                                              user!.profileImageUrl.isEmpty)
                                          ? const Icon(
                                              Icons.person_outline_rounded,
                                              color: Color(0xFF38106A),
                                              size: 28,
                                            )
                                          : null,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Hello, $greetingName',
                                    style: AppTextStyles.heading2.copyWith(
                                      color: const Color(0xFF38106A),
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Color(
                                        0xFF280A54,
                                      ).withValues(alpha: 0.05),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.notifications_outlined,
                                    color: Color(0xFF38106A),
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
                              ? _buildGuestWelcomeCard(AppColors.primary)
                              : _buildProgressHeaderCard(
                                  ongoingList,
                                  AppColors.primary,
                                ),
                        ),
                        const SizedBox(height: 32),

                        // ── 3. Categories ───────────────────────────────
                        CategorySectionWidget(
                          lectureService: _lectureService,
                          orangeAction: const Color(0xFF8841FF),
                          categoriesStream: _categoriesStream,
                          lecturesStream: _latestLecturesStream,
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
                                  color: const Color(0xFF280A54),
                                ),
                              ),
                              GestureDetector(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const AllCoursesScreen(),
                                  ),
                                ),
                                child: Text(
                                  'See All >',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: const Color(0xFF8841FF),
                                    fontWeight: FontWeight.bold,
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
                                return const Center(
                                  child: Text("No courses available"),
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
                                    const Color(0xFF8841FF),
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
                                  color: const Color(0xFF280A54),
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
                                  foregroundColor: const Color(0xFF38106A),
                                ),
                                child: Text(
                                  'See All',
                                  style: AppTextStyles.label.copyWith(
                                    color: const Color(0xFF38106A),
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
                              padding: EdgeInsets.symmetric(horizontal: 24),
                              child: Text(
                                "No ongoing courses yet.",
                                style: TextStyle(
                                  color: Color(
                                    0xFF5E27B6,
                                  ).withValues(alpha: 0.7),
                                ),
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
                                        orangeAction: const Color(0xFF8841FF),
                                        lectureService: _lectureService,
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
                                  color: Colors.white.withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(32),
                                  border: Border.all(
                                    color: const Color(0xFFE5D9F2),
                                    width: 1.5,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(
                                          alpha: 0.4,
                                        ),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.lock_outline_rounded,
                                        color: Color(0xFF38106A),
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
                                                  color: const Color(
                                                    0xFF280A54,
                                                  ),
                                                ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Save your courses and pick up where you left off.',
                                            style: AppTextStyles.caption
                                                .copyWith(
                                                  color: const Color(
                                                    0xFF38106A,
                                                  ),
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

  Widget _buildGuestWelcomeCard(Color accentColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(40),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Welcome to JAAN!",
                style: AppTextStyles.heading2.copyWith(
                  fontSize: 22,
                  color: const Color(0xFF280A54),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            "Sign in to access your modules and track progress.",
            style: AppTextStyles.bodyMedium.copyWith(
              color: const Color(0xFF38106A),
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
            ),
            child: Row(
              children: [
                Text(
                  "Login / Register",
                  style: AppTextStyles.label.copyWith(
                    color: const Color(0xFF5E27B6),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.arrow_forward_rounded,
                  size: 18,
                  color: Color(0xFF5E27B6),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressHeaderCard(
    List<ProgressModel> progressList,
    Color accentColor,
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
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(40),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.4),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 30,
                offset: const Offset(0, 15),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Learned today",
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF38106A),
                    ),
                  ),
                  InkWell(
                    onTap: () {},
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE5D9F2)),
                      ),
                      child: Text(
                        "My courses",
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: const Color(0xFF38106A),
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    "${percentInt}%",
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF280A54),
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Done",
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF38106A).withValues(alpha: 0.7),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: overall,
                  minHeight: 8,
                  backgroundColor: Colors.white.withValues(alpha: 0.4),
                  color: const Color(0xFF5E27B6),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLectureCard(
    BuildContext context,
    LectureModel l,
    bool isEnrolled,
    dynamic user,
    Color accentColor,
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
          color: Colors.white.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: const Color(0xFFE5D9F2), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 30,
              offset: const Offset(0, 15),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Hero(
              tag: 'lecture_${l.id}',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  color: const Color(0xFFE5D9F2),
                  height: 130,
                  width: double.infinity,
                  child: l.thumbnailUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: l.thumbnailUrl,
                          fit: BoxFit.cover,
                        )
                      : const Icon(
                          Icons.image_outlined,
                          color: Color(0xFF8841FF),
                          size: 40,
                        ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF280A54),
                letterSpacing: -0.3,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Tags
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5D9F2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    l.categoryName,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF5E27B6),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  l.isPaid ? '\$${l.price}' : 'Free',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Color(0xFF38106A),
                  ),
                ),
              ],
            ),
            const Spacer(),
            // Avatars + Enroll
            Row(
              children: [
                // Avatars
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
                        : [
                            _buildPlaceholderAvatar(0, const Color(0xFFFFB020)),
                            _buildPlaceholderAvatar(
                              14,
                              const Color(0xFF00D289),
                            ),
                            _buildPlaceholderAvatar(
                              28,
                              const Color(0xFFFF3B30),
                            ),
                          ],
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8841FF),
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

  Widget _buildPlaceholderAvatar(double left, Color color) {
    return Positioned(
      left: left,
      child: CircleAvatar(
        radius: 12,
        backgroundColor: Colors.white,
        child: CircleAvatar(radius: 10, backgroundColor: color),
      ),
    );
  }

  Widget _buildOngoingCard(
    BuildContext context,
    LectureModel l,
    ProgressModel p,
    Color accentColor,
  ) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => LectureDetailsScreen(lecture: l)),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: _cardShadow,
        ),
        child: Row(
          children: [
            // Image
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: 100,
                height: 70,
                color: Colors.grey[200],
                child: l.thumbnailUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: l.thumbnailUrl,
                        fit: BoxFit.cover,
                      )
                    : const Icon(Icons.image),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        "${l.lessons.length} Lessons",
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text("|", style: TextStyle(color: Colors.grey)),
                      const SizedBox(width: 4),
                      Text(
                        "${l.resources.length} PDFs",
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
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
                          color: const Color(0xFFE0E7FF),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: p.completionPercentage.clamp(0.01, 1.0),
                        child: Container(
                          height: 6,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
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
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: accentColor,
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

class CategorySectionWidget extends StatefulWidget {
  final LectureService lectureService;
  final Color orangeAction;
  final Stream<List<CategoryModel>>? categoriesStream;
  final Stream<List<LectureModel>>? lecturesStream;

  const CategorySectionWidget({
    Key? key,
    required this.lectureService,
    required this.orangeAction,
    this.categoriesStream,
    this.lecturesStream,
  }) : super(key: key);

  @override
  State<CategorySectionWidget> createState() => _CategorySectionWidgetState();
}

class _CategorySectionWidgetState extends State<CategorySectionWidget> {
  String _selectedCategoryId = 'all';
  Stream<List<LectureModel>>? _latestLecturesStream;
  Stream<List<CategoryModel>>? _categoriesStream;

  static final _cardShadow = [
    BoxShadow(
      color: AppColors.primary.withValues(alpha: 0.08),
      blurRadius: 24,
      offset: const Offset(0, 12),
    ),
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.03),
      blurRadius: 8,
      offset: const Offset(0, 4),
    ),
  ];

  @override
  Widget build(BuildContext context) {
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
                  color: const Color(0xFF280A54),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CategoriesPage()),
                ),
                child: const Text(
                  'See All',
                  style: TextStyle(
                    color: Color(0xFF38106A),
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
                              color: Colors.grey[300],
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
                            'All',
                            _selectedCategoryId == 'all',
                            () => setState(() => _selectedCategoryId = 'all'),
                          ),
                          const SizedBox(width: 8),
                          ...categories.map(
                            (c) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: _buildCategoryChip(
                                c.name,
                                _selectedCategoryId == c.id,
                                () =>
                                    setState(() => _selectedCategoryId = c.id),
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
                          final c = categories[index];
                          if (_selectedCategoryId != 'all' &&
                              c.id != _selectedCategoryId) {
                            return const SizedBox.shrink();
                          }

                          final totals = totalsByCategory[c.id];
                          final lectureCount =
                              totals?['lectureCount'] ?? c.lectureCount;
                          final lessonCount = totals?['lessonCount'] ?? 0;
                          final resourceCount = totals?['resourceCount'] ?? 0;

                          return _buildCategoryStatCard(
                            context,
                            c,
                            widget.orangeAction,
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

  Widget _buildCategoryChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF5E27B6)
              : Colors.white.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF5E27B6)
                : Colors.white.withValues(alpha: 0.5),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF280A54),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryStatCard(
    BuildContext context,
    CategoryModel c,
    Color accentColor, {
    required int lectureCount,
    required int lessonCount,
    required int resourceCount,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                CategoryLecturesScreen(categoryId: c.id, categoryName: c.name),
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
              color: Colors.white.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(36),
              border: Border.all(color: const Color(0xFFE5D9F2), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  c.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF280A54),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$lectureCount',
                            style: const TextStyle(
                              fontSize: 44,
                              height: 0.95,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF38106A),
                            ),
                          ),
                          const Text(
                            'Courses',
                            style: TextStyle(
                              fontSize: 15,
                              color: Color(0xFF5E27B6),
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
                          Icons.smart_display_outlined,
                          '$lessonCount Lessons',
                        ),
                        const SizedBox(height: 8),
                        _buildCategoryMetric(
                          Icons.description_outlined,
                          '$resourceCount Resources',
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
                color: const Color(0xFF8841FF),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.8),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF8841FF).withValues(alpha: 0.4),
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

  Widget _buildCategoryMetric(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF5E27B6)),
        const SizedBox(width: 7),
        Text(
          text,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF5E27B6),
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

  const CachedOngoingCard({
    Key? key,
    required this.progressModel,
    required this.orangeAction,
    required this.lectureService,
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

  static final _cardShadow = [
    BoxShadow(
      color: AppColors.primary.withValues(alpha: 0.08),
      blurRadius: 24,
      offset: const Offset(0, 12),
    ),
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.03),
      blurRadius: 8,
      offset: const Offset(0, 4),
    ),
  ];

  @override
  Widget build(BuildContext context) {
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
              color: Colors.white.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(40),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.4),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: 100,
                    height: 70,
                    color: Colors.grey[200],
                    child: l.thumbnailUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: l.thumbnailUrl,
                            fit: BoxFit.cover,
                          )
                        : const Icon(Icons.image),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF280A54),
                        ),
                        maxLines: 1,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            "${l.lessons.length} Lessons",
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF5E27B6),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            "|",
                            style: TextStyle(color: Color(0xFF5E27B6)),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "${l.resources.length} PDFs",
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF5E27B6),
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
                              color: const Color(0xFFE5D9F2),
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
                                color: AppColors.primary,
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
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF280A54),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE5D9F2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: Color(0xFF38106A),
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
