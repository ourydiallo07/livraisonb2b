import 'package:flutter/material.dart';
import 'package:livraisonb2b/constants/order_status.dart';
import 'package:livraisonb2b/main_screen.dart';
import 'package:livraisonb2b/provider_data/Login_data.dart';
import 'package:livraisonb2b/services/auth_service.dart';
import 'package:provider/provider.dart';
import 'package:livraisonb2b/models/order.dart';
import 'package:livraisonb2b/provider_data/order_provider.dart';
import 'package:livraisonb2b/constants/theme.dart';
import 'package:livraisonb2b/global_utils/utils.dart';
import 'package:intl/intl.dart';

class DeliveryMainScreen extends StatefulWidget {
  static const String idScreen = "DeliveryMainScreen";

  const DeliveryMainScreen({super.key});

  @override
  State<DeliveryMainScreen> createState() => _DeliveryMainScreenState();
}

class _DeliveryMainScreenState extends State<DeliveryMainScreen>
    with SingleTickerProviderStateMixin {
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy HH:mm');
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _confirmLogout() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Déconnexion'),
          content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(
                'Déconnexion',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      await _performLogout();
    }
  }

  // Méthode pour effectuer la déconnexion avec AuthService
  Future<void> _performLogout() async {
    try {
      // Utilisation directe de la méthode statique
      await AuthService.signOutAppUser();

      final loginData = Provider.of<LoginData>(context, listen: false);

      Navigator.pushNamedAndRemoveUntil(
        context,
        MainScreen.idScreen,
        (route) => false,
      );

      // Message de confirmation
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Déconnexion réussie'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la déconnexion: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = Provider.of<LoginData>(context).currentUserApp;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Livraisons'),
        backgroundColor: AppColors.primaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _confirmLogout,
            tooltip: 'Deconnexion',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.pending_actions), text: 'À Livrer'),
            Tab(icon: Icon(Icons.check_circle), text: 'Livrées'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Onglet 1: Commandes à livrer
          _buildPendingDeliveries(currentUser.id!),

          // Onglet 2: Commandes livrées
          _buildDeliveredOrders(currentUser.id!),
        ],
      ),
    );
  }

  Widget _buildPendingDeliveries(String deliveryManId) {
    return StreamBuilder<List<Order>>(
      stream: Provider.of<OrderProvider>(context)
          .getOrdersForDeliveryMan(deliveryManId)
          .map(
            (orders) =>
                orders
                    .where((order) => order.status == OrderStatus.shipped)
                    .toList(),
          ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Erreur: ${snapshot.error}'));
        }

        final orders = snapshot.data ?? [];
        if (orders.isEmpty) {
          return _buildEmptyState(
            icon: Icons.local_shipping,
            message: 'Aucune commande à livrer',
            subtitle: 'Les commandes expédiées apparaîtront ici',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: orders.length,
          itemBuilder:
              (context, index) => _buildDeliveryCard(orders[index], false),
        );
      },
    );
  }

  Widget _buildDeliveredOrders(String deliveryManId) {
    return StreamBuilder<List<Order>>(
      stream: Provider.of<OrderProvider>(context)
          .getOrdersForDeliveryMan(deliveryManId)
          .map(
            (orders) =>
                orders
                    .where((order) => order.status == OrderStatus.delivered)
                    .toList(),
          ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Erreur: ${snapshot.error}'));
        }

        final orders = snapshot.data ?? [];
        if (orders.isEmpty) {
          return _buildEmptyState(
            icon: Icons.inventory_2,
            message: 'Aucune commande livrée',
            subtitle: 'Vos commandes livrées apparaîtront ici',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: orders.length,
          itemBuilder:
              (context, index) => _buildDeliveryCard(orders[index], true),
        );
      },
    );
  }

  Widget _buildDeliveryCard(Order order, bool isDelivered) {
    final totalWeight = order.getTotalWeight();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec numéro de commande et statut
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Commande #${order.id.substring(0, 8)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color:
                        isDelivered
                            ? Colors.green.withOpacity(0.1)
                            : Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDelivered ? Colors.green : Colors.orange,
                    ),
                  ),
                  child: Text(
                    isDelivered ? 'Livrée' : 'À Livrer',
                    style: TextStyle(
                      color: isDelivered ? Colors.green : Colors.orange,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Informations client
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primaryColor.withOpacity(0.1),
                  child: Text(
                    order.userfirstName[0],
                    style: TextStyle(
                      color: AppColors.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${order.userfirstName} ${order.userlastName}',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      Text(
                        order.userphone,
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Adresse de livraison
            if (order.deliveryAddress != null) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.location_on, size: 16, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      order.deliveryAddress!,
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],

            // Notes de livraison
            if (order.deliveryNotes != null &&
                order.deliveryNotes!.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.note, size: 16, color: Colors.orange),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        order.deliveryNotes!,
                        style: TextStyle(
                          color: Colors.orange[800],
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],

            // Détails de la commande
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${order.items.length} article${order.items.length > 1 ? 's' : ''}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${totalWeight.toStringAsFixed(1)} kg',
                        style: TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Total',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      Text(
                        Utils.formatPrice(order.total),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Date de la commande
            if (order.date != null) ...[
              const SizedBox(height: 8),
              Text(
                'Commandé le ${_dateFormat.format(order.date!)}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],

            // Bouton d'action
            if (!isDelivered) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () => _markAsDelivered(order),
                  child: const Text(
                    'Marquer comme Livrée',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ] else if (order.deliveredAt != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle, size: 16, color: Colors.green),
                    const SizedBox(width: 8),
                    Text(
                      'Livrée le ${_dateFormat.format(order.deliveredAt!)}',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String message,
    String? subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(
                fontSize: 18,
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _markAsDelivered(Order order) async {
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);

    try {
      await orderProvider.markAsDelivered(order.id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Commande #${order.id.substring(0, 8)} marquée comme livrée',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
