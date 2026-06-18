import 'package:cloud_firestore/cloud_firestore.dart';

class PackageModel {
  final String id;
  final String title;
  final String description;
  final String thumbnailUrl;
  final double price;
  final bool isLifetime;
  final int accessDurationDays;
  final List<String> includedLectureIds;
  final String visibility; // 'published', 'private'
  final DateTime createdAt;
  final DateTime updatedAt;

  const PackageModel({
    required this.id,
    required this.title,
    required this.description,
    required this.thumbnailUrl,
    required this.price,
    this.isLifetime = false,
    required this.accessDurationDays,
    required this.includedLectureIds,
    required this.visibility,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PackageModel.fromMap(Map<String, dynamic> map, String id) {
    return PackageModel(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      thumbnailUrl: map['thumbnailUrl'] ?? '',
      price: (map['price'] ?? 0.0).toDouble(),
      isLifetime: map['isLifetime'] ?? false,
      accessDurationDays: map['accessDurationDays'] ?? 0,
      includedLectureIds: List<String>.from(map['includedLectureIds'] ?? []),
      visibility: map['visibility'] ?? 'private',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'thumbnailUrl': thumbnailUrl,
      'price': price,
      'isLifetime': isLifetime,
      'accessDurationDays': accessDurationDays,
      'includedLectureIds': includedLectureIds,
      'visibility': visibility,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  PackageModel copyWith({
    String? id,
    String? title,
    String? description,
    String? thumbnailUrl,
    double? price,
    bool? isLifetime,
    int? accessDurationDays,
    List<String>? includedLectureIds,
    String? visibility,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PackageModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      price: price ?? this.price,
      isLifetime: isLifetime ?? this.isLifetime,
      accessDurationDays: accessDurationDays ?? this.accessDurationDays,
      includedLectureIds: includedLectureIds ?? this.includedLectureIds,
      visibility: visibility ?? this.visibility,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
