import 'package:cloud_firestore/cloud_firestore.dart';

class TaskSubmissionModel {
  final String id;
  final String taskId;
  final String studentId;
  final String lectureId;
  final String googleDriveLink; // Provided by student
  final DateTime submittedAt;
  final bool isMarkedRead;

  TaskSubmissionModel({
    required this.id,
    required this.taskId,
    required this.studentId,
    required this.lectureId,
    required this.googleDriveLink,
    required this.submittedAt,
    this.isMarkedRead = true,
  });

  factory TaskSubmissionModel.fromMap(Map<String, dynamic> map, String id) {
    return TaskSubmissionModel(
      id: id,
      taskId: map['taskId'] ?? '',
      studentId: map['studentId'] ?? '',
      lectureId: map['lectureId'] ?? '',
      googleDriveLink: map['googleDriveLink'] ?? '',
      submittedAt:
          (map['submittedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isMarkedRead: map['isMarkedRead'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'taskId': taskId,
      'studentId': studentId,
      'lectureId': lectureId,
      'googleDriveLink': googleDriveLink,
      'submittedAt': Timestamp.fromDate(submittedAt),
      'isMarkedRead': isMarkedRead,
    };
  }
}
