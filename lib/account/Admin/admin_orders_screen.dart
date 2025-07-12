import 'package:flutter/material.dart';
import 'package:livraisonb2b/constants/order_status.dart';
import 'package:livraisonb2b/models/order.dart';
import 'package:livraisonb2b/provider_data/order_provider.dart';
import 'package:livraisonb2b/constants/theme.dart';
import 'package:provider/provider.dart';

class AdminOrdersScreen extends StatefulWidget {
  static const String idScreen = "AdminOrdersScreen";

  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  @override
  Widget build(BuildContext context) {
    final orderProvider = Provider.of<OrderProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des Commandes'),
        backgroundColor: AppColors.primaryColor,
      ),
      body: StreamBuilder<List<Order>>(
        stream: orderProvider.getAllOrders(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Erreur: ${snapshot.error}'));
          }

          final orders = snapshot.data ?? [];

          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: ListTile(
                  title: Text('Commande #${order.id}'),
                  subtitle: Text('Statut: ${order.status}'),
                  trailing: DropdownButton<String>(
                    value: order.status,
                    items:
                        OrderStatus.values
                            .map(
                              (status) => DropdownMenuItem(
                                value: status,
                                child: Text(status),
                              ),
                            )
                            .toList(),
                    onChanged: (value) => _updateOrderStatus(order, value!),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _updateOrderStatus(Order order, String newStatus) async {
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    try {
      await orderProvider.updateOrderStatus(order.id!, newStatus);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Statut mis à jour')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur: ${e.toString()}')));
    }
  }
}
