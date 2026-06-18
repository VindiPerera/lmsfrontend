import 'package:cloud_firestore/cloud_firestore.dart';
import 'file_upload_service.dart';
import '../models/lecture_model.dart';
import '../models/category_model.dart';

class LectureService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _lecturesRef =>
      _db.collection('lectures');
  CollectionReference<Map<String, dynamic>> get _categoriesRef =>
      _db.collection('categories');

  // ── Create ─────────────────────────────────────────────
  Future<void> createLecture(LectureModel lecture) async {
    await _lecturesRef.doc(lecture.id).set(lecture.toMap());

    // Optionally increment category count
    if (lecture.categoryId.isNotEmpty) {
      await _categoriesRef.doc(lecture.categoryId).set({
        'lectureCount': FieldValue.increment(1),
      }, SetOptions(merge: true));
    }
  }

  // ── Read ───────────────────────────────────────────────
  Future<LectureModel?> getLecture(String id) async {
    final doc = await _lecturesRef.doc(id).get();
    if (!doc.exists || doc.data() == null) return null;
    return LectureModel.fromMap(doc.data()!, doc.id);
  }

  Stream<List<LectureModel>> getPublishedLecturesStream() {
    return _lecturesRef
        .where('visibility', isEqualTo: 'published')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => LectureModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  Stream<List<LectureModel>> getAllLecturesStream() {
    return _lecturesRef
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => LectureModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  // ── Update ──────────────────────────────────────────────
  Future<void> updateLecture(LectureModel lecture) async {
    await _lecturesRef.doc(lecture.id).update({
      ...lecture.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ── Delete ─────────────────────────────────────────────
  Future<void> deleteLecture(LectureModel lecture) async {
    // 1. Delete image from Storage/VPS
    if (lecture.thumbnailUrl.isNotEmpty) {
      // Just a best-effort delete, don't fail if image is already gone
      try {
        await FileUploadService().deleteFile(lecture.thumbnailUrl);
      } catch (_) {}
    }

    // 2. Delete the lecture document
    await _lecturesRef.doc(lecture.id).delete();

    // 3. Decrement category count
    if (lecture.categoryId.isNotEmpty) {
      await _categoriesRef.doc(lecture.categoryId).set({
        'lectureCount': FieldValue.increment(-1),
      }, SetOptions(merge: true));
    }

    // 4. Delete reviews subcollection (requires knowing it exists, best effort)
    try {
      final reviewsSnapshot = await _lecturesRef
          .doc(lecture.id)
          .collection('reviews')
          .get();
      for (var doc in reviewsSnapshot.docs) {
        await doc.reference.delete();
      }
    } catch (_) {}

    // 5. Cleanup user enrollments and progress, plus tasks
    try {
      final usersSnapshot = await _db.collection('users').get();

      // Fire and forget deletions to avoid 500 limit batch
      for (var userDoc in usersSnapshot.docs) {
        userDoc.reference
            .collection('enrolled_courses')
            .doc(lecture.id)
            .delete();
        userDoc.reference.collection('progress').doc(lecture.id).delete();
      }

      // Cleanup tasks
      final tasksSnapshot = await _db
          .collection('tasks')
          .where('lectureId', isEqualTo: lecture.id)
          .get();
      for (var doc in tasksSnapshot.docs) doc.reference.delete();

      // Cleanup task submissions
      final taskSubsSnapshot = await _db
          .collection('task_submissions')
          .where('lectureId', isEqualTo: lecture.id)
          .get();
      for (var doc in taskSubsSnapshot.docs) doc.reference.delete();
    } catch (_) {}
  }

  // ── Enrollment ─────────────────────────────────────────
  Future<void> enrollStudent(String userId, String lectureId) async {
    final userEnrollmentRef = _db
        .collection('users')
        .doc(userId)
        .collection('enrolled_courses')
        .doc(lectureId);
    final lectureRef = _lecturesRef.doc(lectureId);
    final progressRef = _db
        .collection('users')
        .doc(userId)
        .collection('progress')
        .doc(lectureId);
    final userRef = _db.collection('users').doc(userId);

    await _db.runTransaction((transaction) async {
      // 1. PERFORM ALL READS FIRST
      final enrollmentDoc = await transaction.get(userEnrollmentRef);
      final pDoc = await transaction.get(progressRef);
      // New reads for avatar logic
      final userDoc = await transaction.get(userRef);
      final lectureDoc = await transaction.get(lectureRef);

      // 2. PERFORM ALL WRITES SECOND
      if (!enrollmentDoc.exists) {
        // Add enrollment record
        transaction.set(userEnrollmentRef, {
          'enrolledAt': FieldValue.serverTimestamp(),
          'lectureId': lectureId,
        });

        // Update Lecture: Increment count + Update Avatar List if available
        final profileImageUrl = userDoc.data()?['profileImageUrl'] as String?;
        List<String> currentAvatars = [];
        if (lectureDoc.exists && lectureDoc.data() != null) {
          final data = lectureDoc.data()!;
          if (data.containsKey('enrolledStudentAvatars')) {
            currentAvatars = List<String>.from(data['enrolledStudentAvatars']);
          }
        }

        if (profileImageUrl != null &&
            profileImageUrl.isNotEmpty &&
            !currentAvatars.contains(profileImageUrl)) {
          currentAvatars.insert(0, profileImageUrl);
          if (currentAvatars.length > 4) {
            currentAvatars = currentAvatars.sublist(0, 4); // Keep latest 4
          }
        }

        transaction.update(lectureRef, {
          'enrolledCount': FieldValue.increment(1),
          'enrolledStudentAvatars': currentAvatars,
        });
      }

      // Initialize progress (0%) so it shows up in dashboard, even if they were already enrolled!
      if (!pDoc.exists) {
        transaction.set(progressRef, {
          'lectureId': lectureId,
          'completedLessons': [],
          'completionPercentage': 0.0,
          'lastAccessed': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  // ── Categories ─────────────────────────────────────────
  Future<void> createCategory(CategoryModel category) async {
    await _categoriesRef.doc(category.id).set(category.toMap());
  }

  Future<void> deleteCategory(String categoryId) async {
    await _categoriesRef.doc(categoryId).delete();
  }

  Stream<List<CategoryModel>> getCategoriesStream() {
    return _categoriesRef
        .orderBy('name')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => CategoryModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  Stream<List<LectureModel>> getLecturesByCategoryStream(String categoryId) {
    if (categoryId == 'all') return getPublishedLecturesStream();

    return _lecturesRef
        .where('visibility', isEqualTo: 'published')
        .where('categoryId', isEqualTo: categoryId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => LectureModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }
}
