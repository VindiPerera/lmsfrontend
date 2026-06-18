import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/review_model.dart';
import '../models/lecture_model.dart';

class ReviewService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Reviews are stored as a subcollection under the lecture document
  CollectionReference<Map<String, dynamic>> _reviewsRef(String lectureId) {
    return _db.collection('lectures').doc(lectureId).collection('reviews');
  }

  // Add a new review and update the lecture's average rating and review count
  Future<void> addReview(String lectureId, ReviewModel review) async {
    final lectureRef = _db.collection('lectures').doc(lectureId);
    final newReviewRef = _reviewsRef(lectureId).doc(); // Auto-generated ID

    await _db.runTransaction((transaction) async {
      // 1. Read the lecture document first
      final lectureDoc = await transaction.get(lectureRef);

      if (!lectureDoc.exists) {
        throw Exception("Course does not exist.");
      }

      // 2. Perform calculations based on current data
      final lectureData = lectureDoc.data()!;
      final double currentAverage = (lectureData['averageRating'] ?? 0.0)
          .toDouble();
      final int currentCount = (lectureData['reviewCount'] ?? 0);

      final newCount = currentCount + 1;
      final newAverage =
          ((currentAverage * currentCount) + review.rating) / newCount;

      // 3. Write the new review
      final reviewToSave = review.copyWith(id: newReviewRef.id).toMap();
      transaction.set(newReviewRef, reviewToSave);

      // 4. Update the lecture document
      transaction.update(lectureRef, {
        'averageRating': newAverage,
        'reviewCount': newCount,
      });
    });
  }

  // Get a stream of reviews for a lecture
  Stream<List<ReviewModel>> getReviewsStream(String lectureId) {
    return _reviewsRef(lectureId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ReviewModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }
}
