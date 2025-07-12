import 'package:cloud_firestore/cloud_firestore.dart';

class Order {
  final String id;
  final String userId;
  final DateTime date;
  final List<OrderItem> items;
  final double total;
  final String status; // 'pending', 'processing', 'delivered', 'cancelled'
  final String? deliveryAddress;

  Order({
    required this.id,
    required this.userId,
    required this.date,
    required this.items,
    required this.total,
    this.status = 'pending',
    this.deliveryAddress,
  });

  // Méthode copyWith
  Order copyWith({
    String? id,
    String? userId,
    DateTime? date,
    List<OrderItem>? items,
    double? total,
    String? status,
    String? deliveryAddress,
  }) {
    return Order(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      items: items ?? this.items,
      total: total ?? this.total,
      status: status ?? this.status,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
    );
  }

  // Conversion depuis Firestore
  factory Order.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Order(
      id: doc.id,
      userId: data['userId'],
      date: (data['date'] as Timestamp).toDate(),
      items:
          (data['items'] as List)
              .map((item) => OrderItem.fromMap(item))
              .toList(),
      total: data['total'],
      status: data['status'],
      deliveryAddress: data['deliveryAddress'],
    );
  }

  // Conversion vers Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'date': Timestamp.fromDate(date),
      'items': items.map((item) => item.toMap()).toList(),
      'total': total,
      'status': status,
      'deliveryAddress': deliveryAddress,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}

class OrderItem {
  final String productId;
  final String name;
  final int quantity;
  final double price;
  final String? imageUrl;

  OrderItem({
    required this.productId,
    required this.name,
    required this.quantity,
    required this.price,
    this.imageUrl,
  });

  // Conversion depuis Map
  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      productId: map['productId'],
      name: map['name'],
      quantity: map['quantity'],
      price: map['price'],
      imageUrl: map['imageUrl'],
    );
  }

  // Conversion vers Map
  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'name': name,
      'quantity': quantity,
      'price': price,
      'imageUrl': imageUrl,
    };
  }
}
