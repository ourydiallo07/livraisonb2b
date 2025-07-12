import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:livraisonb2b/models/order.dart';
import 'package:livraisonb2b/models/product.dart';
import 'package:livraisonb2b/provider_data/order_provider.dart';

class CartProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Map<String, List<Product>> _userCarts = {};

  Future<void> loadCart(String userId) async {
    if (userId.isEmpty) return;

    try {
      final doc = await _firestore.collection('userCarts').doc(userId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final items = List<Map<String, dynamic>>.from(data['items'] ?? []);
        _userCarts[userId] =
            items.map((item) => Product.fromMap(item)).toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Erreur chargement panier: $e');
    }
  }

  Future<void> _saveCart(String userId) async {
    if (userId.isEmpty) return;

    try {
      final items = _userCarts[userId]?.map((p) => p.toMap()).toList() ?? [];
      await _firestore.collection('userCarts').doc(userId).set({
        'items': items,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Erreur sauvegarde panier: $e');
    }
  }

  List<Product> getItems(String userId) => [..._userCarts[userId] ?? []];

  void addItem(String userId, Product product) {
    if (userId.isEmpty) return;

    _userCarts.putIfAbsent(userId, () => []).add(product);
    _saveCart(userId);
    notifyListeners();
  }

  void removeItem(String userId, String productId) {
    if (userId.isEmpty) return;

    _userCarts[userId]?.removeWhere((item) => item.id == productId);
    _saveCart(userId);
    notifyListeners();
  }

  void clearCart(String userId) {
    if (userId.isEmpty) return;

    _userCarts[userId]?.clear();
    _saveCart(userId);
    notifyListeners();
  }

  double getTotalAmount(String userId) {
    final items = _userCarts[userId];
    if (items == null || items.isEmpty) return 0.0;

    return items.fold(0.0, (sum, item) => sum + (item.price ?? 0.0));
  }

  bool isInCart(String userId, String productId) {
    return _userCarts[userId]?.any((item) => item.id == productId) ?? false;
  }

  Future<void> migrateCart(String oldUserId, String newUserId) async {
    if (oldUserId.isEmpty || newUserId.isEmpty || oldUserId == newUserId)
      return;

    try {
      final doc = await _firestore.collection('userCarts').doc(oldUserId).get();
      if (doc.exists) {
        await _firestore
            .collection('userCarts')
            .doc(newUserId)
            .set(doc.data()!);
        await _firestore.collection('userCarts').doc(oldUserId).delete();

        if (_userCarts.containsKey(oldUserId)) {
          _userCarts[newUserId] = [..._userCarts[oldUserId] ?? []];
          _userCarts.remove(oldUserId);
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Erreur migration panier: $e');
    }
  }

  Future<String> validateCart({
    required String userId,
    required OrderProvider orderProvider,
    String? deliveryAddress,
  }) async {
    final items = getItems(userId);
    if (items.isEmpty) throw Exception('Le panier est vide');

    final orderItems =
        items
            .map(
              (product) => OrderItem(
                productId: product.id,
                name: product.name,
                quantity: 1,
                price: product.price,
                imageUrl: product.imageUrl,
              ),
            )
            .toList();

    final orderId = await orderProvider.createOrder(
      userId: userId,
      items: orderItems,
      total: getTotalAmount(userId),
      deliveryAddress: deliveryAddress,
    );

    clearCart(userId);
    return orderId;
  }
}
