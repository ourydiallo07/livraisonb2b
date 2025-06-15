import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider_data/product_provider.dart';

class ProductDetailScreen extends StatelessWidget {
  final String productId;

  ProductDetailScreen({required this.productId});

  @override
  Widget build(BuildContext context) {
    final loadedProduct = Provider.of<ProductProvider>(
      context,
      listen: false,
    ).findById(productId);

    return Scaffold(
      appBar: AppBar(title: Text(loadedProduct.name)),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Image.network(loadedProduct.imageUrl),
            SizedBox(height: 10),
            Text('${loadedProduct.price} FCFA', style: TextStyle(fontSize: 20)),
            SizedBox(height: 10),
            Padding(
              padding: EdgeInsets.all(10),
              child: Text(
                loadedProduct.description,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
