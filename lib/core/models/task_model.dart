import 'package:cloud_firestore/cloud_firestore.dart';

class TaskModel {
  final String id;
  final String lectureId;
  final String title;
  final String pdfLink; // Provided by teacher
  final DateTime deadline;
  final DateTime createdAt;

  TaskModel({
    required this.id,
    required this.lectureId,
    required this.title,
    required this.pdfLink,
    required this.deadline,
    required this.createdAt,
  });

  factory TaskModel.fromMap(Map<String, dynamic> map, String id) {
    final resolvedLectureId = _firstNonEmptyString([
      map['lectureId'],
      map['courseId'],
      map['lecture_id'],
      map['course_id'],
    ]);
    final resolvedTitle = _firstNonEmptyString([
      map['title'],
      map['taskTitle'],
      map['name'],
    ]);
    final resolvedPdfLink = _firstNonEmptyString([
      map['pdfLink'],
      map['pdfUrl'],
      map['assignmentUrl'],
      map['fileUrl'],
    ]);

    return TaskModel(
      id: id,
      lectureId: resolvedLectureId,
      title: resolvedTitle,
      pdfLink: resolvedPdfLink,
      deadline:
          _parseDateTime(
            map['deadline'] ??
                map['dueDate'] ??
                map['dueAt'] ??
                map['deadlineAt'],
          ) ??
          DateTime.now(),
      createdAt:
          _parseDateTime(
            map['createdAt'] ?? map['created_at'] ?? map['createdOn'],
          ) ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'lectureId': lectureId,
      'title': title,
      'pdfLink': pdfLink,
      'deadline': Timestamp.fromDate(deadline),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  static String _firstNonEmptyString(List<dynamic> values) {
    for (final value in values) {
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return '';
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is int) {
      final isMillis = value > 100000000000;
      return DateTime.fromMillisecondsSinceEpoch(
        isMillis ? value : value * 1000,
      );
    }
    if (value is String) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}
