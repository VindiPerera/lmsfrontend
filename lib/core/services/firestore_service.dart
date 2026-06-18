import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lms/features/auth/models/user_model.dart';

/// CRUD operations for the `users` collection in Cloud Firestore.
class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Reference to the `users` collection.
  CollectionReference<Map<String, dynamic>> get _usersRef =>
      _db.collection('users');

  // ── Create ─────────────────────────────────────────────
  /// Creates a new user document keyed by [uid].
  /// [profileImageUrl] defaults to empty; pass Google photo URL for Google users.
  Future<void> createUserDocument({
    required String uid,
    required String name,
    required String email,
    String? phoneNumber,
    required String role,
    String? studentId,
    String profileImageUrl = '',
  }) async {
    final userModel = UserModel(
      uid: uid,
      name: name,
      email: email,
      phoneNumber: phoneNumber,
      role: role,
      studentId: studentId,
      profileImageUrl: profileImageUrl,
      isActive: true,
      createdAt: DateTime.now(),
    );

    await _usersRef.doc(uid).set(userModel.toMap());
  }

  // ── Read ───────────────────────────────────────────────
  /// Fetches the user document and returns a [UserModel], or `null` if not found.
  Future<UserModel?> getUserDocument(String uid) async {
    final doc = await _usersRef.doc(uid).get();
    if (!doc.exists || doc.data() == null) return null;
    return UserModel.fromMap(doc.data()!);
  }

  /// Returns `true` if a document with [uid] already exists.
  Future<bool> userExists(String uid) async {
    final doc = await _usersRef.doc(uid).get();
    return doc.exists;
  }

  // ── Update ──────────────────────────────────────────────
  /// Updates only the `profileImageUrl` field for [uid].
  Future<void> updateProfileImageUrl(String uid, String url) async {
    await _usersRef.doc(uid).update({'profileImageUrl': url});
  }

  /// Updates specific user data fields for [uid].
  Future<void> updateUserData(String uid, Map<String, dynamic> data) async {
    await _usersRef.doc(uid).update(data);
  }

  // ── Queries ─────────────────────────────────────────────
  /// Fetches all users from the database.
  Future<List<UserModel>> getAllUsers() async {
    final snapshot = await _usersRef.get();
    return snapshot.docs.map((doc) => UserModel.fromMap(doc.data())).toList();
  }

  // ── Delete ─────────────────────────────────────────────
  /// Deletes a user document by [uid].
  Future<void> deleteUserDocument(String uid) async {
    await _usersRef.doc(uid).delete();
  }
}
