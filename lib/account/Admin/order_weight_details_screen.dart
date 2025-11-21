import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:livraisonb2b/constants/order_status.dart';
import 'package:livraisonb2b/global_utils/utils.dart';
import 'package:livraisonb2b/models/order.dart';
import 'package:livraisonb2b/provider_data/order_provider.dart';
import 'package:livraisonb2b/constants/theme.dart';
import 'package:provider/provider.dart';

class OrderWeightDetailsScreen extends StatefulWidget {
  static const String idScreen = "OrderWeightDetailsScreen";

  const OrderWeightDetailsScreen({super.key});

  @override
  State<OrderWeightDetailsScreen> createState() =>
      _OrderWeightDetailsScreenState();
}

class _OrderWeightDetailsScreenState extends State<OrderWeightDetailsScreen> {
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  String _dateFilter = 'Aujourd\'hui';
  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;
  bool _useCustomDateRange = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Détails par Article'),
        backgroundColor: AppColors.primaryColor,
      ),
      body: Column(
        children: [
          _buildDateFilterSection(),
          Expanded(
            child: StreamBuilder<List<Order>>(
              stream: Provider.of<OrderProvider>(context).getAllOrders(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Erreur: ${snapshot.error}'));
                }

                final orders = snapshot.data ?? [];
                final filteredOrders = _filterOrdersByDate(orders);
                final productStats = _calculateProductStats(filteredOrders);

                if (productStats.isEmpty) {
                  return _buildEmptyState();
                }

                return _buildProductStatsList(productStats, filteredOrders);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateFilterSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[50],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Période',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          // Sélection rapide de période
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildDateFilterChip('Aujourd\'hui'),
                _buildDateFilterChip('Hier'),
                _buildDateFilterChip('Cette semaine'),
                _buildDateFilterChip('Ce mois'),
                _buildDateFilterChip('Personnalisée'),
              ],
            ),
          ),

          // Sélecteur de date personnalisée
          if (_useCustomDateRange) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Du', style: TextStyle(fontSize: 12)),
                      InkWell(
                        onTap: () => _selectStartDate(context),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 16),
                              const SizedBox(width: 8),
                              Text(
                                _selectedStartDate != null
                                    ? _dateFormat.format(_selectedStartDate!)
                                    : 'Sélectionner',
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Au', style: TextStyle(fontSize: 12)),
                      InkWell(
                        onTap: () => _selectEndDate(context),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 16),
                              const SizedBox(width: 8),
                              Text(
                                _selectedEndDate != null
                                    ? _dateFormat.format(_selectedEndDate!)
                                    : 'Sélectionner',
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],

          // Résumé de la période sélectionnée
          const SizedBox(height: 16),
          StreamBuilder<List<Order>>(
            stream: Provider.of<OrderProvider>(context).getAllOrders(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox();

              final orders = snapshot.data!;
              final filteredOrders = _filterOrdersByDate(orders);
              final totalWeight = filteredOrders.fold<double>(
                0.0,
                (sum, order) => sum + order.getTotalWeight(),
              );
              final totalAmount = filteredOrders.fold<double>(
                0.0,
                (sum, order) => sum + order.total,
              );

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildSummaryItem('Commandes', '${filteredOrders.length}'),
                  _buildSummaryItem(
                    'Poids Total',
                    '${totalWeight.toStringAsFixed(1)} kg',
                  ),
                  _buildSummaryItem(
                    'Montant Total',
                    Utils.formatPrice(totalAmount),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDateFilterChip(String filter) {
    final isSelected = _dateFilter == filter;

    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(filter),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _dateFilter = selected ? filter : 'Aujourd\'hui';
            _useCustomDateRange = filter == 'Personnalisée';
            if (!_useCustomDateRange) {
              _selectedStartDate = null;
              _selectedEndDate = null;
            }
          });
        },
        backgroundColor: Colors.white,
        selectedColor: AppColors.primaryColor.withOpacity(0.2),
        checkmarkColor: AppColors.primaryColor,
        labelStyle: TextStyle(
          color: isSelected ? AppColors.primaryColor : Colors.grey[700],
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        shape: StadiumBorder(
          side: BorderSide(
            color: isSelected ? AppColors.primaryColor : Colors.grey[300]!,
            width: 1,
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryColor,
          ),
        ),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Future<void> _selectStartDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedStartDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedStartDate = picked;
      });
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedEndDate ?? DateTime.now(),
      firstDate: _selectedStartDate ?? DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedEndDate = picked;
      });
    }
  }

  List<Order> _filterOrdersByDate(List<Order> orders) {
    final now = DateTime.now();

    if (_useCustomDateRange &&
        _selectedStartDate != null &&
        _selectedEndDate != null) {
      return orders.where((order) {
        if (order.date == null) return false;
        final orderDate = DateTime(
          order.date!.year,
          order.date!.month,
          order.date!.day,
        );
        final startDate = DateTime(
          _selectedStartDate!.year,
          _selectedStartDate!.month,
          _selectedStartDate!.day,
        );
        final endDate = DateTime(
          _selectedEndDate!.year,
          _selectedEndDate!.month,
          _selectedEndDate!.day,
        );
        return orderDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
            orderDate.isBefore(endDate.add(const Duration(days: 1)));
      }).toList();
    }

    switch (_dateFilter) {
      case 'Aujourd\'hui':
        return orders.where((order) => _isSameDay(order.date, now)).toList();
      case 'Hier':
        final yesterday = DateTime(now.year, now.month, now.day - 1);
        return orders
            .where((order) => _isSameDay(order.date, yesterday))
            .toList();
      case 'Cette semaine':
        return orders.where((order) => _isSameWeek(order.date, now)).toList();
      case 'Ce mois':
        return orders.where((order) => _isSameMonth(order.date, now)).toList();
      default:
        return orders;
    }
  }

  bool _isSameDay(DateTime? date1, DateTime date2) {
    if (date1 == null) return false;
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  bool _isSameWeek(DateTime? date, DateTime reference) {
    if (date == null) return false;
    final startOfWeek = reference.subtract(
      Duration(days: reference.weekday - 1),
    );
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    return date.isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
        date.isBefore(endOfWeek.add(const Duration(days: 1)));
  }

  bool _isSameMonth(DateTime? date, DateTime reference) {
    if (date == null) return false;
    return date.year == reference.year && date.month == reference.month;
  }

  Map<String, ProductStat> _calculateProductStats(List<Order> orders) {
    final productStats = <String, ProductStat>{};

    for (final order in orders) {
      for (final item in order.items) {
        final productKey = '${item.name}_${item.unit}_${item.sacSize ?? ''}';

        if (!productStats.containsKey(productKey)) {
          productStats[productKey] = ProductStat(
            name: item.name,
            unit: item.unit,
            sacSize: item.sacSize,
          );
        }

        final stat = productStats[productKey]!;
        final itemWeight = _calculateItemWeight(item);
        final itemTotal = item.price * item.quantity;

        stat.totalQuantity += item.quantity;
        stat.totalWeight += itemWeight;
        stat.totalAmount += itemTotal;
        stat.ordersCount++;
      }
    }

    return productStats;
  }

  double _calculateItemWeight(OrderItem item) {
    if (item.unit == 'sac' || item.unit?.contains('sac') == true) {
      final sacWeight = item.sacSize?.toDouble() ?? 25.0;
      return item.quantity * sacWeight;
    } else {
      return item.quantity.toDouble();
    }
  }

  Widget _buildProductStatsList(
    Map<String, ProductStat> productStats,
    List<Order> orders,
  ) {
    final sortedProducts =
        productStats.entries.toList()
          ..sort((a, b) => b.value.totalWeight.compareTo(a.value.totalWeight));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedProducts.length,
      itemBuilder: (context, index) {
        final entry = sortedProducts[index];
        final stat = entry.value;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        stat.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        stat.unit,
                        style: TextStyle(
                          color: AppColors.primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatItem('Quantité', '${stat.totalQuantity}'),
                    _buildStatItem(
                      'Poids Total',
                      '${stat.totalWeight.toStringAsFixed(1)} kg',
                    ),
                    _buildStatItem(
                      'Montant',
                      Utils.formatPrice(stat.totalAmount),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Commandes: ${stat.ordersCount}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                if (stat.sacSize != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Taille sac: ${stat.sacSize} kg',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryColor,
          ),
        ),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text(
            'Aucune donnée pour cette période',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class ProductStat {
  final String name;
  final String unit;
  final int? sacSize;
  int totalQuantity = 0;
  double totalWeight = 0;
  double totalAmount = 0;
  int ordersCount = 0;

  ProductStat({required this.name, required this.unit, this.sacSize});
}
