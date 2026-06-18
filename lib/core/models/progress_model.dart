class ProgressModel {
  final String lectureId;
  final List<String> completedLessons;
  final double completionPercentage;

  const ProgressModel({
    required this.lectureId,
    required this.completedLessons,
    required this.completionPercentage,
  });

  factory ProgressModel.fromMap(Map<String, dynamic> map, String lectureId) {
    return ProgressModel(
      lectureId: lectureId,
      completedLessons: List<String>.from(map['completedLessons'] ?? []),
      completionPercentage: (map['completionPercentage'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'completedLessons': completedLessons,
      'completionPercentage': completionPercentage,
    };
  }

  ProgressModel copyWith({
    String? lectureId,
    List<String>? completedLessons,
    double? completionPercentage,
  }) {
    return ProgressModel(
      lectureId: lectureId ?? this.lectureId,
      completedLessons: completedLessons ?? this.completedLessons,
      completionPercentage: completionPercentage ?? this.completionPercentage,
    );
  }
}
