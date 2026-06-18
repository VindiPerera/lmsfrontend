import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/progress_model.dart';
import '../models/lecture_model.dart';

class ProgressService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _userProgressRef(String userId) {
    return _db.collection('users').doc(userId).collection('progress');
  }

  /// Get the progress for a specific lecture
  Stream<ProgressModel?> getLectureProgress(String userId, String lectureId) {
    return _userProgressRef(userId).doc(lectureId).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return ProgressModel.fromMap(doc.data()!, doc.id);
    });
  }

  /// Mark a lesson as completed
  Future<void> markLessonCompleted(
    String userId,
    LectureModel lecture,
    String lessonId,
  ) async {
    final progressRef = _userProgressRef(userId).doc(lecture.id);

    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(progressRef);
      List<String> completedLessons = [];

      if (snapshot.exists && snapshot.data() != null) {
        completedLessons = List<String>.from(
          snapshot.data()!['completedLessons'] ?? [],
        );
      }

      if (!completedLessons.contains(lessonId)) {
        completedLessons.add(lessonId);
      }

      final totalItems = lecture.lessons.length + lecture.resources.length;
      final double percentage = totalItems == 0
          ? 0.0
          : completedLessons.length / totalItems;

      final progressModel = ProgressModel(
        lectureId: lecture.id,
        completedLessons: completedLessons,
        completionPercentage: percentage,
      );

      transaction.set(progressRef, progressModel.toMap());
    });
  }

  /// Get all ongoing progress for a user
  Stream<List<ProgressModel>> getOngoingProgressStream(String userId) {
    // 1. Get progress items that are explicitly trackable (0.0 to 1.0)
    // Note: We include 0.0 specifically for newly enrolled courses.
    return _userProgressRef(userId)
        .where('completionPercentage', isLessThan: 1.0)
        .orderBy('completionPercentage', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ProgressModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  /// Get all progress for a user (including completed courses)
  Stream<List<ProgressModel>> getAllProgressStream(String userId) {
    return _userProgressRef(userId).snapshots().map(
      (snapshot) => snapshot.docs
          .map((doc) => ProgressModel.fromMap(doc.data(), doc.id))
          .toList(),
    );
  }
}
