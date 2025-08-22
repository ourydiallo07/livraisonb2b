import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:livraisonb2b/constants/order_status.dart';
import 'package:livraisonb2b/global_utils/utils.dart';
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
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy HH:mm');
  final DateFormat _dayFormat = DateFormat('EEEE dd MMMM');
  bool _groupByUser = true;
  String _filterStatus = 'Tous';
  String _dateFilter = 'Toutes';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = Provider.of<OrderProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Commandes Clients'),
        backgroundColor: AppColors.primaryColor,
        actions: [
          IconButton(
            icon: Icon(_groupByUser ? Icons.list : Icons.group),
            onPressed: () => setState(() => _groupByUser = !_groupByUser),
            tooltip: _groupByUser ? 'Vue liste' : 'Vue groupée',
          ),
        ],
      ),
      body: Column(
        children: [
          // Barre de recherche et filtres
          _buildFilterBar(),
          // Liste des commandes
          Expanded(
            child: StreamBuilder<List<Order>>(
              stream: orderProvider.getAllOrders(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Erreur: ${snapshot.error}'));
                }

                final orders = snapshot.data ?? [];
                if (orders.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shopping_cart, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'Aucune commande trouvée',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                // Filtrer et trier les commandes
                final filteredOrders = _filterOrders(orders);

                // Trier par date (les plus récentes en premier)
                filteredOrders.sort(
                  (a, b) =>
                      (b.date ?? DateTime(0)).compareTo(a.date ?? DateTime(0)),
                );

                return RefreshIndicator(
                  onRefresh: () async {
                    // Forcer le rafraîchissement en reconstruisant le widget
                    setState(() {});
                    await Future.delayed(const Duration(milliseconds: 500));
                  },
                  child:
                      _groupByUser
                          ? _buildGroupedView(filteredOrders)
                          : _buildListView(filteredOrders),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Barre de filtres et recherche
  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.grey[50],
      child: Column(
        children: [
          // Barre de recherche
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Rechercher une commande, client...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon:
                  _searchController.text.isNotEmpty
                      ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      )
                      : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            onChanged: (value) => setState(() {}),
          ),
          const SizedBox(height: 12),
          // Double ligne de filtres
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _buildStatusFilterChip('Tous'),
                      _buildStatusFilterChip(OrderStatus.pending),
                      _buildStatusFilterChip(OrderStatus.processing),
                      _buildStatusFilterChip(OrderStatus.shipped),
                      _buildStatusFilterChip(OrderStatus.delivered),
                      _buildStatusFilterChip(OrderStatus.cancelled),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _buildDateFilterChip('Aujourd\'hui'),
                      _buildDateFilterChip('Hier'),
                      _buildDateFilterChip('Cette semaine'),
                      _buildDateFilterChip('Ce mois'),
                      _buildDateFilterChip('Toutes'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusFilterChip(String status) {
    final isSelected = _filterStatus == status;
    final displayText =
        status == 'Tous' ? 'Tous' : OrderStatus.getFrenchTranslation(status);

    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(displayText),
        selected: isSelected,
        onSelected:
            (selected) =>
                setState(() => _filterStatus = selected ? status : 'Tous'),
        backgroundColor: Colors.white,
        selectedColor: _getStatusColor(status).withOpacity(0.2),
        checkmarkColor: _getStatusColor(status),
        labelStyle: TextStyle(
          color: isSelected ? _getStatusColor(status) : Colors.grey[700],
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        shape: StadiumBorder(
          side: BorderSide(
            color: isSelected ? _getStatusColor(status) : Colors.grey[300]!,
            width: 1,
          ),
        ),
      ),
    );
  }

  Widget _buildDateFilterChip(String dateFilter) {
    final isSelected = _dateFilter == dateFilter;

    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(dateFilter),
        selected: isSelected,
        onSelected:
            (selected) =>
                setState(() => _dateFilter = selected ? dateFilter : 'Toutes'),
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

  // Filtrer les commandes selon les critères
  List<Order> _filterOrders(List<Order> orders) {
    var filtered = orders;

    // Filtre par statut
    if (_filterStatus != 'Tous') {
      filtered =
          filtered.where((order) => order.status == _filterStatus).toList();
    }

    // Filtre par date
    final now = DateTime.now();
    if (_dateFilter == 'Aujourd\'hui') {
      filtered =
          filtered.where((order) => _isSameDay(order.date, now)).toList();
    } else if (_dateFilter == 'Hier') {
      final yesterday = DateTime(now.year, now.month, now.day - 1);
      filtered =
          filtered.where((order) => _isSameDay(order.date, yesterday)).toList();
    } else if (_dateFilter == 'Cette semaine') {
      filtered =
          filtered.where((order) => _isSameWeek(order.date, now)).toList();
    } else if (_dateFilter == 'Ce mois') {
      filtered =
          filtered.where((order) => _isSameMonth(order.date, now)).toList();
    }

    // Filtre par recherche
    if (_searchController.text.isNotEmpty) {
      final searchLower = _searchController.text.toLowerCase();
      filtered =
          filtered.where((order) {
            return order.id.toLowerCase().contains(searchLower) ||
                order.userfirstName.toLowerCase().contains(searchLower) ||
                order.userlastName.toLowerCase().contains(searchLower) ||
                order.userphone.toLowerCase().contains(searchLower) ||
                (order.deliveryAddress != null &&
                    order.deliveryAddress!.toLowerCase().contains(searchLower));
          }).toList();
    }

    return filtered;
  }

  bool _isSameDay(DateTime? date1, DateTime date2) {
    if (date1 == null) return false;
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  bool _isSameWeek(DateTime? date, DateTime reference) {
    if (date == null) return false;

    // Trouver le début de la semaine (lundi)
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

  Widget _buildGroupedView(List<Order> orders) {
    // Grouper par date d'abord, puis par utilisateur
    final dateGroups = <String, Map<String, List<Order>>>{};

    for (final order in orders) {
      final dateKey = _getDateGroupKey(order.date);
      final userKey = '${order.userId}_${order.userphone}';

      if (!dateGroups.containsKey(dateKey)) {
        dateGroups[dateKey] = {};
      }

      (dateGroups[dateKey]![userKey] ??= []).add(order);
    }

    return dateGroups.isEmpty
        ? _buildEmptyState()
        : ListView.builder(
          itemCount: dateGroups.length,
          itemBuilder: (context, index) {
            final dateKey = dateGroups.keys.elementAt(index);
            final userGroups = dateGroups[dateKey]!;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    dateKey,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryColor,
                    ),
                  ),
                ),
                ...userGroups.values.map(
                  (userOrders) => _buildUserGroup(userOrders),
                ),
              ],
            );
          },
        );
  }

  String _getDateGroupKey(DateTime? date) {
    if (date == null) return 'Date inconnue';

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);

    if (_isSameDay(date, today)) {
      return 'Aujourd\'hui';
    } else if (_isSameDay(date, yesterday)) {
      return 'Hier';
    } else if (_isSameWeek(date, now)) {
      return 'Cette semaine';
    } else if (_isSameMonth(date, now)) {
      return 'Ce mois-ci';
    } else {
      return '${_dayFormat.format(date)} ${date.year}';
    }
  }

  Widget _buildUserGroup(List<Order> userOrders) {
    final firstOrder = userOrders.first;
    final itemCount = userOrders.fold(
      0,
      (sum, order) => sum + order.items.length,
    );
    final totalAmount = userOrders.fold(0.0, (sum, order) => sum + order.total);
    final hasPendingOrders = userOrders.any(
      (order) => order.status == OrderStatus.pending,
    );

    return Card(
      margin: const EdgeInsets.all(8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        initiallyExpanded: userOrders.length == 1,
        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
        leading: CircleAvatar(
          backgroundColor: AppColors.primaryColor.withOpacity(0.1),
          child: Text(
            firstOrder.userfirstName[0],
            style: TextStyle(
              color: AppColors.primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${firstOrder.userfirstName} ${firstOrder.userlastName}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    firstOrder.userphone,
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ],
              ),
            ),
            if (hasPendingOrders)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.orange,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.warning, color: Colors.white, size: 16),
              ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${userOrders.length} commande${userOrders.length > 1 ? 's' : ''}',
                style: TextStyle(color: Colors.grey[600]),
              ),
              Text(
                Utils.formatPrice(totalAmount),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
        ),
        trailing: Chip(
          label: Text('${userOrders.length} cmd'),
          backgroundColor: AppColors.primaryColor,
          labelStyle: const TextStyle(color: Colors.white),
        ),
        children: [
          Divider(height: 1, color: Colors.grey[300]),
          ...userOrders.map(
            (order) => _buildOrderCard(order, showUserInfo: false),
          ),
        ],
      ),
    );
  }

  Widget _buildListView(List<Order> orders) {
    if (orders.isEmpty) return _buildEmptyState();

    // Grouper les commandes par date pour la vue liste
    final dateGroups = <String, List<Order>>{};

    for (final order in orders) {
      final dateKey = _getDateGroupKey(order.date);
      (dateGroups[dateKey] ??= []).add(order);
    }

    return ListView.builder(
      itemCount: dateGroups.length,
      itemBuilder: (context, index) {
        final dateKey = dateGroups.keys.elementAt(index);
        final dateOrders = dateGroups[dateKey]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                dateKey,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryColor,
                ),
              ),
            ),
            ...dateOrders.map((order) => _buildOrderCard(order)),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text(
            'Aucune commande ne correspond à vos critères',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              setState(() {
                _filterStatus = 'Tous';
                _dateFilter = 'Toutes';
                _searchController.clear();
              });
            },
            child: const Text('Réinitialiser les filtres'),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(Order order, {bool showUserInfo = true}) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showOrderDetails(context, order),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showUserInfo) ...[
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
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(),
              ],
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'CMD #${order.id.substring(0, 6)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    order.date != null
                        ? _dateFormat.format(order.date!)
                        : 'Date inconnue',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
              if (order.deliveryAddress != null) ...[
                const SizedBox(height: 8),
                Text('Livraison: ${order.deliveryAddress}'),
              ],
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${order.items.length} article(s)',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  _buildStatusBadge(order.status),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    Utils.formatPrice(order.total),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  _buildStatusDropdown(order),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: _getStatusColor(status).withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _getStatusColor(status)),
      ),
      child: Text(
        OrderStatus.getFrenchTranslation(status),
        style: TextStyle(
          color: _getStatusColor(status),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildStatusDropdown(Order order) {
    return PopupMenuButton<String>(
      onSelected: (value) => _updateOrderStatus(order, value),
      itemBuilder:
          (context) =>
              OrderStatus.values.map((status) {
                return PopupMenuItem(
                  value: status,
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: _getStatusColor(status),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(OrderStatus.getFrenchTranslation(status)),
                    ],
                  ),
                );
              }).toList(),
      child: const Icon(Icons.more_vert),
    );
  }

  Future<void> _updateOrderStatus(Order order, String newStatus) async {
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    try {
      await orderProvider.updateOrderStatus(order.id, newStatus);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Statut changé à: ${OrderStatus.getFrenchTranslation(newStatus)}',
          ),
          backgroundColor: _getStatusColor(newStatus),
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

  void _showOrderDetails(BuildContext context, Order order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder:
          (context) => SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Détails Commande #${order.id.substring(0, 8)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Divider(),
                  _buildDetailItem(
                    'Client',
                    '${order.userfirstName} ${order.userlastName}',
                  ),
                  _buildDetailItem('Téléphone', order.userphone),
                  if (order.deliveryAddress != null)
                    _buildDetailItem('Adresse', order.deliveryAddress!),
                  _buildDetailItem(
                    'Date',
                    order.date != null
                        ? _dateFormat.format(order.date!)
                        : 'Non spécifiée',
                  ),
                  _buildDetailItem(
                    'Statut',
                    OrderStatus.getFrenchTranslation(order.status),
                    valueColor: _getStatusColor(order.status),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Articles',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const Divider(),
                  ...order.items.map(
                    (item) => ListTile(
                      leading:
                          item.imageUrl != null
                              ? Image.network(
                                item.imageUrl!,
                                width: 40,
                                height: 40,
                              )
                              : const Icon(Icons.shopping_basket),
                      title: Text(item.name),
                      subtitle: Text(
                        '${item.quantity} x ${Utils.formatPrice(item.price)}',
                      ),
                      trailing: Text(
                        Utils.formatPrice(item.price * item.quantity),
                      ),
                    ),
                  ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'TOTAL',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
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
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Fermer',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildDetailItem(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(value, style: TextStyle(color: valueColor))),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.processing:
        return Colors.blue;
      case OrderStatus.shipped:
        return Colors.lightBlue;
      case OrderStatus.delivered:
        return Colors.green;
      case OrderStatus.cancelled:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
