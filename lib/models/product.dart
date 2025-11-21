import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String id;
  final String name;
  final double price;
  final String? imageUrl;
  final String? description;
  final String? category;
  final int? stock;
  final DateTime? createdAt;
  final String unit;
  final int? sacSize;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.unit,
    this.imageUrl,
    this.description,
    this.category,
    this.stock,
    this.createdAt,
    this.sacSize,
  });

  // Convertir Product en Map pour Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'imageUrl': imageUrl,
      'description': description,
      'category': category,
      'stock': stock,
      'createdAt': createdAt?.toIso8601String(),
      'unit': unit,
      'sacSize': sacSize,
    };
  }

  // Créer un Product à partir d'un Map de Firestore
  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] as String,
      name: map['name'] as String,
      price: (map['price'] as num).toDouble(),
      imageUrl: map['imageUrl'] as String?,
      description: map['description'] as String?,
      category: map['category'] as String?,
      stock: map['stock'] as int?,
      createdAt:
          map['createdAt'] != null
              ? DateTime.parse(map['createdAt'] as String)
              : null,
      unit: map['unit'] as String? ?? 'kg',
      sacSize: map['sacSize'] as int?,
    );
  }

  // Méthode pour créer un Product à partir d'un DocumentSnapshot Firestore
  factory Product.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Product(
      id: doc.id,
      name: data['name'] as String,
      price: (data['price'] as num).toDouble(),
      imageUrl: data['imageUrl'] as String?,
      description: data['description'] as String?,
      category: data['category'] as String?,
      stock: data['stock'] as int?,
      createdAt: data['createdAt']?.toDate(),
      unit: data['unit'] as String? ?? 'kg',
      sacSize: data['sacSize'] as int?,
    );
  }

  // Copier un produit avec des modifications
  Product copyWith({
    String? id,
    String? name,
    double? price,
    String? imageUrl,
    String? description,
    String? category,
    int? stock,
    DateTime? createdAt,
    String? unit,
    int? sacSize,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      description: description ?? this.description,
      category: category ?? this.category,
      stock: stock ?? this.stock,
      createdAt: createdAt ?? this.createdAt,
      unit: unit ?? this.unit,
      sacSize: sacSize ?? this.sacSize,
    );
  }

  @override
  String toString() {
    return 'Product(id: $id, name: $name, price: $price, imageUrl: $imageUrl,unit: $unit, sacSize: $sacSize)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Product &&
        other.id == id &&
        other.name == name &&
        other.price == price &&
        other.imageUrl == imageUrl &&
        other.description == description &&
        other.category == category &&
        other.stock == stock &&
        other.createdAt == createdAt &&
        other.unit == unit &&
        other.sacSize == sacSize;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        price.hashCode ^
        imageUrl.hashCode ^
        description.hashCode ^
        category.hashCode ^
        stock.hashCode ^
        createdAt.hashCode ^
        unit.hashCode ^
        sacSize.hashCode;
  }
}
