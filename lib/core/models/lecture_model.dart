import 'package:cloud_firestore/cloud_firestore.dart';

class LectureModel {
  final String id;
  final String title;
  final String categoryId;
  final String categoryName;
  final String thumbnailUrl;
  final List<String> lessons;
  final List<String> resources;
  final bool isPaid;
  final double price;
  final int? accessDurationDays;
  final String visibility; // 'published', 'private', 'scheduled'
  final DateTime? scheduledDate;
  final int enrolledCount;
  final String durationString;
  final double averageRating;
  final int reviewCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> enrolledStudentAvatars; // New field

  const LectureModel({
    required this.id,
    required this.title,
    required this.categoryId,
    required this.categoryName,
    required this.thumbnailUrl,
    required this.lessons,
    required this.resources,
    required this.isPaid,
    required this.price,
    required this.accessDurationDays,
    required this.visibility,
    this.scheduledDate,
    required this.enrolledCount,
    this.durationString = '',
    this.averageRating = 0.0,
    this.reviewCount = 0,
    required this.createdAt,
    required this.updatedAt,
    this.enrolledStudentAvatars = const [],
  });

  factory LectureModel.fromMap(Map<String, dynamic> map, String id) {
    return LectureModel(
      id: id,
      title: map['title'] ?? '',
      categoryId: map['categoryId'] ?? '',
      categoryName: map['categoryName'] ?? '',
      thumbnailUrl: map['thumbnailUrl'] ?? '',
      lessons: List<String>.from(map['lessons'] ?? []),
      resources: List<String>.from(map['resources'] ?? []),
      isPaid: map['isPaid'] ?? false,
      price: (map['price'] ?? 0.0).toDouble(),
      accessDurationDays: map['accessDurationDays'],
      visibility: map['visibility'] ?? 'private',
      scheduledDate: (map['scheduledDate'] as Timestamp?)?.toDate(),
      enrolledCount: map['enrolledCount'] ?? 0,
      durationString: map['durationString'] ?? '',
      averageRating: (map['averageRating'] ?? 0.0).toDouble(),
      reviewCount: map['reviewCount'] ?? 0,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      enrolledStudentAvatars: List<String>.from(
        map['enrolledStudentAvatars'] ?? [],
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'thumbnailUrl': thumbnailUrl,
      'lessons': lessons,
      'resources': resources,
      'isPaid': isPaid,
      'price': price,
      if (accessDurationDays != null) 'accessDurationDays': accessDurationDays,
      'visibility': visibility,
      if (scheduledDate != null)
        'scheduledDate': Timestamp.fromDate(scheduledDate!),
      'enrolledCount': enrolledCount,
      'durationString': durationString,
      'averageRating': averageRating,
      'reviewCount': reviewCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'enrolledStudentAvatars': enrolledStudentAvatars,
    };
  }

  LectureModel copyWith({
    String? id,
    String? title,
    String? categoryId,
    String? categoryName,
    String? thumbnailUrl,
    List<String>? lessons,
    List<String>? resources,
    bool? isPaid,
    double? price,
    int? accessDurationDays,
    String? visibility,
    DateTime? scheduledDate,
    int? enrolledCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LectureModel(
      id: id ?? this.id,
      title: title ?? this.title,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      lessons: lessons ?? this.lessons,
      resources: resources ?? this.resources,
      isPaid: isPaid ?? this.isPaid,
      price: price ?? this.price,
      accessDurationDays: accessDurationDays ?? this.accessDurationDays,
      visibility: visibility ?? this.visibility,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      enrolledCount: enrolledCount ?? this.enrolledCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
