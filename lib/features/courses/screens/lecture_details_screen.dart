import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:lms/core/constants/app_colors.dart';
import 'package:lms/core/models/lecture_model.dart';
import 'package:lms/core/models/cart_item_model.dart';
import 'package:lms/core/providers/cart_provider.dart';
import 'package:lms/core/services/course_access_service.dart';
import 'package:lms/core/services/review_service.dart';
import 'package:lms/core/models/review_model.dart';
import 'package:lms/core/services/lecture_service.dart';
import 'package:lms/core/services/progress_service.dart';
import 'package:lms/core/services/task_service.dart';
import 'package:lms/core/models/progress_model.dart';
import 'package:lms/core/models/task_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:lms/features/auth/providers/auth_provider.dart';
import 'package:lms/features/auth/screens/login_screen.dart';
import 'package:lms/core/providers/theme_provider.dart';

// ── Theme-aware color helper ─────────────────────────────────────────────────
class _LectureColors {
  final bool isDark;
  _LectureColors(this.isDark);

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

class LectureDetailsScreen extends StatefulWidget {
  final LectureModel lecture;
  final int initialTabIndex;

  const LectureDetailsScreen({
    super.key,
    required this.lecture,
    this.initialTabIndex = 0,
  });

  @override
  State<LectureDetailsScreen> createState() => _LectureDetailsScreenState();
}

class _LectureDetailsScreenState extends State<LectureDetailsScreen>
    with SingleTickerProviderStateMixin {
  final CourseAccessService _accessService = CourseAccessService();
  final ProgressService _progressService = ProgressService();
  final LectureService _lectureService = LectureService();
  final ReviewService _reviewService = ReviewService();
  final TaskService _taskService = TaskService();

  late TabController _tabController;
  bool _isLoadingAccess = true;
  bool _hasAccess = false;
  bool _isEnrollLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 4,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
    _checkAccess();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _checkAccess() async {
    final user = context.read<AuthProvider>().userModel;
    if (user == null) {
      setState(() => _isLoadingAccess = false);
      return;
    }

    if (user.role.toLowerCase() != 'student') {
      setState(() {
        _hasAccess = true;
        _isLoadingAccess = false;
      });
      return;
    }

    try {
      final access = await _accessService.hasLectureAccess(
        user.uid,
        widget.lecture,
      );
      if (mounted) {
        setState(() {
          _hasAccess = access;
          _isLoadingAccess = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingAccess = false);
    }
  }

  Future<void> _launchUrlAndMarkComplete(
    String url,
    String itemId,
    String userId,
  ) async {
    String sanitizedUrl = url;
    if (!sanitizedUrl.startsWith('http://') &&
        !sanitizedUrl.startsWith('https://')) {
      sanitizedUrl = 'https://$sanitizedUrl';
    }

    if (await canLaunchUrl(Uri.parse(sanitizedUrl))) {
      await launchUrl(
        Uri.parse(sanitizedUrl),
        mode: LaunchMode.externalApplication,
      );
      if (_hasAccess) {
        await _progressService.markLessonCompleted(
          userId,
          widget.lecture,
          itemId,
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Could not launch URL')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = widget.lecture;
    final userId = context.read<AuthProvider>().userModel?.uid;
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final c = _LectureColors(isDark);

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

          NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverAppBar(
                  expandedHeight: 250,
                  pinned: true,
                  backgroundColor: Colors.transparent,
                  iconTheme: IconThemeData(
                    color: c.textPrimary,
                  ), // Back button color adapt
                  flexibleSpace: FlexibleSpaceBar(
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (l.thumbnailUrl.isNotEmpty)
                          Image.network(l.thumbnailUrl, fit: BoxFit.cover)
                        else
                          Container(color: c.bgColor2),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                c.bgColor1.withValues(
                                  alpha: 0.9,
                                ), // Fade to theme color
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l.title,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: c.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 20,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${l.averageRating} (${l.reviewCount} reviews)',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: c.textPrimary,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Text(
                              l.durationString,
                              style: TextStyle(
                                color: c.accentBright,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Text(
                              '${l.lessons.length} Lessons',
                              style: TextStyle(
                                color: c.accentBright,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (!_hasAccess)
                          Consumer<CartProvider>(
                            builder: (context, cartProvider, child) {
                              final inCart = cartProvider.isInCart(l.id);
                              return SizedBox(
                                width: double.infinity,
                                child: l.isPaid
                                    ? (inCart
                                          ? OutlinedButton(
                                              onPressed: () {},
                                              style: OutlinedButton.styleFrom(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 16,
                                                    ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(16),
                                                ),
                                                side: BorderSide(
                                                  color: c.accentBright,
                                                  width: 2,
                                                ),
                                              ),
                                              child: Text(
                                                'Added to Cart',
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  color: c.accentBright,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            )
                                          : ElevatedButton(
                                              onPressed: () {
                                                final item = CartItemModel(
                                                  itemId: l.id,
                                                  title: l.title,
                                                  thumbnailUrl: l.thumbnailUrl,
                                                  price: l.price,
                                                  itemType: 'lecture',
                                                );
                                                cartProvider.addToCart(item);
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: const Text(
                                                      'Added to Cart',
                                                    ),
                                                    backgroundColor:
                                                        AppColors.success,
                                                    behavior: SnackBarBehavior
                                                        .floating,
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            10,
                                                          ),
                                                    ),
                                                    margin:
                                                        const EdgeInsets.all(
                                                          16,
                                                        ),
                                                  ),
                                                );
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    c.accentPrimary,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 16,
                                                    ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(16),
                                                ),
                                                elevation: 0,
                                              ),
                                              child: Text(
                                                'Add to Cart - \$${l.price.toStringAsFixed(2)}',
                                                style: const TextStyle(
                                                  fontSize: 18,
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ))
                                    : ElevatedButton(
                                        onPressed: _isEnrollLoading
                                            ? null
                                            : () async {
                                                final authProvider = context
                                                    .read<AuthProvider>();
                                                if (!authProvider
                                                    .isAuthenticated) {
                                                  // Show Login Dialog
                                                  showDialog(
                                                    context: context,
                                                    builder: (ctx) => AlertDialog(
                                                      backgroundColor: c.cardBg,
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              20,
                                                            ),
                                                        side: BorderSide(
                                                          color: c.cardBorder,
                                                        ),
                                                      ),
                                                      title: Text(
                                                        'Login Required',
                                                        style: TextStyle(
                                                          color: c.textPrimary,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                      content: Text(
                                                        'You need to login to enroll in this course.',
                                                        style: TextStyle(
                                                          color:
                                                              c.textSecondary,
                                                        ),
                                                      ),
                                                      actions: [
                                                        TextButton(
                                                          onPressed: () =>
                                                              Navigator.pop(
                                                                ctx,
                                                              ),
                                                          child: Text(
                                                            'Cancel',
                                                            style: TextStyle(
                                                              color: c
                                                                  .textSecondary,
                                                            ),
                                                          ),
                                                        ),
                                                        ElevatedButton(
                                                          onPressed: () {
                                                            Navigator.pop(ctx);
                                                            Navigator.push(
                                                              context,
                                                              MaterialPageRoute(
                                                                builder: (_) =>
                                                                    const LoginScreen(),
                                                              ),
                                                            );
                                                          },
                                                          style: ElevatedButton.styleFrom(
                                                            backgroundColor:
                                                                c.accentPrimary,
                                                            shape: RoundedRectangleBorder(
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                    12,
                                                                  ),
                                                            ),
                                                          ),
                                                          child: const Text(
                                                            'Login',
                                                            style: TextStyle(
                                                              color:
                                                                  Colors.white,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                  return;
                                                }
                                                setState(
                                                  () => _isEnrollLoading = true,
                                                );
                                                try {
                                                  await _lectureService
                                                      .enrollStudent(
                                                        authProvider
                                                            .userModel!
                                                            .uid,
                                                        l.id,
                                                      );
                                                  if (mounted) {
                                                    setState(() {
                                                      _hasAccess = true;
                                                      _isEnrollLoading = false;
                                                    });
                                                    ScaffoldMessenger.of(
                                                      context,
                                                    ).showSnackBar(
                                                      SnackBar(
                                                        content: const Text(
                                                          'Enrolled successfully!',
                                                        ),
                                                        backgroundColor:
                                                            AppColors.success,
                                                        behavior:
                                                            SnackBarBehavior
                                                                .floating,
                                                        shape: RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                10,
                                                              ),
                                                        ),
                                                        margin:
                                                            const EdgeInsets.all(
                                                              16,
                                                            ),
                                                      ),
                                                    );
                                                  }
                                                } catch (e) {
                                                  if (mounted) {
                                                    setState(
                                                      () => _isEnrollLoading =
                                                          false,
                                                    );
                                                    ScaffoldMessenger.of(
                                                      context,
                                                    ).showSnackBar(
                                                      SnackBar(
                                                        content: const Text(
                                                          'Enrollment failed',
                                                        ),
                                                        backgroundColor:
                                                            AppColors.error,
                                                        behavior:
                                                            SnackBarBehavior
                                                                .floating,
                                                        shape: RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                10,
                                                              ),
                                                        ),
                                                        margin:
                                                            const EdgeInsets.all(
                                                              16,
                                                            ),
                                                      ),
                                                    );
                                                  }
                                                }
                                              },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: c.accentPrimary,
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 16,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                          ),
                                          elevation: 0,
                                        ),
                                        child: _isEnrollLoading
                                            ? const SizedBox(
                                                height: 24,
                                                width: 24,
                                                child:
                                                    CircularProgressIndicator(
                                                      color: Colors.white,
                                                      strokeWidth: 2,
                                                    ),
                                              )
                                            : const Text(
                                                'Enroll Now - Free',
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                      ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                ),
                SliverPersistentHeader(
                  delegate: _SliverAppBarDelegate(
                    TabBar(
                      controller: _tabController,
                      labelColor: c.accentBright,
                      unselectedLabelColor: c.textSecondary,
                      indicatorColor: c.accentBright,
                      dividerColor:
                          Colors.transparent, // Disable standard bottom divider
                      tabs: const [
                        Tab(text: 'Lessons'),
                        Tab(text: 'Resources'),
                        Tab(text: 'Tasks'),
                        Tab(text: 'Reviews'),
                      ],
                    ),
                    c,
                  ),
                  pinned: true,
                ),
              ];
            },
            body: TabBarView(
              controller: _tabController,
              children: [
                _buildLessonsList(userId, c),
                _buildResourcesList(userId, c),
                _buildTasksList(userId, c),
                _buildReviewsList(c),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLessonsList(String? userId, _LectureColors c) {
    return StreamBuilder<ProgressModel?>(
      stream: (userId != null)
          ? _progressService.getLectureProgress(userId, widget.lecture.id)
          : Stream.value(null),
      builder: (context, snapshot) {
        final progress = snapshot.data;
        final completedSet = Set<String>.from(progress?.completedLessons ?? []);

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: widget.lecture.lessons.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final lessonUrl = widget.lecture.lessons[index];
            final lessonNumber = (index + 1).toString().padLeft(2, '0');
            final itemId = 'lesson_${index}_$lessonUrl';
            final isCompleted = completedSet.contains(itemId);

            return Container(
              decoration: BoxDecoration(
                color: c.cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: c.cardBorder, width: 1.5),
              ),
              child: ListTile(
                leading: Text(
                  lessonNumber,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: c.accentPale,
                  ),
                ),
                title: Text(
                  'Lesson ${index + 1}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: c.textPrimary,
                  ),
                ),
                subtitle: Text(
                  'Video Content',
                  style: TextStyle(color: c.textSecondary),
                ),
                trailing: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, animation) =>
                      ScaleTransition(scale: animation, child: child),
                  child: !_hasAccess
                      ? Icon(
                          Icons.lock,
                          key: const ValueKey('locked'),
                          color: c.textSecondary,
                          size: 28,
                        )
                      : (isCompleted
                            ? const Icon(
                                Icons.check_circle,
                                key: ValueKey('done'),
                                color: Colors.green,
                                size: 32,
                              )
                            : Container(
                                key: const ValueKey('download'),
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: c.accentPrimary.withValues(
                                    alpha: 0.15,
                                  ),
                                ),
                                child: Icon(
                                  Icons.play_arrow_rounded,
                                  color: c.accentBright,
                                  size: 24,
                                ),
                              )),
                ),
                onTap: () {
                  if (!_hasAccess) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text(
                          'Please enroll to access this content.',
                        ),
                        backgroundColor: AppColors.error,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        margin: const EdgeInsets.all(16),
                      ),
                    );
                    return;
                  }
                  if (userId != null) {
                    _launchUrlAndMarkComplete(lessonUrl, itemId, userId);
                  }
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildResourcesList(String? userId, _LectureColors c) {
    return StreamBuilder<ProgressModel?>(
      stream: (userId != null)
          ? _progressService.getLectureProgress(userId, widget.lecture.id)
          : Stream.value(null),
      builder: (context, snapshot) {
        final progress = snapshot.data;
        final completedSet = Set<String>.from(progress?.completedLessons ?? []);

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: widget.lecture.resources.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final resUrl = widget.lecture.resources[index];
            final itemId = 'resource_${index}_$resUrl';
            final isCompleted = completedSet.contains(itemId);

            return Container(
              decoration: BoxDecoration(
                color: c.cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: c.cardBorder, width: 1.5),
              ),
              child: ListTile(
                leading: const Icon(
                  Icons.folder_shared_rounded,
                  color: Colors.amber,
                  size: 32,
                ),
                title: Text(
                  'Resource ${index + 1}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: c.textPrimary,
                  ),
                ),
                subtitle: Text(
                  'Downloadable File',
                  style: TextStyle(color: c.textSecondary),
                ),
                trailing: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, animation) =>
                      ScaleTransition(scale: animation, child: child),
                  child: !_hasAccess
                      ? Icon(
                          Icons.lock,
                          key: const ValueKey('locked'),
                          color: c.textSecondary,
                          size: 28,
                        )
                      : (isCompleted
                            ? const Icon(
                                Icons.check_circle,
                                key: ValueKey('done'),
                                color: Colors.green,
                                size: 32,
                              )
                            : Container(
                                key: const ValueKey('download'),
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: c.accentPrimary.withValues(
                                    alpha: 0.15,
                                  ),
                                ),
                                child: Icon(
                                  Icons.download_rounded,
                                  color: c.accentBright,
                                  size: 24,
                                ),
                              )),
                ),
                onTap: () {
                  if (!_hasAccess) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text(
                          'Please enroll to access this content.',
                        ),
                        backgroundColor: AppColors.error,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        margin: const EdgeInsets.all(16),
                      ),
                    );
                    return;
                  }
                  if (userId != null) {
                    _launchUrlAndMarkComplete(resUrl, itemId, userId);
                  }
                },
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _launchTaskLink(String url) async {
    String sanitizedUrl = url.trim();
    if (!sanitizedUrl.startsWith('http://') &&
        !sanitizedUrl.startsWith('https://')) {
      sanitizedUrl = 'https://$sanitizedUrl';
    }
    final uri = Uri.tryParse(sanitizedUrl);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Could not open link'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  Widget _buildTasksList(String? userId, _LectureColors c) {
    return StreamBuilder<List<TaskModel>>(
      stream: _hasAccess
          ? _taskService.streamLectureTasks(widget.lecture.id)
          : Stream.value([]),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: c.accentPrimary),
                const SizedBox(height: 16),
                Text(
                  'Loading tasks...',
                  style: TextStyle(color: c.textSecondary),
                ),
              ],
            ),
          );
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text(
                'Failed to load tasks. Please try again.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.error),
              ),
            ),
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Text(
                'No tasks for this course.',
                style: TextStyle(fontSize: 16, color: c.textSecondary),
              ),
            ),
          );
        }

        final tasks = snapshot.data!;
        return ListView.separated(
          shrinkWrap: true,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          itemCount: tasks.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            return _LectureDetailsTaskItem(
              task: tasks[index],
              lectureId: widget.lecture.id,
              userId: userId,
              hasAccess: _hasAccess,
              onLaunchLink: () => _launchTaskLink(tasks[index].pdfLink),
              c: c,
            );
          },
        );
      },
    );
  }

  Widget _buildReviewsList(_LectureColors c) {
    final userId = context.read<AuthProvider>().userModel?.uid;

    return CustomScrollView(
      slivers: [
        if (userId != null)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _showWriteReviewDialog(userId, c),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: c.accentPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Write a Review',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        StreamBuilder<List<ReviewModel>>(
          stream: _reviewService.getReviewsStream(widget.lecture.id),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(color: c.accentPrimary),
                ),
              );
            }
            if (snapshot.hasError) {
              return SliverFillRemaining(
                child: Center(
                  child: Text(
                    'Error loading reviews',
                    style: TextStyle(color: AppColors.error),
                  ),
                ),
              );
            }
            final reviews = snapshot.data ?? [];
            if (reviews.isEmpty) {
              return SliverFillRemaining(
                child: Center(
                  child: Text(
                    'No reviews yet.',
                    style: TextStyle(color: c.textSecondary),
                  ),
                ),
              );
            }

            return SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final review = reviews[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16.0),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: c.cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: c.cardBorder, width: 1.5),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: c.accentPrimary,
                          backgroundImage: review.userAvatar.isNotEmpty
                              ? NetworkImage(review.userAvatar)
                              : null,
                          child: review.userAvatar.isEmpty
                              ? Text(
                                  review.userName.isNotEmpty
                                      ? review.userName[0].toUpperCase()
                                      : 'U',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    review.userName,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: c.textPrimary,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Text(
                                        review.rating.toStringAsFixed(1),
                                        style: TextStyle(
                                          color: c.textSecondary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      ...List.generate(5, (starIndex) {
                                        return Icon(
                                          starIndex < review.rating
                                              ? Icons.star_rounded
                                              : Icons.star_border_rounded,
                                          color: Colors.amber,
                                          size: 16,
                                        );
                                      }),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                review.comment,
                                style: TextStyle(
                                  color: c.textSecondary,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }, childCount: reviews.length),
              ),
            );
          },
        ),
      ],
    );
  }

  void _showWriteReviewDialog(String userId, _LectureColors c) {
    double rating = 5.0;
    final commentController = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: c.cardBg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: c.cardBorder, width: 1.5),
              ),
              title: Text(
                'Write a Review',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: c.textPrimary,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                        onPressed: () => setState(() => rating = index + 1.0),
                        icon: Icon(
                          index < rating
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          color: Colors.amber,
                          size: 36,
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: commentController,
                    maxLines: 4,
                    style: TextStyle(color: c.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Share your experience...',
                      hintStyle: TextStyle(color: c.textSecondary),
                      filled: true,
                      fillColor: c.isDark
                          ? Colors.black.withValues(alpha: 0.2)
                          : Colors.white.withValues(alpha: 0.5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: c.cardBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: c.cardBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: c.accentBright, width: 2),
                      ),
                      contentPadding: const EdgeInsets.all(16),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: c.textSecondary),
                  ),
                ),
                ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          if (commentController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Please write a comment'),
                                backgroundColor: AppColors.error,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                margin: const EdgeInsets.all(16),
                              ),
                            );
                            return;
                          }
                          setState(() => isSubmitting = true);

                          final user = context.read<AuthProvider>().userModel!;
                          final review = ReviewModel(
                            id: '',
                            lectureId: widget.lecture.id,
                            userId: userId,
                            userName: user.name,
                            userAvatar: user.profileImageUrl ?? '',
                            rating: rating,
                            comment: commentController.text.trim(),
                            createdAt: DateTime.now(),
                          );

                          try {
                            await _reviewService.addReview(
                              widget.lecture.id,
                              review,
                            );
                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text(
                                    'Review submitted successfully!',
                                  ),
                                  backgroundColor: AppColors.success,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  margin: const EdgeInsets.all(16),
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              setState(() => isSubmitting = false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Failed: $e'),
                                  backgroundColor: AppColors.error,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  margin: const EdgeInsets.all(16),
                                ),
                              );
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: c.accentPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Submit',
                          style: TextStyle(color: Colors.white),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;
  final _LectureColors c;
  _SliverAppBarDelegate(this._tabBar, this.c);

  @override
  double get minExtent => _tabBar.preferredSize.height + 8; // Slight padding
  @override
  double get maxExtent => _tabBar.preferredSize.height + 8;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          color: c.cardBg,
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: _tabBar,
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}

class _LectureDetailsTaskItem extends StatefulWidget {
  final TaskModel task;
  final String lectureId;
  final String? userId;
  final bool hasAccess;
  final VoidCallback onLaunchLink;
  final _LectureColors c;

  const _LectureDetailsTaskItem({
    required this.task,
    required this.lectureId,
    required this.userId,
    required this.hasAccess,
    required this.onLaunchLink,
    required this.c,
  });

  @override
  State<_LectureDetailsTaskItem> createState() =>
      _LectureDetailsTaskItemState();
}

class _LectureDetailsTaskItemState extends State<_LectureDetailsTaskItem> {
  Future<QuerySnapshot?>? _submissionFuture;

  @override
  void initState() {
    super.initState();
    _fetchSubmission();
  }

  void _fetchSubmission() {
    if (widget.userId != null) {
      _submissionFuture = FirebaseFirestore.instance
          .collection('task_submissions')
          .where('taskId', isEqualTo: widget.task.id)
          .where('studentId', isEqualTo: widget.userId)
          .limit(1)
          .get();
    } else {
      _submissionFuture = Future.value(null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    bool isOverdue = DateTime.now().isAfter(task.deadline);
    final c = widget.c;

    return FutureBuilder<QuerySnapshot?>(
      future: _submissionFuture,
      builder: (context, subSnapshot) {
        final submissionDoc = subSnapshot.data?.docs.isNotEmpty == true
            ? subSnapshot.data!.docs.first
            : null;
        final isSubmitted = submissionDoc != null;

        return ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              decoration: BoxDecoration(
                color: c.cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: c.cardBorder, width: 1.5),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      task.title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: c.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: 16,
                          color: isOverdue && !isSubmitted
                              ? AppColors.error
                              : c.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Due: ${DateFormat('MMM dd, yyyy HH:mm').format(task.deadline)}',
                          style: TextStyle(
                            color: isOverdue && !isSubmitted
                                ? AppColors.error
                                : c.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: task.pdfLink.trim().isEmpty
                                ? null
                                : widget.onLaunchLink,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: c.accentPrimary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            icon: const Icon(Icons.download_rounded, size: 20),
                            label: const Text('View Assignment'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (isSubmitted)
                          Row(
                            children: [
                              const Icon(
                                Icons.check_circle_rounded,
                                color: AppColors.success,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Submitted',
                                style: TextStyle(
                                  color: AppColors.success,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                    if (!isSubmitted && widget.userId != null) ...[
                      const SizedBox(height: 16),
                      Divider(color: c.cardBorder),
                      const SizedBox(height: 16),
                      _LectureTaskSubmitField(
                        taskId: task.id,
                        lectureId: widget.lectureId,
                        studentId: widget.userId!,
                        c: c,
                        onSubmitted: () {
                          _fetchSubmission();
                          setState(() {});
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _LectureTaskSubmitField extends StatefulWidget {
  final String taskId;
  final String lectureId;
  final String studentId;
  final VoidCallback onSubmitted;
  final _LectureColors c;

  const _LectureTaskSubmitField({
    required this.taskId,
    required this.lectureId,
    required this.studentId,
    required this.onSubmitted,
    required this.c,
  });

  @override
  State<_LectureTaskSubmitField> createState() =>
      _LectureTaskSubmitFieldState();
}

class _LectureTaskSubmitFieldState extends State<_LectureTaskSubmitField> {
  final TextEditingController _controller = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final link = _controller.text.trim();
    if (link.isEmpty) return;

    setState(() => _isSubmitting = true);
    try {
      await FirebaseFirestore.instance.collection('task_submissions').add({
        'taskId': widget.taskId,
        'studentId': widget.studentId,
        'lectureId': widget.lectureId,
        'googleDriveLink': link,
        'submittedAt': FieldValue.serverTimestamp(),
        'isMarkedRead': true,
      });
      _controller.clear();
      widget.onSubmitted();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Submission failed: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.c;
    return SizedBox(
      width: double.infinity,
      child: TextField(
        controller: _controller,
        enabled: !_isSubmitting,
        onSubmitted: (_) => _submit(),
        style: TextStyle(color: c.textPrimary, fontSize: 14),
        decoration: InputDecoration(
          labelText: 'Paste Google Drive Link',
          labelStyle: TextStyle(color: c.textSecondary),
          hintText: 'Press Enter to submit',
          hintStyle: TextStyle(color: c.textSecondary),
          filled: true,
          fillColor: c.isDark
              ? Colors.black.withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.5),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: c.cardBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: c.cardBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: c.accentBright, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          suffixIcon: _isSubmitting
              ? Padding(
                  padding: const EdgeInsets.all(12),
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: c.accentBright,
                    ),
                  ),
                )
              : IconButton(
                  icon: Icon(Icons.send_rounded, color: c.accentBright),
                  onPressed: _submit,
                ),
        ),
      ),
    );
  }
}
