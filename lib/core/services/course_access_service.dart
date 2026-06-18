import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/lecture_model.dart';
import '../models/package_model.dart';
import '../models/purchase_model.dart';

class CourseAccessService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _userPurchasesRef(String userId) {
    return _db.collection('users').doc(userId).collection('purchases');
  }

  /// Grant manual access to a lecture or package from Admin
  Future<void> grantManualAccess({
    required String userEmail,
    required String itemId,
    required String itemType, // 'lecture' or 'package'
    required int accessDurationDays,
  }) async {
    // 1. Find user by email
    final userQuery = await _db
        .collection('users')
        .where('email', isEqualTo: userEmail)
        .limit(1)
        .get();
    if (userQuery.docs.isEmpty) {
      throw Exception('User not found with email: $userEmail');
    }
    final userId = userQuery.docs.first.id;

    // 2. Add purchase record
    final purchasedAt = DateTime.now();
    DateTime? expiresAt;
    if (accessDurationDays > 0) {
      expiresAt = purchasedAt.add(Duration(days: accessDurationDays));
    }

    final purchaseRef = _userPurchasesRef(userId).doc();
    final purchase = PurchaseModel(
      id: purchaseRef.id,
      itemId: itemId,
      itemType: itemType,
      purchasedAt: purchasedAt,
      expiresAt: expiresAt,
      status: 'active',
    );

    await purchaseRef.set(purchase.toMap());
  }

  /// Check if user has access to a specific lecture
  Future<bool> hasLectureAccess(String userId, LectureModel lecture) async {
    // 1. If it's free, grant access
    if (!lecture.isPaid) return true;

    // 2. Check for active single lecture purchase
    final singlePurchaseQuery = await _userPurchasesRef(userId)
        .where('itemType', isEqualTo: 'lecture')
        .where('itemId', isEqualTo: lecture.id)
        .where('status', isEqualTo: 'active')
        .get();

    for (var doc in singlePurchaseQuery.docs) {
      final purchase = PurchaseModel.fromMap(doc.data(), doc.id);
      if (purchase.expiresAt == null ||
          purchase.expiresAt!.isAfter(DateTime.now())) {
        return true;
      }
    }

    // 3. Check for active package purchase containing this lecture
    final packagePurchaseQuery = await _userPurchasesRef(userId)
        .where('itemType', isEqualTo: 'package')
        .where('status', isEqualTo: 'active')
        .get();

    for (var doc in packagePurchaseQuery.docs) {
      final purchase = PurchaseModel.fromMap(doc.data(), doc.id);
      if (purchase.expiresAt == null ||
          purchase.expiresAt!.isAfter(DateTime.now())) {
        // We have an active package, need to check if it includes the lecture
        final packageDoc = await _db
            .collection('packages')
            .doc(purchase.itemId)
            .get();
        if (packageDoc.exists && packageDoc.data() != null) {
          final package = PackageModel.fromMap(
            packageDoc.data()!,
            packageDoc.id,
          );
          if (package.includedLectureIds.contains(lecture.id)) {
            return true;
          }
        }
      }
    }

    // No access found
    return false;
  }

  /// Stream of user purchases
  Stream<List<PurchaseModel>> getUserPurchasesStream(String userId) {
    return _userPurchasesRef(userId)
        .orderBy('purchasedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => PurchaseModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }
}
