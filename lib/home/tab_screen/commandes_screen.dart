import 'package:flutter/material.dart';
import 'package:livraisonb2b/constants/theme.dart';
import 'package:livraisonb2b/global_utils/utils.dart';
import 'package:livraisonb2b/models/order.dart';
import 'package:livraisonb2b/provider_data/Login_data.dart';
import 'package:livraisonb2b/provider_data/order_provider.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class CommandesScreen extends StatefulWidget {
  static const String idScreen = "commandes";

  const CommandesScreen({super.key});

  @override
  State<CommandesScreen> createState() => _CommandesScreenState();
}

class _CommandesScreenState extends State<CommandesScreen> {
  String _selectedFilter = 'Toutes';
  final Map<String, String> _statusTranslations = {
    'pending': 'En attente',
    'processing': 'En cours',
    'shipped': 'Expédiée',
    'delivered': 'Livrée',
    'cancelled': 'Annulée',
  };

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<LoginData>(context).currentUserApp;
    final orderProvider = Provider.of<OrderProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Commandes'),
        backgroundColor: AppColors.primaryGreen,
      ),
      body: StreamBuilder<List<Order>>(
        stream: orderProvider.getOrdersStream(user.id ?? ''),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Erreur: ${snapshot.error}'));
          }

          final orders = snapshot.data ?? [];

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildStatusSummary(orders),
                const SizedBox(height: 16),
                _buildFilterChips(),
                const SizedBox(height: 16),
                Expanded(child: _buildOrdersList(orders)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusSummary(List<Order> orders) {
    final statusCounts = {
      'Toutes': orders.length,
      'En attente': orders.where((o) => o.status == 'pending').length,
      'En cours': orders.where((o) => o.status == 'processing').length,
      'Livrée': orders.where((o) => o.status == 'delivered').length,
      'Annulée': orders.where((o) => o.status == 'cancelled').length,
    };

    return SizedBox(
      height: 100,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children:
            statusCounts.entries.map((entry) {
              return Container(
                width: 120,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
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
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              );
            }).toList(),
      ),
    );
  }

  Widget _buildFilterChips() {
    return Wrap(
      spacing: 8.0,
      children:
          ['Toutes', 'En attente', 'En cours', 'Livrée', 'Annulée'].map((
            filter,
          ) {
            return ChoiceChip(
              label: Text(filter),
              selected: _selectedFilter == filter,
              onSelected: (selected) {
                setState(() {
                  _selectedFilter = selected ? filter : 'Toutes';
                });
              },
              selectedColor: AppColors.primaryGreen,
            );
          }).toList(),
    );
  }

  Widget _buildOrdersList(List<Order> orders) {
    final filteredOrders =
        _selectedFilter == 'Toutes'
            ? orders
            : orders
                .where(
                  (order) =>
                      _statusTranslations[order.status] == _selectedFilter,
                )
                .toList();

    if (filteredOrders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, size: 60, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Aucune commande ${_selectedFilter == 'Toutes' ? '' : '$_selectedFilter '}trouvée',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: filteredOrders.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final order = filteredOrders[index];
        return _buildOrderCard(order);
      },
    );
  }

  Widget _buildOrderCard(Order order) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Commande #${order.id.substring(0, 8)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusBackgroundColor(order.status),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _statusTranslations[order.status] ?? order.status,
                    style: TextStyle(
                      color: _getStatusColor(order.status),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _formatDate(order.date ?? DateTime.now()),
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            const SizedBox(height: 12),
            ...order.items.map((item) => _buildOrderItem(item)).toList(),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total:', style: TextStyle(fontSize: 16)),
                Text(
                  Utils.formatPrice(order.total),
                  style: const TextStyle(
                    fontSize: 16,
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

  Widget _buildOrderItem(OrderItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child:
                item.imageUrl != null
                    ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(item.imageUrl!, fit: BoxFit.cover),
                    )
                    : Icon(
                      Icons.shopping_bag,
                      size: 20,
                      color: Colors.grey[400],
                    ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${item.quantity} x ${Utils.formatPrice(item.price)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Text(
            Utils.formatPrice(item.price * item.quantity),
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy - HH:mm').format(date);
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'processing':
        return Colors.blue;
      case 'delivered':
        return AppColors.primaryGreen;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.white;
    }
  }

  Color _getStatusBackgroundColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange.withOpacity(0.2);
      case 'processing':
        return Colors.blue.withOpacity(0.2);
      case 'delivered':
        return AppColors.primaryGreen.withOpacity(0.2);
      case 'cancelled':
        return Colors.red.withOpacity(0.2);
      default:
        return Colors.grey.withOpacity(0.2);
    }
  }
}

class ChoiceChip extends StatelessWidget {
  final Widget label;
  final bool selected;
  final ValueChanged<bool> onSelected;
  final Color? selectedColor;

  const ChoiceChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
    this.selectedColor,
  });

  @override
  Widget build(BuildContext context) {
    return InputChip(
      label: label,
      selected: selected,
      onSelected: onSelected,
      selectedColor: selectedColor ?? Theme.of(context).primaryColor,
      labelStyle: TextStyle(color: selected ? Colors.white : Colors.black),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color:
              selected
                  ? selectedColor ?? Theme.of(context).primaryColor
                  : Colors.grey,
        ),
      ),
    );
  }
}
