import 'package:cloud_firestore/cloud_firestore.dart';

/// Data model representing a user document in Firestore.
class UserModel {
  final String uid;
  final String name;
  final String email;
  final String? phoneNumber;
  final String role; // 'student' or 'teacher'
  final String? studentId;
  final String profileImageUrl;
  final bool isActive;
  final DateTime createdAt;

  const UserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.phoneNumber,
    required this.role,
    this.studentId,
    required this.profileImageUrl,
    this.isActive = true,
    required this.createdAt,
  });

  /// Deserialise from a Firestore document map.
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] as String? ?? '',
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      phoneNumber: map['phoneNumber'] as String?,
      role: map['role'] as String? ?? 'student',
      studentId: map['studentId'] as String?,
      profileImageUrl: map['profileImageUrl'] as String? ?? '',
      isActive: map['isActive'] as bool? ?? true,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Serialise to a Firestore-compatible map.
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      if (phoneNumber != null) 'phoneNumber': phoneNumber,
      'role': role,
      if (studentId != null) 'studentId': studentId,
      'profileImageUrl': profileImageUrl,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Quick helper to copy with modifications.
  UserModel copyWith({
    String? uid,
    String? name,
    String? email,
    String? phoneNumber,
    String? role,
    String? studentId,
    String? profileImageUrl,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      role: role ?? this.role,
      studentId: studentId ?? this.studentId,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
