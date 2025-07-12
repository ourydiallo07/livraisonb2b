import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider_data/product_provider.dart';

class ProductDetailScreen extends StatelessWidget {
  final String productId;

  const ProductDetailScreen({Key? key, required this.productId})
    : super(key: key);

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
            if (loadedProduct.imageUrl != null)
              Image.network(loadedProduct.imageUrl!),
            const SizedBox(height: 10),
            Text(
              '${loadedProduct.price} FCFA',
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Text(
                loadedProduct.description ?? 'Pas de description',
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
