import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:flutter/material.dart';
import 'package:livraisonb2b/constants/order_status.dart';
import 'package:livraisonb2b/models/order.dart';

class OrderProvider with ChangeNotifier {
  final firestore.FirebaseFirestore _firestore =
      firestore.FirebaseFirestore.instance;
  List<Order> _orders = [];

  List<Order> get orders => [..._orders];

  // Add this new method for admin screen
  Stream<List<Order>> getAllOrders() {
    return _firestore
        .collection('orders')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(Order.fromFirestore).toList());
  }

  Future<void> fetchUserOrders(String userId) async {
    try {
      final snapshot =
          await _firestore
              .collection('orders')
              .where('userId', isEqualTo: userId)
              .orderBy('createdAt', descending: true)
              .get();

      _orders = snapshot.docs.map((doc) => Order.fromFirestore(doc)).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching orders: $e');
    }
  }

  Stream<List<Order>> getOrdersStream(String userId) {
    return _firestore
        .collection('orders')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(Order.fromFirestore).toList());
  }

  Future<String> createOrder({
    required String userId,
    required List<OrderItem> items,
    required String userfirstName,
    required String userlastName,
    required String userphone,
    required double total,
    String? deliveryAddress,
    firestore.GeoPoint? deliveryLocation,
    String? deliveryNotes, // Ajouté
  }) async {
    try {
      final docRef = await _firestore.collection('orders').add({
        'userId': userId,
        'userfirstName': userfirstName,
        'userlastName': userlastName,
        'userphone': userphone,
        'items': items.map((item) => item.toMap()).toList(),
        'total': total,
        'status': 'pending',
        'deliveryAddress': deliveryAddress,
        'deliveryLocation': deliveryLocation, // Ajouté
        'deliveryNotes': deliveryNotes, // Ajouté
        'createdAt': firestore.FieldValue.serverTimestamp(),
        'viewedByAdmin': false,
      });

      await _notifyAdmins(docRef.id);
      return docRef.id;
    } catch (e) {
      debugPrint('Error creating order: $e');
      rethrow;
    }
  }

  Future<void> _notifyAdmins(String orderId) async {
    try {
      // 1. Récupérer tous les administrateurs
      final admins =
          await _firestore
              .collection('users')
              .where('isAdmin', isEqualTo: true)
              .get();

      // 2. Pour chaque admin, créer une notification
      for (var admin in admins.docs) {
        await _firestore.collection('notifications').add({
          'userId': admin.id,
          'orderId': orderId,
          'type': 'new_order',
          'read': false,
          'createdAt': firestore.FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint('Error notifying admins: $e');
    }
  }

  // Récupère toutes les commandes expédiées (visibles par tous les livreurs)
  Stream<List<Order>> getAllShippedOrders() {
    return _firestore
        .collection('orders')
        .where('status', isEqualTo: OrderStatus.shipped)
        .where('isVisibleToDelivery', isEqualTo: true)
        .orderBy('shippedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(Order.fromFirestore).toList());
  }

  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    try {
      final updateData = <String, dynamic>{'status': newStatus};

      // Si le statut est "shipped", rendre visible à TOUS les livreurs
      if (newStatus == OrderStatus.shipped) {
        updateData['isVisibleToDelivery'] = true;
        updateData['shippedAt'] = firestore.FieldValue.serverTimestamp();
        // On ne assigne PAS de livreur spécifique - visible par tous
      }

      // Si le statut est "delivered", enregistrer la date de livraison
      if (newStatus == OrderStatus.delivered) {
        updateData['deliveredAt'] = firestore.FieldValue.serverTimestamp();
      }

      await _firestore.collection('orders').doc(orderId).update(updateData);

      // Update local state
      final index = _orders.indexWhere((order) => order.id == orderId);
      if (index >= 0) {
        _orders[index] = _orders[index].copyWith(
          status: newStatus,
          isVisibleToDelivery:
              newStatus == OrderStatus.shipped
                  ? true
                  : _orders[index].isVisibleToDelivery,
          shippedAt:
              newStatus == OrderStatus.shipped
                  ? DateTime.now()
                  : _orders[index].shippedAt,
          deliveredAt:
              newStatus == OrderStatus.delivered
                  ? DateTime.now()
                  : _orders[index].deliveredAt,
        );
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating order status: $e');
      rethrow;
    }
  }

  // Nouvelle méthode pour récupérer les commandes visibles par les livreurs
  Stream<List<Order>> getOrdersForDelivery() {
    return _firestore
        .collection('orders')
        .where('isVisibleToDelivery', isEqualTo: true)
        .where('status', whereIn: [OrderStatus.shipped, OrderStatus.processing])
        .orderBy('shippedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(Order.fromFirestore).toList());
  }

  // Méthode pour marquer une commande comme livrée
  Future<void> markAsDelivered(String orderId) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'status': OrderStatus.delivered,
        'deliveredAt': firestore.FieldValue.serverTimestamp(),
      });

      // Update local state
      final index = _orders.indexWhere((order) => order.id == orderId);
      if (index >= 0) {
        _orders[index] = _orders[index].copyWith(
          status: OrderStatus.delivered,
          deliveredAt: DateTime.now(),
        );
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error marking order as delivered: $e');
      rethrow;
    }
  }

  // Dans la classe OrderProvider
  Stream<List<Order>> getOrdersForDeliveryMan(String deliveryManId) {
    return _firestore
        .collection('orders')
        .where('isVisibleToDelivery', isEqualTo: true)
        .where('status', whereIn: [OrderStatus.shipped, OrderStatus.delivered])
        .orderBy('shippedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(Order.fromFirestore).toList());
  }

  Future<Map<String, int>> getOrdersCountByStatus() async {
    try {
      final snapshot = await _firestore.collection('orders').get();
      final counts = <String, int>{};

      for (var doc in snapshot.docs) {
        final status = doc['status'] as String? ?? 'unknown';
        counts[status] = (counts[status] ?? 0) + 1;
      }

      return counts;
    } catch (e) {
      debugPrint('Error getting orders count by status: $e');
      return {};
    }
  }

  Future<int> getTotalOrdersCount() async {
    try {
      final snapshot = await _firestore.collection('orders').count().get();
      return snapshot.count ?? 0;
    } catch (e) {
      debugPrint('Error getting total orders count: $e');
      return 0;
    }
  }

  Future<List<Map<String, dynamic>>> getRecentOrders(int limit) async {
    try {
      final snapshot =
          await _firestore
              .collection('orders')
              .orderBy('createdAt', descending: true)
              .limit(limit)
              .get();

      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      debugPrint('Error getting recent orders: $e');
      return [];
    }
  }
}
