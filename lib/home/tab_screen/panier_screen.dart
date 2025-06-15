// lib/home/tab_screen/panier_screen.dart
import 'package:flutter/material.dart';
import 'package:livraisonb2b/provider_data/cart_provider.dart';
import 'package:provider/provider.dart';

class PanierScreen extends StatelessWidget {
  static const String idScreen = "panier";

  const PanierScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Votre Panier'),
        actions: [
          if (cart.items.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: cart.clearCart,
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child:
                cart.items.isEmpty
                    ? const Center(child: Text('Panier vide'))
                    : ListView.builder(
                      itemCount: cart.items.length,
                      itemBuilder: (ctx, index) {
                        final item = cart.items[index];
                        return ListTile(
                          leading:
                              item.imageUrl != null
                                  ? Image.network(item.imageUrl!, width: 50)
                                  : const Icon(Icons.fastfood),
                          title: Text(item.name),
                          subtitle: Text('${item.price} FCFA'),
                          trailing: IconButton(
                            icon: const Icon(Icons.remove),
                            onPressed: () => cart.removeItem(item.id),
                          ),
                        );
                      },
                    ),
          ),
          if (cart.items.isNotEmpty)
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
                    '${cart.totalAmount} FCFA',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
          if (cart.items.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
                onPressed: () {
                  // TODO: Implémenter la validation du panier
                },
                child: const Text('Valider la commande'),
              ),
            ),
        ],
      ),
    );
  }
}
