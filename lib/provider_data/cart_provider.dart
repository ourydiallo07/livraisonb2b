// lib/provider_data/cart_provider.dart
import 'package:flutter/material.dart';
import 'package:livraisonb2b/models/product.dart';

class CartProvider with ChangeNotifier {
  final List<Product> _items = [];

  List<Product> get items => [
    ..._items,
  ]; // Copie pour éviter les modifications externes

  // Ajouter un produit au panier
  void addItem(Product product) {
    _items.add(product);
    notifyListeners();
  }

  // Retirer un produit du panier
  void removeItem(String productId) {
    _items.removeWhere((item) => item.id == productId);
    notifyListeners();
  }

  // Vider complètement le panier
  void clearCart() {
    _items.clear();
    notifyListeners();
  }

  // Calculer le total du panier
  double get totalAmount {
    return _items.fold(0, (sum, item) => sum + item.price);
  }

  // Vérifier si un produit est déjà dans le panier (optionnel)
  bool isInCart(String productId) {
    return _items.any((item) => item.id == productId);
  }
}
