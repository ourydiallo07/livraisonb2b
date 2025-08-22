import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:livraisonb2b/constants/theme.dart';
import 'package:livraisonb2b/home/tab_screen/commandes_screen.dart';
import 'package:livraisonb2b/location/location_picker.dart';
import 'package:livraisonb2b/models/CartItem.dart';
import 'package:livraisonb2b/models/app_user.dart';
import 'package:livraisonb2b/provider_data/Login_data.dart';
import 'package:livraisonb2b/provider_data/cart_provider.dart';
import 'package:livraisonb2b/provider_data/order_provider.dart';
import 'package:provider/provider.dart';
import 'package:livraisonb2b/global_utils/utils.dart';

class PanierScreen extends StatefulWidget {
  static const String idScreen = "panier";

  const PanierScreen({super.key});

  @override
  State<PanierScreen> createState() => _PanierScreenState();
}

class _PanierScreenState extends State<PanierScreen> {
  @override
  Widget build(BuildContext context) {
    final user = Provider.of<LoginData>(context).currentUserApp;
    final cart = Provider.of<CartProvider>(context);
    final items = cart.getItems(user.id ?? '');
    final discountDetails = cart.getDiscountDetails(user.id ?? '', context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon Panier'),
        backgroundColor: AppColors.primaryGreen,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withOpacity(0.1),
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200, width: 1),
              ),
            ),
            child: Center(
              child: Text(
                items.isEmpty
                    ? 'Votre panier est vide'
                    : '${items.length} ${items.length > 1 ? 'articles' : 'article'}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Expanded(
            child:
                items.isEmpty
                    ? _buildEmptyCart()
                    : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: items.length,
                      separatorBuilder:
                          (context, index) => const SizedBox(height: 12),
                      itemBuilder:
                          (ctx, index) => _buildCartItemCard(
                            context,
                            user,
                            cart,
                            items[index],
                          ),
                    ),
          ),
          if (items.isNotEmpty)
            _buildOrderSummary(context, user, cart, discountDetails),
        ],
      ),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.shopping_cart_outlined,
            size: 60,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun article dans votre panier',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              // Naviguer vers l'écran des produits
            },
            child: const Text('Parcourir les produits'),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItemCard(
    BuildContext context,
    UserApp user,
    CartProvider cart,
    CartItem item,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey.shade100,
                  ),
                  child:
                      item.imageUrl != null
                          ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              item.imageUrl!,
                              fit: BoxFit.cover,
                            ),
                          )
                          : Icon(
                            Icons.shopping_basket,
                            size: 40,
                            color: Colors.grey.shade400,
                          ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      const SizedBox(height: 4),
                      Text(
                        Utils.formatPrice(item.price),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: Colors.grey.shade500),
                  onPressed: () => cart.removeItem(user.id ?? '', item.id),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove, size: 18),
                        onPressed:
                            item.quantity > 1
                                ? () => cart.updateItemQuantity(
                                  user.id ?? '',
                                  item.id,
                                  item.quantity - 1,
                                )
                                : null,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(item.quantity.toString()),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add, size: 18),
                        onPressed:
                            () => cart.updateItemQuantity(
                              user.id ?? '',
                              item.id,
                              item.quantity + 1,
                            ),
                      ),
                    ],
                  ),
                ),
                Text(
                  (Utils.formatPrice(item.price * item.quantity)),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSummary(
    BuildContext context,
    UserApp user,
    CartProvider cart,
    Map<String, double> discountDetails,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade300, width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          Column(
            children: [
              _buildSummaryRow(
                'Total articles',
                Utils.formatPrice(discountDetails['cartTotal'] ?? 0),
              ),
              if ((discountDetails['personalDiscount'] ?? 0) > 0)
                _buildSummaryRow(
                  'Remise personnelle (${user.personalDiscount?.toStringAsFixed(0)}%)',
                  '-${Utils.formatPrice(discountDetails['personalDiscount'] ?? 0)}',
                  isDiscount: true,
                ),
              if ((discountDetails['automaticBonus'] ?? 0) > 0)
                _buildSummaryRow(
                  'Bonus (${user.bonusRate?.toStringAsFixed(0)}% > ${user.bonusThreshold?.toStringAsFixed(0)} FG)',
                  '+${Utils.formatPrice(discountDetails['automaticBonus'] ?? 0)}',
                  isBonus: true,
                ),
              const Divider(height: 24),
              _buildSummaryRow(
                'Total à payer',
                Utils.formatPrice(discountDetails['finalTotal'] ?? 0),
                isTotal: true,
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => _validateOrder(context, user, cart),
              child: const Text(
                'Valider la commande',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value, {
    bool isTotal = false,
    bool isDiscount = false,
    bool isBonus = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              color: isTotal ? Colors.black : Colors.grey.shade700,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 18 : 14,
              color:
                  isTotal
                      ? AppColors.primaryGreen
                      : isDiscount
                      ? Colors.red
                      : isBonus
                      ? Colors.green
                      : Colors.black,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _validateOrder(
    BuildContext context,
    UserApp user,
    CartProvider cart,
  ) async {
    // 1. Vérification des informations client
    if (user.phone == null || user.phone!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez compléter votre numéro de téléphone'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // 2. ✅ UTILISER DIRECTEMENT LA DERNIÈRE ADRESSE SI ELLE EXISTE
    if (user.address != null &&
        user.address!.isNotEmpty &&
        user.location != null) {
      _processOrderWithSavedAddress(context, user, cart);
      return;
    }

    // 3. Sinon, demander une nouvelle adresse
    _requestNewAddress(context, user, cart);
  }

  Future<void> _processOrderWithSavedAddress(
    BuildContext context,
    UserApp user,
    CartProvider cart,
  ) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final discountDetails = cart.getDiscountDetails(user.id ?? '', context);
      final totalToPay = discountDetails['finalTotal'] ?? 0;

      // ✅ UTILISER L'ADRESSE SAUVEGARDÉE
      final orderId = await cart.validateCart(
        userId: user.id!,
        orderProvider: Provider.of<OrderProvider>(context, listen: false),
        currentUser: user,
        context: context,
        deliveryAddress: user.address!, // Adresse sauvegardée
        deliveryLocation: user.location!, // Localisation sauvegardée
        deliveryNotes: 'Même adresse que la précédente commande',
      );

      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Commande #${orderId.substring(0, 8)} validée !',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: AppColors.primaryGreen,
          duration: const Duration(seconds: 3),
        ),
      );

      Navigator.pushNamed(context, CommandesScreen.idScreen);
    } catch (e) {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  Future<void> _requestNewAddress(
    BuildContext context,
    UserApp user,
    CartProvider cart,
  ) async {
    final locationData = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      builder:
          (ctx) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: LocationPicker(
              initialAddress: user.address,
              initialLocation: user.location,
              onLocationSelected: (selectedLocation) {},
            ),
          ),
    );

    if (locationData == null || locationData['address'] == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner une adresse valide'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      GeoPoint? deliveryGeoPoint;
      if (locationData['location'] != null) {
        deliveryGeoPoint = GeoPoint(
          locationData['location']['lat'],
          locationData['location']['lng'],
        );
      }

      final discountDetails = cart.getDiscountDetails(user.id ?? '', context);
      final totalToPay = discountDetails['finalTotal'] ?? 0;

      final orderId = await cart.validateCart(
        userId: user.id!,
        orderProvider: Provider.of<OrderProvider>(context, listen: false),
        currentUser: user,
        context: context,
        deliveryAddress: locationData['address'],
        deliveryLocation: deliveryGeoPoint,
        deliveryNotes: locationData['notes'],
      );

      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Commande #${orderId.substring(0, 8)} validée !',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: AppColors.primaryGreen,
          duration: const Duration(seconds: 3),
        ),
      );

      Navigator.pushNamed(context, CommandesScreen.idScreen);
    } catch (e) {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }
}
