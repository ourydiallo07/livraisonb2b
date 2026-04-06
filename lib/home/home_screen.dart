import 'package:flutter/material.dart';
import 'package:livraisonb2b/account/product_detail_screen.dart';
import 'package:livraisonb2b/global_utils/utils.dart';
import 'package:livraisonb2b/models/product.dart';
import 'package:livraisonb2b/provider_data/Login_data.dart';
import 'package:livraisonb2b/provider_data/app_data.dart';
import 'package:livraisonb2b/provider_data/cart_provider.dart';
import 'package:livraisonb2b/provider_data/product_provider.dart';
import 'package:livraisonb2b/account/add_product_screen.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatelessWidget {
  static const String idScreen = "home";
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loginData = Provider.of<LoginData>(context);
    final lastName = loginData.currentUserApp.lastName ?? "";
    final productProvider = Provider.of<ProductProvider>(
      context,
      listen: false,
    );
    final cartProvider = Provider.of<CartProvider>(context, listen: false);

    return Scaffold(
      backgroundColor: Colors.green.shade800, // fond général vert foncé
      body: Column(
        children: [
          // ==================== Section haut (Bonjour + Recherche) ====================
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 40, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Bonjour $lastName 👋",
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                // Barre de recherche capsule
                _buildSearchBar(context, productProvider),
              ],
            ),
          ),

          // ==================== Carte blanche flottante ====================
          Expanded(
            child: Stack(
              children: [
                // Fond de la carte blanche
                Container(
                  margin: const EdgeInsets.only(top: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(
                          0,
                          -3,
                        ), // ombre légèrement vers le haut
                      ),
                    ],
                  ),
                ),

                // Contenu : GridView des produits
                Padding(
                  padding: const EdgeInsets.only(
                    top: 30,
                  ), // espace pour arrondi
                  child: StreamBuilder<List<Product>>(
                    stream: productProvider.combinedProductsStream,
                    builder: (ctx, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(child: Text("Erreur: ${snapshot.error}"));
                      }

                      final products = snapshot.data ?? [];

                      if (products.isEmpty) {
                        return const Center(
                          child: Text("Aucun produit disponible"),
                        );
                      }

                      return GridView.builder(
                        padding: const EdgeInsets.all(10),
                        itemCount: products.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 3 / 4,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                            ),
                        itemBuilder:
                            (ctx, i) => _buildProductCard(
                              context: context,
                              product: products[i],
                              productProvider: productProvider,
                              cartProvider: cartProvider,
                            ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (ctx) => const AddProductScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSearchBar(
    BuildContext context,
    ProductProvider productProvider,
  ) {
    return Container(
      height: 50,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300, width: 1),
      ),
      child: Row(
        children: [
          // Icône de recherche à gauche comme le code pays
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: const Icon(Icons.search, color: Colors.grey, size: 22),
          ),
          // Champ de texte
          Expanded(
            child: TextField(
              onChanged: (value) {
                ;
              },
              style: const TextStyle(fontSize: 16),
              decoration: const InputDecoration(
                hintText: "Rechercher un produit...",
                hintStyle: TextStyle(color: Colors.grey),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard({
    required BuildContext context,
    required Product product,
    required ProductProvider productProvider,
    required CartProvider cartProvider,
  }) {
    final userId =
        Provider.of<LoginData>(context, listen: false).currentUserApp.id ?? '';
    return GestureDetector(
      onTap:
          () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProductDetailScreen(productId: product.id),
            ),
          ),
      child: Card(
        elevation: 5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // IMAGE AGRANDIE
                Expanded(
                  flex: 8, // Réduit à 8 au lieu de 10 pour équilibrer
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(10),
                      topRight: Radius.circular(10),
                    ),
                    child:
                        product.imageUrl != null &&
                                product.imageUrl!.startsWith('http')
                            ? Image.network(
                              product.imageUrl!,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            )
                            : Image.asset(
                              product.imageUrl ?? '',
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                  ),
                ),
                // CONTENU TEXTUEL - réorganisé pour éviter le débordement
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min, // Important
                    children: [
                      Text(
                        product.name,
                        style: const TextStyle(
                          fontSize: 16, // Légèrement réduit
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        product.description ?? '',
                        style: const TextStyle(fontSize: 12), // Réduit
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            product.unit,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.green,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (product.sacSize != null) ...[
                            const SizedBox(width: 8),
                            Text(
                              '${product.sacSize}kg',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.green,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),

                      Container(
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          Utils.formatPrice(product.price),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // Boutons positionnés (inchangés)
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () {
                  cartProvider.addItem(userId, product);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${product.name} ajouté au panier'),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.add, color: Colors.blue, size: 20),
                ),
              ),
            ),
            Positioned(
              top: 8,
              left: 8,
              child: GestureDetector(
                onTap:
                    () => _showDeleteDialog(context, product, productProvider),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.delete, color: Colors.red, size: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(
    BuildContext context,
    Product product,
    ProductProvider productProvider,
  ) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Confirmer la suppression'),
            content: Text('Voulez-vous vraiment supprimer "${product.name}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Annuler'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.of(ctx).pop();
                  try {
                    final appData = Provider.of<AppData>(
                      context,
                      listen: false,
                    );
                    await productProvider.deleteProduct(product.id, appData);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${product.name} supprimé avec succès'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Erreur: ${e.toString().replaceFirst('Exception: ', '')}',
                        ),
                        duration: const Duration(seconds: 2),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                child: const Text(
                  'Supprimer',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
  }
}
