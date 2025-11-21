import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:livraisonb2b/constants/app_errors.dart';
import 'package:livraisonb2b/models/CartItem.dart';
import 'package:livraisonb2b/models/app_user.dart';
import 'package:livraisonb2b/models/order.dart';
import 'package:livraisonb2b/models/product.dart';
import 'package:livraisonb2b/provider_data/Login_data.dart';
import 'package:livraisonb2b/provider_data/order_provider.dart';
import 'package:livraisonb2b/services/discount_service.dart';
import 'package:livraisonb2b/services/user_service.dart';
import 'package:provider/provider.dart';

class CartProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Map<String, List<CartItem>> _userCarts = {}; // Uniquement CartItem

  Future<void> loadCart(String userId) async {
    if (userId.isEmpty) return;

    try {
      final doc = await _firestore.collection('userCarts').doc(userId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final items = List<Map<String, dynamic>>.from(data['items'] ?? []);

        _userCarts[userId] =
            items
                .map(
                  (item) => CartItem(
                    id:
                        item['id'] ??
                        item['productId'], // Compatibilité avec les deux formats
                    name: item['name'],
                    price: (item['price'] as num).toDouble(),
                    imageUrl: item['imageUrl'],
                    unit: item['unit'],
                    quantity: item['quantity'] ?? 1,
                  ),
                )
                .toList();

        notifyListeners();
      }
    } catch (e) {
      debugPrint('Erreur chargement panier: $e');
    }
  }

  Future<void> _saveCart(String userId) async {
    if (userId.isEmpty) return;

    try {
      final items =
          _userCarts[userId]?.map((item) => item.toMap()).toList() ?? [];
      await _firestore.collection('userCarts').doc(userId).set({
        'items': items,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Erreur sauvegarde panier: $e');
    }
  }

  List<CartItem> getItems(String userId) => [..._userCarts[userId] ?? []];

  void addItem(String userId, Product product, {int quantity = 1}) {
    if (userId.isEmpty) return;

    final existingIndex =
        _userCarts[userId]?.indexWhere((item) => item.id == product.id) ?? -1;

    if (existingIndex >= 0) {
      // Merge les quantités si le produit existe déjà
      final existingItem = _userCarts[userId]![existingIndex];
      _userCarts[userId]![existingIndex] = existingItem.copyWith(
        quantity: existingItem.quantity + quantity,
      );
    } else {
      // Ajout d'un nouvel item
      _userCarts
          .putIfAbsent(userId, () => [])
          .add(
            CartItem(
              id: product.id,
              name: product.name,
              price: product.price ?? 0.0,
              imageUrl: product.imageUrl,
              unit: product.category,
              quantity: quantity,
            ),
          );
    }

    _saveCart(userId);
    notifyListeners();
  }

  // Dans la classe CartProvider

  double calculateTotalWithDiscounts(String userId, BuildContext context) {
    final user = Provider.of<LoginData>(context, listen: false).currentUserApp;
    final cartTotal = getTotalAmount(userId);

    // 1. Applique la remise personnelle
    double personalDiscount = 0;
    if (user.personalDiscount != null) {
      personalDiscount = cartTotal * (user.personalDiscount! / 100);
    }

    // 2. Applique le bonus automatique
    final automaticBonus = DiscountService.calculateAutomaticBonus(
      cartTotal,
      user,
    );

    return cartTotal - personalDiscount + automaticBonus;
  }

  Map<String, double> getDiscountDetails(String userId, BuildContext context) {
    final user = Provider.of<LoginData>(context, listen: false).currentUserApp;
    final cartTotal = getTotalAmount(userId);

    return {
      'cartTotal': cartTotal,
      'personalDiscount':
          user.personalDiscount != null
              ? cartTotal * (user.personalDiscount! / 100)
              : 0,
      'automaticBonus': DiscountService.calculateAutomaticBonus(
        cartTotal,
        user,
      ),
      'finalTotal': calculateTotalWithDiscounts(userId, context),
    };
  }

  void updateItemQuantity(String userId, String itemId, int newQuantity) {
    if (_userCarts[userId] != null) {
      final index = _userCarts[userId]!.indexWhere((item) => item.id == itemId);
      if (index != -1) {
        _userCarts[userId]![index].quantity = newQuantity;
        _saveCart(userId);
        notifyListeners();
      }
    }
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
    if (userId.isEmpty) return 0.0;

    final cartItems = _userCarts[userId];
    if (cartItems == null || cartItems.isEmpty) return 0.0;

    return cartItems.fold(
      0.0,
      (total, item) => total + ((item.price ?? 0.0) * item.quantity),
    );
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

  // Dans cart_provider.dart
  Future<String> validateCart({
    required String userId,
    required OrderProvider orderProvider,
    required UserApp currentUser,
    required BuildContext context,
    String? deliveryAddress,
    GeoPoint? deliveryLocation,
    String? deliveryNotes,
  }) async {
    // Validation des entrées
    if (userId.isEmpty) {
      throw AppError(
        AppErrorType.invalidInput,
        message: 'Utilisateur non identifié',
      );
    }

    final items = getItems(userId);
    if (items.isEmpty) {
      throw AppError(
        AppErrorType.invalidInput,
        message: 'Votre panier est vide',
      );
    }

    if (deliveryAddress == null || deliveryAddress.isEmpty) {
      throw AppError(
        AppErrorType.invalidInput,
        message: 'Veuillez spécifier une adresse de livraison',
      );
    }

    // Conversion des articles
    final orderItems =
        items
            .map(
              (item) => OrderItem(
                productId: item.id,
                name: item.name,
                quantity: item.quantity,
                price: item.price,
                imageUrl: item.imageUrl,
                unit: item.unit ?? 'kg',
              ),
            )
            .toList();

    // Création de la commande
    try {
      final orderId = await orderProvider.createOrder(
        userId: userId,
        items: orderItems,
        userfirstName: currentUser.firstName ?? '',
        userlastName: currentUser.lastName ?? '',
        userphone: currentUser.phone ?? '',

        total: getTotalAmount(userId),
        deliveryAddress: deliveryAddress,
        deliveryLocation: deliveryLocation,
        deliveryNotes: deliveryNotes,
      );

      if (deliveryAddress != null && deliveryLocation != null) {
        await UserService.updateUserLocation(
          userId: userId,
          address: deliveryAddress,
          location: deliveryLocation,
        );

        final loginData = Provider.of<LoginData>(context, listen: false);
        loginData.updateUserApp(
          currentUser.copyWith(
            address: deliveryAddress,
            location: deliveryLocation,
          ),
        );
      }

      // Vider le panier seulement après succès
      clearCart(userId);
      return orderId;
    } catch (e) {
      debugPrint('Erreur création commande: $e');
      rethrow;
    }
  }
}
