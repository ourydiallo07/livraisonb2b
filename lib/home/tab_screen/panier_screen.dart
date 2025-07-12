import 'package:flutter/material.dart';
import 'package:livraisonb2b/constants/theme.dart';
import 'package:livraisonb2b/home/tab_screen/commandes_screen.dart';
import 'package:livraisonb2b/models/app_user.dart';
import 'package:livraisonb2b/provider_data/Login_data.dart';
import 'package:livraisonb2b/provider_data/cart_provider.dart';
import 'package:livraisonb2b/provider_data/order_provider.dart';
import 'package:provider/provider.dart';

class PanierScreen extends StatelessWidget {
  static const String idScreen = "panier";

  const PanierScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<LoginData>(context).currentUserApp;
    final cart = Provider.of<CartProvider>(context);
    final items = cart.getItems(user.id ?? '');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Votre Panier'),
        actions: [
          if (items.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => cart.clearCart(user.id ?? ''),
              tooltip: 'Vider le panier',
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child:
                items.isEmpty
                    ? const Center(
                      child: Text(
                        'Votre panier est vide',
                        style: TextStyle(fontSize: 18),
                      ),
                    )
                    : ListView.builder(
                      itemCount: items.length,
                      itemBuilder: (ctx, index) {
                        final item = items[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          child: ListTile(
                            leading:
                                item.imageUrl != null
                                    ? Image.network(
                                      item.imageUrl!,
                                      width: 50,
                                      height: 50,
                                      fit: BoxFit.cover,
                                    )
                                    : const Icon(
                                      Icons.shopping_basket,
                                      size: 50,
                                    ),
                            title: Text(
                              item.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              '${item.price} FCFA',
                              style: TextStyle(
                                color: AppColors.primaryGreen,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            trailing: IconButton(
                              icon: const Icon(
                                Icons.remove_circle_outline,
                                color: Colors.red,
                              ),
                              onPressed:
                                  () => cart.removeItem(user.id ?? '', item.id),
                            ),
                          ),
                        );
                      },
                    ),
          ),
          if (items.isNotEmpty) ...[
            Divider(height: 1, color: Colors.grey[300]),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${cart.getTotalAmount(user.id ?? '')} FCFA',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: AppColors.backgroundWhite,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                onPressed: () => _validateOrder(context, user, cart),
                child: const Text(
                  'Valider la commande',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _validateOrder(
    BuildContext context,
    UserApp user,
    CartProvider cart,
  ) async {
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);

    // Vérifier si l'utilisateur est valide
    if (user.id == null || user.id!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez vous connecter pour valider la commande'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Afficher un indicateur de chargement
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => Center(
            child: CircularProgressIndicator(color: AppColors.primaryGreen),
          ),
    );

    try {
      final orderId = await cart.validateCart(
        userId: user.id!,
        orderProvider: orderProvider,
      );

      // Fermer le dialogue de chargement
      Navigator.of(context).pop();

      // Afficher la confirmation
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Commande #${orderId.substring(0, 8)} validée avec succès!',
            style: TextStyle(color: AppColors.backgroundWhite),
          ),
          backgroundColor: AppColors.primaryGreen,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );

      // Naviguer vers l'écran des commandes
      Navigator.of(context).pushReplacementNamed(CommandesScreen.idScreen);
    } catch (e) {
      // Fermer le dialogue de chargement en cas d'erreur
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Erreur: ${e.toString()}',
            style: TextStyle(color: AppColors.backgroundWhite),
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }
}
