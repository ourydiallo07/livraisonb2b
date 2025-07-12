import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:flutter/material.dart';
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
    required double total,
    String? deliveryAddress,
  }) async {
    try {
      final docRef = await _firestore.collection('orders').add({
        'userId': userId,
        'items': items.map((item) => item.toMap()).toList(),
        'total': total,
        'status': 'pending',
        'deliveryAddress': deliveryAddress,
        'createdAt': firestore.FieldValue.serverTimestamp(),
      });

      return docRef.id;
    } catch (e) {
      debugPrint('Error creating order: $e');
      rethrow;
    }
  }

  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'status': newStatus,
      });

      // Update local state
      final index = _orders.indexWhere((order) => order.id == orderId);
      if (index >= 0) {
        _orders[index] = _orders[index].copyWith(status: newStatus);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating order status: $e');
    }
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
