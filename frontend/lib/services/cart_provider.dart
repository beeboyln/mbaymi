import 'package:flutter/material.dart';

class CartItem {
  final int id;
  final String name;
  final double price;
  int quantity;
  final String? image;
  final String unit;
  final int sellerId;

  CartItem({
    required this.id,
    required this.name,
    required this.price,
    required this.quantity,
    this.image,
    required this.unit,
    required this.sellerId,
  });

  double get totalPrice => price * quantity;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'price': price,
    'quantity': quantity,
    'image': image,
    'unit': unit,
    'seller_id': sellerId,
  };

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
    id: json['id'] as int,
    name: json['name'] as String,
    price: (json['price'] as num).toDouble(),
    quantity: json['quantity'] as int,
    image: json['image'] as String?,
    unit: json['unit'] as String? ?? 'kg',
    sellerId: json['seller_id'] as int? ?? 0,
  );
}

class CartProvider extends ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items => _items;

  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);

  double get totalPrice => _items.fold(0, (sum, item) => sum + item.totalPrice);

  /// Ajouter un article au panier
  void addItem({
    required int id,
    required String name,
    required double price,
    required int quantity,
    String? image,
    required String unit,
    required int sellerId,
  }) {
    // Vérifier si l'article existe déjà
    final existingIndex = _items.indexWhere((item) => item.id == id);

    if (existingIndex >= 0) {
      // Augmenter la quantité si l'article existe
      _items[existingIndex].quantity += quantity;
    } else {
      // Ajouter un nouvel article
      _items.add(CartItem(
        id: id,
        name: name,
        price: price,
        quantity: quantity,
        image: image,
        unit: unit,
        sellerId: sellerId,
      ));
    }
    notifyListeners();
  }

  /// Supprimer un article du panier
  void removeItem(int id) {
    _items.removeWhere((item) => item.id == id);
    notifyListeners();
  }

  /// Modifier la quantité d'un article
  void updateQuantity(int id, int newQuantity) {
    final itemIndex = _items.indexWhere((item) => item.id == id);
    if (itemIndex >= 0) {
      if (newQuantity <= 0) {
        removeItem(id);
      } else {
        _items[itemIndex].quantity = newQuantity;
        notifyListeners();
      }
    }
  }

  /// Vider le panier
  void clear() {
    _items.clear();
    notifyListeners();
  }

  /// Obtenir les articles d'un vendeur spécifique
  List<CartItem> getItemsBySeller(int sellerId) {
    return _items.where((item) => item.sellerId == sellerId).toList();
  }

  /// Obtenir le total du panier pour un vendeur
  double getTotalBySeller(int sellerId) {
    return _items
        .where((item) => item.sellerId == sellerId)
        .fold(0, (sum, item) => sum + item.totalPrice);
  }
}
