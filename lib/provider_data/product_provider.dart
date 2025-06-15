import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:livraisonb2b/provider_data/app_data.dart';
import 'package:livraisonb2b/services/aws_services.dart';
import '../models/product.dart';

class ProductProvider with ChangeNotifier {
  final List<Product> _items = [
    Product(
      id: 'p1',
      name: 'Poulet braisé',
      description: 'Délicieux poulet braisé avec accompagnement',
      price: 5000,
      imageUrl: 'assets/images/poulet.jpg',
    ),
    Product(
      id: 'p2',
      name: 'Jus de bissap',
      description: 'Jus naturel frais et sucré',
      price: 1500,
      imageUrl: 'assets/images/jus-bissap.jpg',
    ),
    Product(
      id: 'p3',
      name: 'Oignon',
      description: 'Oignons frais pour vos plats',
      price: 1000,
      imageUrl: 'assets/images/oignon.jpg',
    ),
    Product(
      id: 'p4',
      name: 'Pomme de terre',
      description: 'Pommes de terre de qualité',
      price: 2000,
      imageUrl: 'assets/images/pomme de terre.jpg',
    ),
  ];

  List<Product> get items => [..._items];

  Stream<List<Product>> get productsStream {
    return FirebaseFirestore.instance
        .collection('products')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Product.fromFirestore(doc)).toList(),
        );
  }

  Stream<List<Product>> get combinedProductsStream {
    return productsStream.map((firestoreProducts) {
      return [..._items, ...firestoreProducts];
    });
  }

  Future<void> addProduct(
    Product product,
    File? imageFile,
    AppData appData,
  ) async {
    try {
      String? imageUrl;

      // 1. Upload vers S3 si image existe
      if (imageFile != null) {
        final imageKey =
            "PRODUCTS_IMAGES/${DateTime.now().toIso8601String()}.jpg";
        await AwsServices.uploadFile(imageFile, imageKey, appData);
        imageUrl = AwsServices.getPublicUrl(keyName: imageKey);
      }

      // 2. Enregistrer TOUTES les données dans Firestore
      final docRef = await FirebaseFirestore.instance
          .collection('products')
          .add({
            'name': product.name,
            'price': product.price,
            'description': product.description,
            'imageUrl': imageUrl,
            'createdAt': FieldValue.serverTimestamp(),
            'ownerId': FirebaseAuth.instance.currentUser?.uid,
          });

      // 3. Mettre à jour l'état local avec l'ID généré par Firestore
      final persistentProduct = product.copyWith(
        id: docRef.id, // <- Ceci est crucial
        imageUrl: imageUrl,
      );

      _items.add(persistentProduct);
      notifyListeners();
    } catch (e) {
      throw Exception("Erreur lors de l'ajout du produit: $e");
    }
  }

  Product findById(String id) {
    return _items.firstWhere((prod) => prod.id == id);
  }
}
