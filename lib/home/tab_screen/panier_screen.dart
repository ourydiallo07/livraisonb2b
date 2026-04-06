import 'package:flutter/material.dart';
import 'package:livraisonb2b/main_screen.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:livraisonb2b/global_utils/utils.dart';
import 'package:livraisonb2b/models/app_user.dart';
import 'package:livraisonb2b/models/CartItem.dart';
import 'package:livraisonb2b/location/location_picker.dart';
import 'package:livraisonb2b/provider_data/cart_provider.dart';
import 'package:livraisonb2b/provider_data/Login_data.dart';
import 'package:livraisonb2b/provider_data/order_provider.dart';
import 'package:livraisonb2b/account/select_recipient_screen.dart';
import 'package:livraisonb2b/constants/theme.dart';
import 'package:livraisonb2b/constants/app_errors.dart';

class PanierScreen extends StatefulWidget {
  static const String idScreen = "panier";

  const PanierScreen({super.key});

  @override
  State<PanierScreen> createState() => _PanierScreenState();
}

class _PanierScreenState extends State<PanierScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final loginData = Provider.of<LoginData>(context);
    final cartProvider = Provider.of<CartProvider>(context);
    final currentUser = loginData.currentUserApp;
    final userId = currentUser.id ?? '';

    final cartItems = cartProvider.getItems(userId);
    final totalAmount = cartProvider.getTotalAmount(userId);
    final discountDetails = cartProvider.getDiscountDetails(userId, context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Mon Panier',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (cartItems.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.white),
              onPressed:
                  () => _showClearCartDialog(context, cartProvider, userId),
              tooltip: 'Vider le panier',
            ),
        ],
      ),
      body: Column(
        children: [
          // En-tête avec statistiques
          if (cartItems.isNotEmpty)
            _buildCartHeader(discountDetails, cartItems),

          // Liste des articles
          Expanded(
            child:
                cartItems.isEmpty
                    ? _buildEmptyCart()
                    : _buildCartItems(cartItems, cartProvider, userId),
          ),

          // Pied de page avec total et bouton
          if (cartItems.isNotEmpty)
            _buildCheckoutSection(
              context,
              totalAmount,
              discountDetails,
              cartItems.length,
            ),
        ],
      ),
    );
  }

  Widget _buildCartHeader(
    Map<String, double> discountDetails,
    List<CartItem> cartItems,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppColors.backgroundWhite,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${cartItems.length} article${cartItems.length > 1 ? 's' : ''}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              Text(
                'Sous-total: ${Utils.formatPrice(discountDetails['cartTotal'] ?? 0)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (discountDetails['personalDiscount']! > 0)
            _buildDiscountRow(
              'Remise personnelle',
              -discountDetails['personalDiscount']!,
              AppColors.primaryColor,
            ),
          if (discountDetails['automaticBonus']! > 0)
            _buildDiscountRow(
              'Bonus automatique',
              -discountDetails['automaticBonus']!,
              Colors.blue,
            ),
        ],
      ),
    );
  }

  Widget _buildDiscountRow(String label, double amount, Color color) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 14, color: AppColors.textGrey),
          ),
          Text(
            Utils.formatPrice(amount),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 80,
            color: AppColors.textGrey,
          ),
          const SizedBox(height: 16),
          const Text(
            'Votre panier est vide',
            style: TextStyle(fontSize: 18, color: AppColors.textDark),
          ),
          const SizedBox(height: 8),
          Text(
            'Ajoutez des produits pour commencer',
            style: TextStyle(fontSize: 14, color: AppColors.textGrey),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text(
              'Découvrir nos produits',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItems(
    List<CartItem> cartItems,
    CartProvider cartProvider,
    String userId,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: cartItems.length,
      itemBuilder: (context, index) {
        final item = cartItems[index];
        return _buildCartItem(item, cartProvider, userId);
      },
    );
  }

  Widget _buildCartItem(
    CartItem item,
    CartProvider cartProvider,
    String userId,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.borderGrey, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Image du produit
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: AppColors.secondaryGreen,
              ),
              child:
                  item.imageUrl != null && item.imageUrl!.startsWith('http')
                      ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          item.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.shopping_basket,
                              color: AppColors.textGrey,
                            );
                          },
                        ),
                      )
                      : Icon(Icons.shopping_basket, color: AppColors.textGrey),
            ),
            const SizedBox(width: 16),

            // Détails du produit
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    Utils.formatPrice(item.price),
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (item.unit != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      item.unit!,
                      style: TextStyle(fontSize: 12, color: AppColors.textGrey),
                    ),
                  ],
                ],
              ),
            ),

            // Contrôle de quantité
            Column(
              children: [
                Row(
                  children: [
                    // Bouton diminuer
                    InkWell(
                      onTap: () {
                        if (item.quantity > 1) {
                          cartProvider.updateItemQuantity(
                            userId,
                            item.id,
                            item.quantity - 1,
                          );
                        } else {
                          _showRemoveItemDialog(
                            context,
                            cartProvider,
                            userId,
                            item,
                          );
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.borderGrey,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.remove,
                          size: 16,
                          color: AppColors.textDark,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Quantité
                    Text(
                      item.quantity.toString(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Bouton augmenter
                    InkWell(
                      onTap: () {
                        cartProvider.updateItemQuantity(
                          userId,
                          item.id,
                          item.quantity + 1,
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.primaryColor.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.add,
                          size: 16,
                          color: AppColors.primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Sous-total de l'article
                Text(
                  Utils.formatPrice(item.price * item.quantity),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckoutSection(
    BuildContext context,
    double totalAmount,
    Map<String, double> discountDetails,
    int itemCount,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Total final
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total à payer',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              Text(
                Utils.formatPrice(discountDetails['finalTotal'] ?? totalAmount),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Bouton de commande
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _isLoading ? null : () => _proceedToCheckout(context),
              child:
                  _isLoading
                      ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                      : const Text(
                        'Passer la commande',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
            ),
          ),
        ],
      ),
    );
  }

  void _proceedToCheckout(BuildContext context) async {
    final loginData = Provider.of<LoginData>(context, listen: false);
    final currentUser = loginData.currentUserApp;

    // Vérifier si l'utilisateur est un agent
    if (currentUser.isAgent == true) {
      // Proposer de choisir le destinataire
      final recipient = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const SelectRecipientScreen()),
      );

      // Vérifier si un recipient a été sélectionné
      if (recipient != null && recipient is UserApp) {
        // Continuer avec le processus de commande
        _showLocationPicker(context, recipient);
      } else {
        // L'utilisateur a annulé la sélection
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sélection annulée'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
    } else {
      // Processus normal pour les clients réguliers
      _showLocationPicker(context, currentUser);
    }
  }

  void _showLocationPicker(BuildContext context, UserApp recipient) async {
    // Options disponibles basées sur l'adresse existante
    List<Map<String, dynamic>> options = [];

    // Option 1: Utiliser l'adresse existante si disponible
    if (recipient.address != null && recipient.address!.isNotEmpty) {
      options.add({
        'type': 'existing',
        'title': 'Utiliser mon adresse habituelle',
        'address': recipient.address!,
        'location': recipient.location,
        'notes': 'Adresse habituelle du profil',
      });
    }

    // Option 2: Choisir une nouvelle adresse
    options.add({'type': 'new', 'title': 'Choisir une nouvelle adresse'});

    // Afficher le dialogue de sélection
    final selectedOption = await showDialog<Map<String, dynamic>>(
      context: context,
      builder:
          (context) => SimpleDialog(
            title: const Text('Sélectionner l\'adresse de livraison'),
            children:
                options.map((option) {
                  return SimpleDialogOption(
                    onPressed: () => Navigator.of(context).pop(option),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            option['title'],
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          if (option['type'] == 'existing') ...[
                            const SizedBox(height: 4),
                            Text(
                              option['address'],
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }).toList(),
          ),
    );

    if (selectedOption == null) return;

    Map<String, dynamic>? locationData;

    if (selectedOption['type'] == 'existing') {
      // Utiliser l'adresse existante
      locationData = {
        'address': selectedOption['address'],
        'location': selectedOption['location'],
        'notes': selectedOption['notes'],
        'useExisting': true,
      };
    } else {
      // Choisir une nouvelle adresse
      locationData = await showModalBottomSheet<Map<String, dynamic>>(
        context: context,
        isScrollControlled: true,
        builder:
            (context) => LocationPicker(
              onLocationSelected: (location) {},
              initialAddress: recipient.address,
              initialLocation: recipient.location,
            ),
      );

      if (locationData == null ||
          locationData['address'] == null ||
          locationData['address'].toString().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Veuillez sélectionner une adresse de livraison'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Demander si l'utilisateur veut sauvegarder cette adresse pour les futures commandes
      if (recipient.id ==
          Provider.of<LoginData>(context, listen: false).currentUserApp.id) {
        final saveAddress = await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('Enregistrer cette adresse ?'),
                content: const Text(
                  'Voulez-vous utiliser cette adresse pour vos futures commandes ?\n\n'
                  'Elle remplacera votre adresse actuelle.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Non, cette fois seulement'),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                    ),
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('Oui, enregistrer'),
                  ),
                ],
              ),
        );

        locationData['saveAddress'] = saveAddress == true;
      }
    }

    if (!mounted) return;

    if (locationData != null) {
      _placeOrder(context, recipient, locationData);
    }
  }

  void _placeOrder(
    BuildContext context,
    UserApp recipient,
    Map<String, dynamic> locationData,
  ) async {
    setState(() => _isLoading = true);

    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    final loginData = Provider.of<LoginData>(context, listen: false);
    final currentUser = loginData.currentUserApp;

    try {
      // Extraire les données
      String deliveryAddress = locationData['address'];
      GeoPoint? deliveryLocation = locationData['location'];
      String? deliveryNotes = locationData['notes'];
      bool saveAddress = locationData['saveAddress'] == true;
      bool useExisting = locationData['useExisting'] == true;

      // Si c'est une adresse existante, utiliser les notes par défaut
      if (useExisting) {
        deliveryNotes = 'Adresse habituelle du client';
      }

      // Validation de l'adresse
      if (deliveryAddress.isEmpty) {
        throw AppError(
          AppErrorType.invalidInput,
          message: 'Veuillez sélectionner une adresse de livraison',
        );
      }

      // Passer la commande
      final orderId = await cartProvider.validateCart(
        userId: currentUser.id!,
        orderProvider: orderProvider,
        currentUser: currentUser,
        context: context,
        deliveryAddress: deliveryAddress,
        deliveryLocation: deliveryLocation,
        deliveryNotes: deliveryNotes,
        recipientUser: recipient.id != currentUser.id ? recipient : null,
      );

      // Message de succès
      String successMessage;
      if (recipient.id == currentUser.id) {
        successMessage = 'Votre commande a été passée avec succès!';
      } else {
        successMessage =
            'Commande pour ${recipient.firstName} ${recipient.lastName} passée avec succès!';
      }

      if (saveAddress) {
        successMessage += '\nVotre adresse a été mise à jour.';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(successMessage),
            backgroundColor: AppColors.primaryColor,
            duration: const Duration(seconds: 4),
          ),
        );
      }

      // Vider le panier et retourner à l'accueil
      cartProvider.clearCart(currentUser.id!);

      if (mounted) {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil(MainScreen.idScreen, (route) => false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      debugPrint('Erreur lors de la commande: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showClearCartDialog(
    BuildContext context,
    CartProvider cartProvider,
    String userId,
  ) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text(
              'Vider le panier',
              style: TextStyle(color: AppColors.textDark),
            ),
            content: const Text(
              'Voulez-vous vraiment supprimer tous les articles de votre panier ?',
              style: TextStyle(color: AppColors.textDark),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text(
                  'Annuler',
                  style: TextStyle(color: AppColors.textGrey),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  cartProvider.clearCart(userId);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Panier vidé'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  }
                },
                child: const Text('Vider', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );
  }

  void _showRemoveItemDialog(
    BuildContext context,
    CartProvider cartProvider,
    String userId,
    CartItem item,
  ) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text(
              'Supprimer l\'article',
              style: TextStyle(color: AppColors.textDark),
            ),
            content: Text(
              'Voulez-vous supprimer "${item.name}" de votre panier ?',
              style: const TextStyle(color: AppColors.textDark),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text(
                  'Annuler',
                  style: TextStyle(color: AppColors.textGrey),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  cartProvider.removeItem(userId, item.id);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${item.name} supprimé du panier'),
                        backgroundColor: Colors.orange,
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

  @override
  void dispose() {
    _isLoading = false;
    super.dispose();
  }
}
