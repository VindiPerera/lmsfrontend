import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lms/core/services/firestore_service.dart';

class TeacherStatsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirestoreService _firestoreService = FirestoreService();

  Future<Map<String, dynamic>> getTeacherStats(String teacherId) async {
    try {
      // 1. Fetch total students (using exactly the same logic as the dashboard)
      int totalStudents = 0;
      final users = await _firestoreService.getAllUsers();
      for (var u in users) {
        if (u.role.toLowerCase() == 'student') {
          totalStudents++;
        }
      }

      // 2. Get all lectures
      final lecturesSnapshot = await _firestore.collection('lectures').get();

      // 3. Get all packages
      final packagesSnapshot = await _firestore.collection('packages').get();

      double totalRating = 0.0;
      int totalLectures =
          lecturesSnapshot.docs.length + packagesSnapshot.docs.length;
      int ratingCount = 0;
      double totalPayments = 0.0;
      int pendingSlips = 0; // Mock or query if slip system exists

      for (var doc in lecturesSnapshot.docs) {
        final data = doc.data();

        final rating = (data['averageRating'] as num?)?.toDouble() ?? 0.0;
        final reviews = (data['reviewCount'] as num?)?.toInt() ?? 0;
        if (reviews > 0) {
          totalRating += (rating * reviews);
          ratingCount += reviews;
        }
      }

      for (var doc in packagesSnapshot.docs) {
        final data = doc.data();

        final rating = (data['averageRating'] as num?)?.toDouble() ?? 0.0;
        final reviews = (data['reviewCount'] as num?)?.toInt() ?? 0;
        if (reviews > 0) {
          totalRating += (rating * reviews);
          ratingCount += reviews;
        }
      }

      double averageRating = ratingCount > 0 ? totalRating / ratingCount : 0.0;

      // Mocking payments and slips for now since the payment aggregation logic might be complex
      // In a real app you'd aggregate from a 'payments' or 'orders' collection
      final paymentsSnapshot = await _firestore
          .collection('payments')
          .where('teacherId', isEqualTo: teacherId)
          .get();

      for (var doc in paymentsSnapshot.docs) {
        final data = doc.data();
        totalPayments += (data['amount'] as num?)?.toDouble() ?? 0.0;
        if (data['status'] == 'pending') {
          pendingSlips++;
        }
      }

      return {
        'totalStudents': totalStudents,
        'averageRating': averageRating,
        'totalLectures': totalLectures,
        'totalPayments': totalPayments,
        'pendingSlips': pendingSlips,
      };
    } catch (e) {
      return {
        'totalStudents': 0,
        'averageRating': 0.0,
        'totalLectures': 0,
        'totalPayments': 0.0,
        'pendingSlips': 0,
      };
    }
  }
}
