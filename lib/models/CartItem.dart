// models/cart_item.dart
class CartItem {
  final String id;
  final String name;
  final double price;
  final String? imageUrl;
  final String? unit;
  int quantity;

  CartItem({
    required this.id,
    required this.name,
    required this.price,
    this.imageUrl,
    this.unit,
    this.quantity = 1,
  });

  // Conversion vers Map pour Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'imageUrl': imageUrl,
      'unit': unit,
      'quantity': quantity,
    };
  }

  // Création à partir d'un Map (pour Firestore)
  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      id: map['id'] ?? map['productId'] ?? '',
      name: map['name'] ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      imageUrl: map['imageUrl'],
      unit: map['unit'],
      quantity: map['quantity'] ?? 1,
    );
  }
  CartItem copyWith({
    String? id,
    String? name,
    double? price,
    String? imageUrl,
    String? unit,
    int? quantity,
  }) {
    return CartItem(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      unit: unit ?? this.unit,
      quantity: quantity ?? this.quantity,
    );
  }
}
