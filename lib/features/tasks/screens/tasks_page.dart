import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:lms/core/constants/app_colors.dart';
import 'package:lms/core/constants/app_text_styles.dart';
import 'package:lms/core/models/task_model.dart';
import 'package:lms/core/services/task_service.dart';
import 'package:lms/core/services/lecture_service.dart';
import 'package:lms/features/courses/screens/lecture_details_screen.dart';
import 'package:lms/features/auth/providers/auth_provider.dart';
import 'package:lms/core/providers/navigation_provider.dart';
import 'package:lms/core/providers/theme_provider.dart';

// ── Theme-aware color helper ─────────────────────────────────────────────────
class _TasksColors {
  final bool isDark;
  _TasksColors(this.isDark);

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

class TasksPage extends StatefulWidget {
  const TasksPage({super.key});

  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  final TaskService _taskService = TaskService();
  Map<String, String> _lectureTitleMap = {};
  Future<Set<String>>? _accessibleIdsFuture;
  String? _lastUserId;
  int? _lastIndex;

  Widget _buildBackground(_TasksColors c) {
    return Stack(
      clipBehavior: Clip.none,
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
                  const Color(0xFFA855F7).withValues(alpha: c.orbOpacity * 0.6),
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
                  const Color(0xFF6D28D9).withValues(alpha: c.orbOpacity * 0.7),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().userModel;
    final navProvider = context.watch<NavigationProvider>();
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final c = _TasksColors(isDark);

    if (user != null && user.role.toLowerCase() == 'student') {
      if (navProvider.currentIndex == 2 && _lastIndex != 2) {
        _lastUserId = user.uid;
        _accessibleIdsFuture = _taskService.getAccessibleLectureIdsForStudent(
          user.uid,
        );
      }
    }
    _lastIndex = navProvider.currentIndex;

    if (user == null) {
      return Scaffold(
        backgroundColor: c.bgColor1,
        body: Stack(
          children: [
            _buildBackground(c),
            SafeArea(
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
                              icon: Icon(
                                Icons.arrow_back_ios_new,
                                color: c.textSecondary,
                                size: 20,
                              ),
                              padding: const EdgeInsets.only(
                                left: 8,
                                right: 12,
                              ),
                              constraints: const BoxConstraints(),
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
                              'Tasks',
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
                  Expanded(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: c.cardBg,
                            borderRadius: BorderRadius.circular(40),
                            border: Border.all(color: c.cardBorder, width: 1.5),
                            boxShadow: c.cardShadow,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: c.accentPrimary.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.lock_outline_rounded,
                                  color: c.accentPale,
                                  size: 56,
                                ),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                "Sign In Required",
                                style: AppTextStyles.heading2.copyWith(
                                  color: c.textPrimary,
                                  fontSize: 20,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Please log in to view your tasks.',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: c.textSecondary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
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

    if (user.role.toLowerCase() != 'student') {
      return _buildTeacherView(user.uid, c);
    }
    return _buildStudentView(user.uid, c);
  }

  Widget _buildTeacherView(String userId, _TasksColors c) {
    return Scaffold(
      backgroundColor: c.bgColor1,
      body: Stack(
        children: [
          _buildBackground(c),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                            icon: Icon(
                              Icons.arrow_back_ios_new,
                              color: c.textSecondary,
                              size: 20,
                            ),
                            padding: const EdgeInsets.only(left: 8, right: 12),
                            constraints: const BoxConstraints(),
                            onPressed: () {
                              try {
                                context.read<NavigationProvider>().setIndex(0);
                              } catch (e) {
                                Navigator.pop(context);
                              }
                            },
                          ),
                          Text(
                            'All Tasks',
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
                Expanded(
                  child: StreamBuilder<List<TaskModel>>(
                    stream: _taskService.streamAllTasks(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(
                          child: CircularProgressIndicator(
                            color: c.accentBright,
                          ),
                        );
                      }
                      if (snapshot.hasError)
                        return _buildErrorState(
                          c,
                          'Error loading tasks: ${snapshot.error}',
                        );
                      if (!snapshot.hasData || snapshot.data!.isEmpty)
                        return _buildEmptyState(c);

                      final tasks = snapshot.data!;
                      _fetchLectureTitlesIfNeeded(tasks);
                      return _buildTasksListView(
                        tasks,
                        userId,
                        isTeacher: true,
                        c: c,
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

  Widget _buildStudentView(String userId, _TasksColors c) {
    if (_lastUserId != userId) {
      _lastUserId = userId;
      _accessibleIdsFuture = _taskService.getAccessibleLectureIdsForStudent(
        userId,
      );
    }

    return Scaffold(
      backgroundColor: c.bgColor1,
      body: Stack(
        children: [
          _buildBackground(c),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                            icon: Icon(
                              Icons.arrow_back_ios_new,
                              color: c.textSecondary,
                              size: 20,
                            ),
                            padding: const EdgeInsets.only(left: 8, right: 12),
                            constraints: const BoxConstraints(),
                            onPressed: () {
                              try {
                                context.read<NavigationProvider>().setIndex(0);
                              } catch (e) {
                                Navigator.pop(context);
                              }
                            },
                          ),
                          Text(
                            'Tasks',
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
                Expanded(
                  child: RefreshIndicator(
                    color: c.accentBright,
                    onRefresh: () async {
                      setState(() {
                        _accessibleIdsFuture = _taskService
                            .getAccessibleLectureIdsForStudent(userId);
                        _lectureTitleMap = {};
                      });
                    },
                    child: FutureBuilder<Set<String>>(
                      future: _accessibleIdsFuture,
                      builder: (context, accessSnapshot) {
                        if (accessSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Center(
                            child: CircularProgressIndicator(
                              color: c.accentBright,
                            ),
                          );
                        }
                        if (accessSnapshot.hasError) {
                          return _buildErrorState(
                            c,
                            'Error loading enrolled courses.',
                            onRetry: () {
                              setState(
                                () => _accessibleIdsFuture = _taskService
                                    .getAccessibleLectureIdsForStudent(userId),
                              );
                            },
                          );
                        }

                        final accessibleLectureIds = accessSnapshot.data ?? {};
                        if (accessibleLectureIds.isEmpty) {
                          return _buildEmptyState(
                            c,
                            message:
                                'No enrolled courses found.\nEnroll in a course to see tasks.',
                          );
                        }

                        return StreamBuilder<List<TaskModel>>(
                          stream: _taskService.streamTasksForLectureIds(
                            accessibleLectureIds,
                          ),
                          builder: (context, taskSnapshot) {
                            if (taskSnapshot.connectionState ==
                                ConnectionState.waiting) {
                              return Center(
                                child: CircularProgressIndicator(
                                  color: c.accentBright,
                                ),
                              );
                            }
                            if (taskSnapshot.hasError) {
                              return _buildErrorState(
                                c,
                                'Error loading tasks.',
                                onRetry: () {
                                  setState(
                                    () => _accessibleIdsFuture = _taskService
                                        .getAccessibleLectureIdsForStudent(
                                          userId,
                                        ),
                                  );
                                },
                              );
                            }
                            if (!taskSnapshot.hasData ||
                                taskSnapshot.data!.isEmpty) {
                              return _buildEmptyState(c);
                            }

                            final tasks = taskSnapshot.data!;
                            _fetchLectureTitlesIfNeeded(tasks);
                            return _buildTasksListView(
                              tasks,
                              userId,
                              isTeacher: false,
                              c: c,
                            );
                          },
                        );
                      },
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

  Widget _buildTasksListView(
    List<TaskModel> tasks,
    String userId, {
    required bool isTeacher,
    required _TasksColors c,
  }) {
    final Map<String, List<TaskModel>> groupedTasks = {};
    for (final task in tasks) {
      groupedTasks.putIfAbsent(task.lectureId, () => []).add(task);
    }
    final lectureIds = groupedTasks.keys.toList();

    return ListView.separated(
      shrinkWrap: true,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: lectureIds.length,
      separatorBuilder: (_, __) => const SizedBox(height: 24),
      itemBuilder: (context, index) {
        final lectureId = lectureIds[index];
        final lectureTasks = groupedTasks[lectureId]!;
        final lectureName = _lectureTitleMap[lectureId] ?? 'Loading Course...';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 12, left: 4),
              child: Row(
                children: [
                  Icon(
                    Icons.play_lesson_rounded,
                    color: c.accentBright,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      lectureName,
                      style: AppTextStyles.heading3.copyWith(
                        fontSize: 18,
                        color: c.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: lectureTasks.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, taskIndex) {
                final task = lectureTasks[taskIndex];
                return _TaskListItemWidget(
                  task: task,
                  userId: userId,
                  isTeacher: isTeacher,
                  lectureName: lectureName,
                  c: c,
                  onLaunchLink: () => _launchLink(task.pdfLink),
                  onSubmitted: () => setState(() {}),
                );
              },
            ),
          ],
        );
      },
    );
  }

  void _fetchLectureTitlesIfNeeded(List<TaskModel> tasks) {
    final missing = <String>{};
    for (final task in tasks) {
      if (task.lectureId.isNotEmpty &&
          !_lectureTitleMap.containsKey(task.lectureId)) {
        missing.add(task.lectureId);
      }
    }
    if (missing.isNotEmpty) {
      _taskService.getLectureTitleMap(missing).then((titleMap) {
        if (mounted && titleMap.isNotEmpty)
          setState(() => _lectureTitleMap.addAll(titleMap));
      });
    }
  }

  Future<void> _launchLink(String url) async {
    String sanitizedUrl = url.trim();
    if (!sanitizedUrl.startsWith('http://') &&
        !sanitizedUrl.startsWith('https://'))
      sanitizedUrl = 'https://$sanitizedUrl';
    final uri = Uri.tryParse(sanitizedUrl);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not open link')));
    }
  }

  Widget _buildEmptyState(_TasksColors c, {String? message}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: c.cardBg,
            borderRadius: BorderRadius.circular(40),
            border: Border.all(color: c.cardBorder, width: 1.5),
            boxShadow: c.cardShadow,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: c.accentPrimary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.task_alt_rounded,
                  color: c.accentPale,
                  size: 56,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'No Tasks Yet!',
                style: AppTextStyles.heading2.copyWith(
                  color: c.textPrimary,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message ?? 'There are no active tasks to show.',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: c.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(
    _TasksColors c,
    String message, {
    VoidCallback? onRetry,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: c.cardBg,
            borderRadius: BorderRadius.circular(40),
            border: Border.all(color: c.cardBorder, width: 1.5),
            boxShadow: c.cardShadow,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.error_outline,
                  color: Colors.redAccent,
                  size: 56,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                message,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: c.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              if (onRetry != null) ...[
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: c.accentPrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TaskListItemWidget extends StatefulWidget {
  final TaskModel task;
  final String userId;
  final bool isTeacher;
  final String lectureName;
  final VoidCallback onLaunchLink;
  final VoidCallback onSubmitted;
  final _TasksColors c;

  const _TaskListItemWidget({
    required this.task,
    required this.userId,
    required this.isTeacher,
    required this.lectureName,
    required this.onLaunchLink,
    required this.onSubmitted,
    required this.c,
  });

  @override
  State<_TaskListItemWidget> createState() => _TaskListItemWidgetState();
}

class _TaskListItemWidgetState extends State<_TaskListItemWidget> {
  Future<QuerySnapshot?>? _submissionFuture;
  final LectureService _lectureService = LectureService();
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    _fetchSubmission();
  }

  void _fetchSubmission() {
    if (!widget.isTeacher && widget.userId.isNotEmpty) {
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
  void didUpdateWidget(covariant _TaskListItemWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.task.id != widget.task.id ||
        oldWidget.userId != widget.userId)
      _fetchSubmission();
  }

  Future<void> _navigateToLecture() async {
    if (_isNavigating) return;
    setState(() => _isNavigating = true);
    try {
      final lecture = await _lectureService.getLecture(widget.task.lectureId);
      if (lecture != null && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                LectureDetailsScreen(lecture: lecture, initialTabIndex: 2),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Course not found or unavailable.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isNavigating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    final isOverdue = DateTime.now().isAfter(task.deadline);
    final c = widget.c;

    return FutureBuilder<QuerySnapshot?>(
      future: _submissionFuture,
      builder: (context, subSnapshot) {
        final submissionDoc = subSnapshot.data?.docs.isNotEmpty == true
            ? subSnapshot.data!.docs.first
            : null;
        final isSubmitted = submissionDoc != null;

        String statusText;
        Color statusColor;
        IconData statusIcon;

        if (isSubmitted) {
          statusText = 'Submitted';
          statusColor = Colors.green;
          statusIcon = Icons.check_circle;
        } else if (isOverdue) {
          statusText = 'Overdue';
          statusColor = Colors.red;
          statusIcon = Icons.error_outline;
        } else {
          statusText = 'Pending';
          statusColor = Colors.orange;
          statusIcon = Icons.pending_actions;
        }

        return Container(
          decoration: BoxDecoration(
            color: c.cardBg,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: c.cardBorder, width: 1.5),
            boxShadow: c.cardShadow,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        task.title,
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.bold,
                          color: c.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (!widget.isTeacher)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(
                            alpha: c.isDark ? 0.2 : 0.1,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: statusColor.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(statusIcon, size: 12, color: statusColor),
                            const SizedBox(width: 4),
                            Text(
                              statusText,
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.timer,
                      size: 16,
                      color: isOverdue && !isSubmitted && !widget.isTeacher
                          ? Colors.red
                          : c.textSecondary.withValues(alpha: 0.6),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Due: ${DateFormat('MMM dd, yyyy HH:mm').format(task.deadline)}',
                      style: TextStyle(
                        color: isOverdue && !isSubmitted && !widget.isTeacher
                            ? Colors.red
                            : c.textSecondary,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: task.pdfLink.trim().isEmpty
                            ? null
                            : widget.onLaunchLink,
                        icon: Icon(
                          Icons.picture_as_pdf,
                          size: 18,
                          color: task.pdfLink.trim().isEmpty
                              ? c.textSecondary.withValues(alpha: 0.5)
                              : const Color(0xFFD32F2F),
                        ),
                        label: Text(
                          'Open File',
                          style: TextStyle(
                            color: task.pdfLink.trim().isEmpty
                                ? c.textSecondary.withValues(alpha: 0.5)
                                : c.textPrimary,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: c.cardBorder),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    if (!widget.isTeacher) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isNavigating ? null : _navigateToLecture,
                          icon: _isNavigating
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.arrow_forward),
                          label: const Text(
                            'Go to Task',
                            overflow: TextOverflow.ellipsis,
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: c.accentPrimary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
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

// ── Submit Link Field Widget ────────────────────────────────────────────────
class _SubmitLinkField extends StatefulWidget {
  final String taskId;
  final String lectureId;
  final String studentId;
  final VoidCallback onSubmitted;

  const _SubmitLinkField({
    required this.taskId,
    required this.lectureId,
    required this.studentId,
    required this.onSubmitted,
  });

  @override
  State<_SubmitLinkField> createState() => _SubmitLinkFieldState();
}

class _SubmitLinkFieldState extends State<_SubmitLinkField> {
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
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Submission failed: $e')));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: TextField(
        controller: _controller,
        enabled: !_isSubmitting,
        onSubmitted: (_) => _submit(),
        decoration: InputDecoration(
          labelText: 'Submit Google Drive Link',
          hintText: 'Paste link and press Enter',
          isDense: true,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          suffixIcon: _isSubmitting
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.send, size: 18),
                  onPressed: _submit,
                ),
        ),
      ),
    );
  }
}
