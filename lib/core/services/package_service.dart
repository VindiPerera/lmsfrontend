import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/package_model.dart';

class PackageService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _packagesRef =>
      _db.collection('packages');

  // ── Create ─────────────────────────────────────────────
  Future<void> createPackage(PackageModel package) async {
    await _packagesRef.doc(package.id).set(package.toMap());
  }

  // ── Read ───────────────────────────────────────────────
  Future<PackageModel?> getPackage(String id) async {
    final doc = await _packagesRef.doc(id).get();
    if (!doc.exists || doc.data() == null) return null;
    return PackageModel.fromMap(doc.data()!, doc.id);
  }

  Stream<List<PackageModel>> getPublishedPackagesStream() {
    return _packagesRef
        .where('visibility', isEqualTo: 'published')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => PackageModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  Stream<List<PackageModel>> getAllPackagesStream() {
    return _packagesRef
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => PackageModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  // ── Update ──────────────────────────────────────────────
  Future<void> updatePackage(PackageModel package) async {
    await _packagesRef.doc(package.id).update({
      ...package.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ── Delete ─────────────────────────────────────────────
  Future<void> deletePackage(String id) async {
    await _packagesRef.doc(id).delete();
  }
}
