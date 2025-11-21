import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:livraisonb2b/constants/app_errors.dart';
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
      unit: '24 kg',
    ),
    Product(
      id: 'p2',
      name: 'Jus de bissap',
      description: 'Jus naturel frais et sucré',
      price: 1500,
      imageUrl: 'assets/images/jus-bissap.jpg',
      unit: '10 Kg',
    ),
    Product(
      id: 'p3',
      name: 'Oignon',
      description: 'Oignons frais pour vos plats',
      price: 1000,
      imageUrl: 'assets/images/oignon.jpg',
      unit: '13kg',
    ),
    Product(
      id: 'p4',
      name: 'Pomme de terre',
      description: 'Pommes de terre de qualité',
      price: 2000,
      imageUrl: 'assets/images/pomme de terre.jpg',
      unit: '25 kg ',
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
    String? imageKey;
    try {
      // Validation
      if (product.name.isEmpty) {
        throw AppError(
          AppErrorType.invalidInput,
          message: 'Le nom est obligatoire',
        );
      }
      if (product.price <= 0) {
        throw AppError(
          AppErrorType.invalidInput,
          message: 'Le prix doit être positif',
        );
      }
      if (product.unit == 'sac' && product.sacSize == null) {
        throw AppError(
          AppErrorType.invalidInput,
          message: 'La taille du sac est obligatoire pour les produits en sacs',
        );
      }

      String? imageUrl;
      String? imageKey;

      // Upload image si elle existe
      if (imageFile != null) {
        imageKey = "PRODUCTS_IMAGES/${DateTime.now().toIso8601String()}.jpg";
        await AwsServices.uploadFile(imageFile, imageKey, appData);
        imageUrl = AwsServices.getPublicUrl(keyName: imageKey);
      }

      // Création dans Firestore avec batch write
      final batch = FirebaseFirestore.instance.batch();
      final productRef =
          FirebaseFirestore.instance.collection('products').doc();

      batch.set(productRef, {
        'name': product.name,
        'price': product.price,
        'description': product.description,
        'imageUrl': imageUrl,
        'createdAt': FieldValue.serverTimestamp(),
        'ownerId': FirebaseAuth.instance.currentUser?.uid,
        'unit': product.unit,
        'sacSize': product.sacSize,
      });

      await batch.commit();

      // Mise à jour locale
      _items.add(product.copyWith(id: productRef.id, imageUrl: imageUrl));

      notifyListeners();
    } catch (e) {
      // Rollback en cas d'erreur
      if (imageKey != null) {
        await AwsServices.deleteFile(keyName: imageKey);
      }
      rethrow;
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
