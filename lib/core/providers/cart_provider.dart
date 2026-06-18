import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cart_item_model.dart';
import '../services/location_service.dart';

class CartProvider extends ChangeNotifier {
  List<CartItemModel> _items = [];
  List<CartItemModel> get items => _items;

  String _currency = 'USD';
  String get currency => _currency;

  bool _isLocating = true;
  bool get isLocating => _isLocating;

  /// Assuming base prices in db are in USD, we temporarily multiply by 300 for LKR testing.
  double get totalPrice {
    double baseSum = _items.fold(0, (sum, item) => sum + item.price);
    return _currency == 'LKR' ? baseSum * 300.0 : baseSum;
  }

  /// Calculates dynamic price per item based on the detected currency.
  double getItemPrice(double basePrice) {
    return _currency == 'LKR' ? basePrice * 300.0 : basePrice;
  }

  CartProvider() {
    _initCart();
  }

  Future<void> _initCart() async {
    await loadCart();
    await _detectCurrency();
  }

  Future<void> _detectCurrency() async {
    try {
      final countryCode = await LocationService.getUserCountryCode();
      _currency = (countryCode == 'LK') ? 'LKR' : 'USD';
    } catch (_) {
      _currency = 'USD';
    } finally {
      _isLocating = false;
      notifyListeners();
    }
  }

  bool isInCart(String itemId) {
    return _items.any((item) => item.itemId == itemId);
  }

  Future<void> addToCart(CartItemModel item) async {
    if (!isInCart(item.itemId)) {
      _items.add(item);
      await _saveCart();
      notifyListeners();
    }
  }

  Future<void> removeFromCart(String itemId) async {
    _items.removeWhere((item) => item.itemId == itemId);
    await _saveCart();
    notifyListeners();
  }

  Future<void> clearCart() async {
    _items.clear();
    await _saveCart();
    notifyListeners();
  }

  Future<void> loadCart() async {
    final prefs = await SharedPreferences.getInstance();
    final String? cartJson = prefs.getString('user_cart');
    if (cartJson != null) {
      final List<dynamic> decodedList = json.decode(cartJson);
      _items = decodedList.map((item) => CartItemModel.fromMap(item)).toList();
      notifyListeners();
    }
  }

  Future<void> _saveCart() async {
    final prefs = await SharedPreferences.getInstance();
    final String cartJson = json.encode(
      _items.map((item) => item.toMap()).toList(),
    );
    await prefs.setString('user_cart', cartJson);
  }
}
