import 'package:cloud_firestore/cloud_firestore.dart';

class Order {
  final String id;
  final String userId;
  final String userfirstName;
  final String userlastName;
  final String userphone;
  final DateTime? date;
  final List<OrderItem> items;
  final double total;
  final String status; // 'pending', 'processing', 'delivered', 'cancelled'
  final GeoPoint? deliveryLocation;
  final String? deliveryAddress;
  final String? deliveryNotes;
  final String? assignedDeliveryManId;
  final String? assignedDeliveryManName;
  final DateTime? assignedAt;
  final DateTime? deliveredAt;

  final bool isVisibleToDelivery; // Nouveau champ
  final DateTime? shippedAt; // Nouveau champ

  Order({
    required this.id,
    required this.userId,
    required this.userfirstName,
    required this.userlastName,
    required this.userphone,
    required this.date,
    required this.items,
    required this.total,
    this.deliveryLocation,
    this.deliveryAddress,
    this.deliveryNotes,
    this.assignedDeliveryManId,
    this.assignedDeliveryManName,
    this.assignedAt,
    this.deliveredAt,
    this.shippedAt,
    this.isVisibleToDelivery = false,
    this.status = 'pending',
  });

  double getTotalWeight() {
    double totalWeight = 0.0;

    for (final item in items) {
      if (item.unit == 'sac' || item.unit?.contains('sac') == true) {
        final sacWeight = item.sacSize?.toDouble() ?? 25.0;
        totalWeight += item.quantity * sacWeight;
      } else {
        totalWeight += item.quantity.toDouble();
      }
    }

    return totalWeight;
  }

  // Méthode copyWith
  Order copyWith({
    String? id,
    String? userId,
    String? userfirstName,
    String? userlastName,
    String? userphone,
    DateTime? date,
    List<OrderItem>? items,
    double? total,
    String? status,
    GeoPoint? deliveryLocation,
    String? deliveryAddress,
    String? deliveryNotes,
    String? assignedDeliveryManId,
    String? assignedDeliveryManName,
    DateTime? assignedAt,
    DateTime? deliveredAt,
    DateTime? shippedAt,
    bool? isVisibleToDelivery,
  }) {
    return Order(
      id: id ?? this.id,
      userfirstName: userfirstName ?? this.userfirstName,
      userlastName: userlastName ?? this.userlastName,
      userphone: userphone ?? this.userphone,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      items: items ?? this.items,

      deliveryLocation: deliveryLocation ?? this.deliveryLocation,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      deliveryNotes: deliveryNotes ?? this.deliveryNotes,
      total: total ?? this.total,
      status: status ?? this.status,

      assignedDeliveryManId:
          assignedDeliveryManId ?? this.assignedDeliveryManId,
      assignedDeliveryManName:
          assignedDeliveryManName ?? this.assignedDeliveryManName,
      assignedAt: assignedAt ?? this.assignedAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      shippedAt: shippedAt ?? this.shippedAt,
      isVisibleToDelivery: isVisibleToDelivery ?? this.isVisibleToDelivery,
    );
  }

  // Conversion depuis Firestore
  factory Order.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Order(
      id: doc.id,
      userfirstName: data['userfirstName'] ?? '', // Ajouté
      userlastName: data['userlastName'] ?? '', // Ajouté
      userphone: data['userphone'] ?? '', // Ajouté

      userId: data['userId'] ?? '',
      date:
          data['createdAt'] != null
              ? (data['createdAt'] as Timestamp).toDate()
              : DateTime.now(), // Valeur par défaut
      items:
          (data['items'] as List? ?? [])
              .map((item) => OrderItem.fromMap(item))
              .toList(),
      total: (data['total'] as num?)?.toDouble() ?? 0.0,
      status: data['status'] ?? 'pending',

      deliveryLocation: data['deliveryLocation'] as GeoPoint?,
      deliveryAddress: data['deliveryAddress'],
      deliveryNotes: data['deliveryNotes'],

      assignedDeliveryManId: data['assignedDeliveryManId'],
      assignedDeliveryManName: data['assignedDeliveryManName'],
      assignedAt:
          data['assignedAt'] != null
              ? (data['assignedAt'] as Timestamp).toDate()
              : null,
      deliveredAt:
          data['deliveredAt'] != null
              ? (data['deliveredAt'] as Timestamp).toDate()
              : null,
      shippedAt:
          data['shippedAt'] !=
                  null // Ajouté
              ? (data['shippedAt'] as Timestamp).toDate()
              : null,
      isVisibleToDelivery: data['isVisibleToDelivery'] ?? false,
    );
  }

  // Conversion vers Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'userfirstName': userfirstName, // Ajouté
      'userlastName': userlastName, // Ajouté
      'userphone': userphone, // Ajouté

      'items': items.map((item) => item.toMap()).toList(),
      'total': total,
      'status': status,

      'deliveryLocation': deliveryLocation,
      'deliveryAddress': deliveryAddress,
      'deliveryNotes': deliveryNotes,
      'assignedDeliveryManId': assignedDeliveryManId,
      'assignedDeliveryManName': assignedDeliveryManName,
      'assignedAt': assignedAt != null ? Timestamp.fromDate(assignedAt!) : null,
      'deliveredAt':
          deliveredAt != null ? Timestamp.fromDate(deliveredAt!) : null,

      'createdAt': FieldValue.serverTimestamp(),
      'shippedAt':
          shippedAt != null ? Timestamp.fromDate(shippedAt!) : null, // Ajouté
      'isVisibleToDelivery': isVisibleToDelivery,
    };
  }
}

class OrderItem {
  final String productId;
  final String name;
  final int quantity;
  final double price;
  final String? imageUrl;
  final String unit;
  final int? sacSize;

  OrderItem({
    required this.productId,
    required this.name,
    required this.quantity,
    required this.price,
    this.imageUrl,
    required this.unit,
    this.sacSize,
  });

  // Conversion depuis Map
  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      productId: map['productId'],
      name: map['name'],
      quantity: map['quantity'],
      price: map['price'],
      imageUrl: map['imageUrl'],
      unit: map['unit'] ?? 'kg',
      sacSize: map['sacSize'],
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
      'unit': unit,
      'sacSize': sacSize,
    };
  }
}
