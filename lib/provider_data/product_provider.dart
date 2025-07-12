import 'dart:io';

import 'package:amplify_flutter/amplify_flutter.dart';
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

  Future<void> deleteProduct(String productId, AppData appData) async {
    try {
      appData.updateS3StateUploading(true);

      // 1. Trouver le produit dans la liste locale (version null-safe)
      Product? productToDelete;
      try {
        productToDelete = _items.cast<Product?>().firstWhere(
          (p) => p?.id == productId,
          orElse: () => null,
        );
      } catch (e) {
        debugPrint('Erreur recherche locale: $e');
      }

      // 2. Supprimer l'image S3 si elle existe
      if (productToDelete?.imageUrl != null &&
          productToDelete!.imageUrl!.startsWith('http')) {
        await _deleteProductImage(productToDelete.imageUrl!);
      }

      // 3. Supprimer de Firestore (tous les produits sauf locaux)
      if (!productId.startsWith('p')) {
        try {
          await FirebaseFirestore.instance
              .collection('products')
              .doc(productId)
              .delete();
          debugPrint('$productId supprimé de Firestore');
        } on FirebaseException catch (e) {
          debugPrint('Erreur Firestore: ${e.message}');
        }
      }

      // 4. Supprimer de la liste locale
      _items.removeWhere((item) => item.id == productId);
      notifyListeners();
    } catch (e) {
      debugPrint('Erreur globale: $e');
      throw Exception('Échec de la suppression: ${e.toString()}');
    } finally {
      appData.updateS3StateUploading(false);
    }
  }

  Future<void> _deleteProductImage(String imageUrl) async {
    try {
      // Extraire le keyName de l'URL S3
      final prefixToRemove =
          'https://${AwsServices.bucketName}.s3.${AwsServices.region}.amazonaws.com/';
      if (imageUrl.startsWith(prefixToRemove)) {
        final keyName = imageUrl.substring(prefixToRemove.length);
        await AwsServices.deleteFile(keyName: keyName);
      }
    } catch (e) {
      debugPrint('Erreur lors de la suppression de l\'image: $e');
    }
  }

  bool _isFirestoreProduct(String productId) {
    // Considère maintenant que tous les produits peuvent être dans Firestore
    return true;
  }

  // Méthode pour mettre à jour un produit
  Future<void> updateProduct(
    String productId,
    Product newProduct,
    File? newImageFile,
    AppData appData,
  ) async {
    try {
      appData.updateS3StateUploading(true);

      final productIndex = _items.indexWhere((prod) => prod.id == productId);
      if (productIndex >= 0) {
        String? imageUrl = _items[productIndex].imageUrl;

        // Gérer la nouvelle image si fournie
        if (newImageFile != null) {
          // Supprimer l'ancienne image si elle existe
          if (imageUrl != null && imageUrl.startsWith('http')) {
            await _deleteProductImage(imageUrl);
          }

          // Uploader la nouvelle image
          final imageKey =
              "PRODUCTS_IMAGES/${DateTime.now().toIso8601String()}.jpg";
          await AwsServices.uploadFile(newImageFile, imageKey, appData);
          imageUrl = AwsServices.getPublicUrl(keyName: imageKey);
        }

        // Mettre à jour dans Firestore si c'est un produit Firestore
        if (_isFirestoreProduct(productId)) {
          await FirebaseFirestore.instance
              .collection('products')
              .doc(productId)
              .update({
                'name': newProduct.name,
                'price': newProduct.price,
                'description': newProduct.description,
                'imageUrl': imageUrl,
              });
        }

        // Mettre à jour localement
        _items[productIndex] = newProduct.copyWith(
          id: productId,
          imageUrl: imageUrl,
        );

        notifyListeners();
      }
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour du produit: $e');
    } finally {
      appData.updateS3StateUploading(false);
    }
  }
}
