import 'package:flutter/material.dart';
import 'package:lms/core/constants/app_colors.dart';
import 'package:lms/core/constants/app_text_styles.dart';
import 'package:lms/core/models/progress_model.dart';
import 'package:lms/core/services/lecture_service.dart';
import 'package:lms/features/home/screens/home_page.dart'; // To use CachedOngoingCard

class OngoingCoursesScreen extends StatelessWidget {
  final List<ProgressModel> progressList;

  const OngoingCoursesScreen({super.key, required this.progressList});

  @override
  Widget build(BuildContext context) {
    final lectureService = LectureService();
    const orangeAction = Color(0xFFFF9900);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F9FF),

      appBar: AppBar(
        title: const Text(
          'Ongoing Courses',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: progressList.isEmpty
          ? const Center(child: Text("No ongoing courses found."))
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              itemCount: progressList.length,
              itemBuilder: (context, index) {
                return CachedOngoingCard(
                  progressModel: progressList[index],
                  orangeAction: orangeAction,
                  lectureService: lectureService,
                );
              },
            ),
    );
  }
}
