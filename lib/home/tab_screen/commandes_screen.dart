import 'package:flutter/material.dart';
import 'package:livraisonb2b/constants/theme.dart';
import 'package:livraisonb2b/models/order.dart';
import 'package:livraisonb2b/provider_data/order_provider.dart';
import 'package:livraisonb2b/provider_data/Login_data.dart';
import 'package:provider/provider.dart';

class CommandesScreen extends StatefulWidget {
  static const String idScreen = "CommandesScreen";
  const CommandesScreen({super.key});

  @override
  State<CommandesScreen> createState() => _CommandesScreenState();
}

class _CommandesScreenState extends State<CommandesScreen> {
  String _selectedFilter = 'Toutes';

  final Map<String, String> _statusFilters = {
    'Toutes': 'all',
    'En cours': 'pending',
    'Livrées': 'delivered',
    'Annulées': 'cancelled',
  };

  @override
  void initState() {
    super.initState();
    final user = Provider.of<LoginData>(context, listen: false).currentUserApp;
    Provider.of<OrderProvider>(
      context,
      listen: false,
    ).fetchUserOrders(user.id!);
  }

  Widget _buildStatusSummary(List<Order> orders) {
    final statusCounts = {
      'En cours': orders.where((o) => o.status == 'pending').length,
      'Livrées': orders.where((o) => o.status == 'delivered').length,
      'Annulées': orders.where((o) => o.status == 'cancelled').length,
    };

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.secondaryGreen,
        borderRadius: BorderRadius.circular(10),
      ),
      margin: const EdgeInsets.all(8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children:
            statusCounts.entries.map((entry) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    entry.value.toString(),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    entry.key,
                    style: TextStyle(fontSize: 12, color: AppColors.textGrey),
                  ),
                ],
              );
            }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = Provider.of<OrderProvider>(context);
    final user = Provider.of<LoginData>(context).currentUserApp;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Mes Commandes",
          style: TextStyle(color: AppColors.backgroundWhite),
        ),
        centerTitle: true,
        backgroundColor: AppColors.primaryGreen,
        iconTheme: const IconThemeData(color: AppColors.backgroundWhite),
      ),
      body: StreamBuilder<List<Order>>(
        stream: orderProvider.getOrdersStream(user.id!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: AppColors.primaryGreen),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text(
                "Aucune commande trouvée",
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textGrey,
                ),
              ),
            );
          }

          final orders = snapshot.data!;
          final filteredOrders =
              _selectedFilter == 'Toutes'
                  ? orders
                  : orders
                      .where(
                        (order) =>
                            order.status == _statusFilters[_selectedFilter],
                      )
                      .toList();

          return Column(
            children: [
              // Section Résumé
              _buildStatusSummary(orders),

              // Filtres
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                color: AppColors.secondaryGreen,
                child: SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _statusFilters.length,
                    itemBuilder: (context, index) {
                      final filter = _statusFilters.keys.elementAt(index);
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: ChoiceChip(
                          label: Text(
                            filter,
                            style: TextStyle(
                              color:
                                  _selectedFilter == filter
                                      ? AppColors.backgroundWhite
                                      : AppColors.textDark,
                            ),
                          ),
                          selected: _selectedFilter == filter,
                          selectedColor: AppColors.primaryGreen,
                          backgroundColor: AppColors.backgroundWhite,
                          side: const BorderSide(color: AppColors.borderGrey),
                          onSelected: (selected) {
                            setState(() {
                              _selectedFilter = selected ? filter : 'Toutes';
                            });
                          },
                        ),
                      );
                    },
                  ),
                ),
              ),

              // Liste des commandes
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: filteredOrders.length,
                  itemBuilder: (context, index) {
                    final order = filteredOrders[index];
                    return _buildOrderCard(order, theme);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildOrderCard(Order order, ThemeData theme) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: AppColors.borderGrey, width: 1),
      ),
      color: AppColors.backgroundWhite,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Commande #${order.id.substring(0, 8)}",
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusBackgroundColor(order.status),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getStatusText(order.status),
                    style: TextStyle(
                      color: _getStatusColor(order.status),
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              "Date: ${_formatDate(order.date)}",
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textGrey,
              ),
            ),
            const SizedBox(height: 12),
            ...order.items.map(
              (item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        "${item.quantity} x ${item.name}",
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.textDark,
                        ),
                      ),
                    ),
                    Text(
                      "${(item.price * item.quantity).toStringAsFixed(0)} FCFA",
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.textDark,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(color: AppColors.borderGrey),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Total:",
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                Text(
                  "${order.total.toStringAsFixed(0)} FCFA",
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryGreen,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}";
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'En cours';
      case 'processing':
        return 'En traitement';
      case 'delivered':
        return 'Livrée';
      case 'cancelled':
        return 'Annulée';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
      case 'processing':
        return AppColors.primaryGreen;
      case 'delivered':
        return AppColors.primaryGreen;
      case 'cancelled':
        return Colors.red;
      default:
        return AppColors.textDark;
    }
  }

  Color _getStatusBackgroundColor(String status) {
    switch (status) {
      case 'pending':
      case 'processing':
      case 'delivered':
        return AppColors.secondaryGreen;
      case 'cancelled':
        return Colors.red.withOpacity(0.1);
      default:
        return AppColors.secondaryGreen;
    }
  }
}
