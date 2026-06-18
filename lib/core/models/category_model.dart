import 'package:cloud_firestore/cloud_firestore.dart';

class CategoryModel {
  final String id;
  final String name;
  final int lectureCount;
  final List<String> enrolledStudentAvatars;

  const CategoryModel({
    required this.id,
    required this.name,
    this.lectureCount = 0,
    this.enrolledStudentAvatars = const [],
  });

  factory CategoryModel.fromMap(Map<String, dynamic> map, String id) {
    return CategoryModel(
      id: id,
      name: map['name'] ?? '',
      lectureCount: map['lectureCount'] ?? 0,
      enrolledStudentAvatars: List<String>.from(
        map['enrolledStudentAvatars'] ?? [],
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {'name': name, 'lectureCount': lectureCount};
  }

  CategoryModel copyWith({String? id, String? name, int? lectureCount}) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      lectureCount: lectureCount ?? this.lectureCount,
    );
  }
}
