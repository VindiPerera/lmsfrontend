import 'package:cloud_firestore/cloud_firestore.dart';

class PurchaseModel {
  final String id; // The document ID of the purchase record
  final String itemId; // The ID of the lecture or package
  final String itemType; // 'lecture' or 'package'
  final DateTime purchasedAt;
  final DateTime? expiresAt;
  final String status; // 'active', 'expired'

  const PurchaseModel({
    required this.id,
    required this.itemId,
    required this.itemType,
    required this.purchasedAt,
    this.expiresAt,
    required this.status,
  });

  factory PurchaseModel.fromMap(Map<String, dynamic> map, String id) {
    return PurchaseModel(
      id: id,
      itemId: map['itemId'] ?? '',
      itemType: map['itemType'] ?? 'lecture',
      purchasedAt:
          (map['purchasedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expiresAt: (map['expiresAt'] as Timestamp?)?.toDate(),
      status: map['status'] ?? 'active',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'itemId': itemId,
      'itemType': itemType,
      'purchasedAt': Timestamp.fromDate(purchasedAt),
      if (expiresAt != null) 'expiresAt': Timestamp.fromDate(expiresAt!),
      'status': status,
    };
  }

  PurchaseModel copyWith({
    String? id,
    String? itemId,
    String? itemType,
    DateTime? purchasedAt,
    DateTime? expiresAt,
    String? status,
  }) {
    return PurchaseModel(
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      itemType: itemType ?? this.itemType,
      purchasedAt: purchasedAt ?? this.purchasedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      status: status ?? this.status,
    );
  }
}
