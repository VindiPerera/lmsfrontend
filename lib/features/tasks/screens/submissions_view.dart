import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:lms/core/constants/app_colors.dart';
import 'package:lms/core/constants/app_text_styles.dart';

class SubmissionsView extends StatelessWidget {
  const SubmissionsView({super.key});

  Future<void> _launchUrl(BuildContext context, String url) async {
    String sanitizedUrl = url.trim();
    if (!sanitizedUrl.startsWith('http://') &&
        !sanitizedUrl.startsWith('https://')) {
      sanitizedUrl = 'https://$sanitizedUrl';
    }
    final uri = Uri.tryParse(sanitizedUrl);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Could not open link')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('task_submissions')
          .orderBy('submittedAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.inbox_rounded,
                  color: AppColors.textHint.withValues(alpha: 0.3),
                  size: 64,
                ),
                const SizedBox(height: 16),
                Text('No submissions yet', style: AppTextStyles.heading3),
              ],
            ),
          );
        }

        final submissions = snapshot.data!.docs;

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: submissions.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final data = submissions[index].data() as Map<String, dynamic>;
            final taskId = data['taskId'] ?? '';
            final studentId = data['studentId'] ?? '';
            final submittedAt =
                (data['submittedAt'] as Timestamp?)?.toDate() ?? DateTime.now();
            final link = data['googleDriveLink'] ?? '';

            return FutureBuilder<List<DocumentSnapshot>>(
              future: Future.wait([
                FirebaseFirestore.instance
                    .collection('tasks')
                    .doc(taskId)
                    .get(),
                FirebaseFirestore.instance
                    .collection('users')
                    .doc(studentId)
                    .get(),
              ]),
              builder: (context, infoSnapshot) {
                String taskName = 'Unknown Task';
                String studentName = 'Unknown Student';

                if (infoSnapshot.hasData && infoSnapshot.data!.length == 2) {
                  final taskDoc = infoSnapshot.data![0];
                  final userDoc = infoSnapshot.data![1];

                  if (taskDoc.exists) {
                    final taskData = taskDoc.data() as Map<String, dynamic>?;
                    // Support legacy courseId or lectureId field mapping
                    taskName =
                        taskData?['title'] ??
                        taskData?['taskTitle'] ??
                        taskData?['name'] ??
                        'Task';
                  }
                  if (userDoc.exists) {
                    studentName =
                        (userDoc.data() as Map<String, dynamic>?)?['name'] ??
                        'Student';
                  }
                }

                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    taskName,
                                    style: AppTextStyles.bodyLarge.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'By: $studentName',
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                DateFormat(
                                  'MMM dd, yyyy\nHH:mm',
                                ).format(submittedAt),
                                textAlign: TextAlign.right,
                                style: AppTextStyles.label.copyWith(
                                  color: AppColors.textHint,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: link.isEmpty
                                    ? null
                                    : () => _launchUrl(context, link),
                                icon: const Icon(Icons.link_rounded),
                                label: const Text(
                                  'View Submission Link',
                                  overflow: TextOverflow.ellipsis,
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                ),
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
          },
        );
      },
    );
  }
}
