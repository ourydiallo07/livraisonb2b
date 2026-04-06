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

  // Dans cart_provider.dart - méthode validateCart
  Future<String> validateCart({
    required String userId,
    required OrderProvider orderProvider,
    required UserApp currentUser,
    required BuildContext context,
    String? deliveryAddress,
    GeoPoint? deliveryLocation,
    String? deliveryNotes,
    UserApp? recipientUser,
  }) async {
    // Validation des entrées
    if (userId.isEmpty) {
      throw AppError(
        AppErrorType.invalidInput,
        message: 'Utilisateur non identifié',
      );
    }

    // VÉRIFICATION IMPORTANTE : L'ID utilisateur doit exister
    if (currentUser.id == null || currentUser.id!.isEmpty) {
      throw AppError(
        AppErrorType.invalidInput,
        message: 'Utilisateur non connecté correctement',
      );
    }

    final items = getItems(userId);
    if (items.isEmpty) {
      throw AppError(
        AppErrorType.invalidInput,
        message: 'Votre panier est vide',
      );
    }

    final targetUser = recipientUser ?? currentUser;

    // Utiliser l'adresse fournie ou l'adresse existante
    final targetAddress = deliveryAddress ?? targetUser.address;
    final targetLocation = deliveryLocation ?? targetUser.location;

    // Validation de l'adresse
    if (targetAddress == null || targetAddress.isEmpty) {
      throw AppError(
        AppErrorType.invalidInput,
        message:
            'Aucune adresse disponible. Veuillez sélectionner une adresse de livraison.',
      );
    }

    if (targetLocation == null) {
      throw AppError(
        AppErrorType.invalidInput,
        message: 'Localisation du client non disponible.',
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
        userId: targetUser.id!,
        items: orderItems,
        userfirstName: targetUser.firstName ?? '',
        userlastName: targetUser.lastName ?? '',
        userphone: targetUser.phone ?? '',
        total: getTotalAmount(userId),
        deliveryAddress: targetAddress,
        deliveryLocation: targetLocation,
        deliveryNotes: deliveryNotes,
        orderedByAgentId: recipientUser != null ? currentUser.id : null,
        orderedByAgentName:
            recipientUser != null
                ? '${currentUser.firstName} ${currentUser.lastName}'
                : null,
      );

      // Vider le panier après succès
      clearCart(userId);

      // IMPORTANT: Mettre à jour l'adresse de l'utilisateur
      // (uniquement pour ses propres commandes, pas pour les commandes d'agent)
      if (recipientUser == null &&
          deliveryAddress != null &&
          deliveryAddress.isNotEmpty &&
          currentUser.id != null) {
        // Vérification supplémentaire

        // Vérifier si l'adresse est différente avant de mettre à jour
        if (deliveryAddress != currentUser.address) {
          await _updateUserAddress(
            userId: currentUser.id!,
            address: deliveryAddress,
            location: deliveryLocation,
            context: context,
          );
        }
      }

      debugPrint(
        '✅ Commande créée pour: ${targetUser.firstName} ${targetUser.lastName}',
      );
      debugPrint('📍 Adresse utilisée: $targetAddress');

      return orderId;
    } catch (e) {
      debugPrint('Erreur création commande: $e');
      rethrow;
    }
  }

  Future<void> _updateUserAddress({
    required String userId,
    required String address,
    GeoPoint? location,
    required BuildContext context,
  }) async {
    try {
      // Utiliser set() avec merge au lieu de update()
      await _firestore.collection('users').doc(userId).set({
        'address': address,
        'location': location,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)); // ← merge: true crée OU met à jour

      // Mettre à jour localement
      final loginData = Provider.of<LoginData>(context, listen: false);
      loginData.updateUserAddress(address: address, location: location);

      debugPrint('✅ Adresse utilisateur $userId créée/mise à jour');
    } catch (e) {
      debugPrint('❌ Erreur mise à jour adresse: $e');
      // Ne pas rethrow pour ne pas bloquer la commande
    }
  }
}
