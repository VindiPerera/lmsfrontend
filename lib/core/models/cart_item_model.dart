import 'dart:convert';

class CartItemModel {
  final String itemId;
  final String itemType; // 'lecture' or 'package'
  final String title;
  final String thumbnailUrl;
  final double price;

  const CartItemModel({
    required this.itemId,
    required this.itemType,
    required this.title,
    required this.thumbnailUrl,
    required this.price,
  });

  Map<String, dynamic> toMap() {
    return {
      'itemId': itemId,
      'itemType': itemType,
      'title': title,
      'thumbnailUrl': thumbnailUrl,
      'price': price,
    };
  }

  factory CartItemModel.fromMap(Map<String, dynamic> map) {
    return CartItemModel(
      itemId: map['itemId'] ?? '',
      itemType: map['itemType'] ?? 'lecture',
      title: map['title'] ?? '',
      thumbnailUrl: map['thumbnailUrl'] ?? '',
      price: (map['price'] ?? 0.0).toDouble(),
    );
  }

  String toJson() => json.encode(toMap());

  factory CartItemModel.fromJson(String source) =>
      CartItemModel.fromMap(json.decode(source));
}
