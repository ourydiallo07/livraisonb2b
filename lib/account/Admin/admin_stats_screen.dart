import 'package:flutter/material.dart';
import 'package:livraisonb2b/provider_data/order_provider.dart';
import 'package:livraisonb2b/constants/theme.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

class AdminStatsScreen extends StatefulWidget {
  static const String idScreen = "AdminStatsScreen";

  const AdminStatsScreen({super.key});

  @override
  State<AdminStatsScreen> createState() => _AdminStatsScreenState();
}

class _AdminStatsScreenState extends State<AdminStatsScreen> {
  late Future<Map<String, dynamic>> _statsFuture;

  @override
  void initState() {
    super.initState();
    _statsFuture = _loadStats();
  }

  Future<Map<String, dynamic>> _loadStats() async {
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    return {
      'ordersByStatus': await orderProvider.getOrdersCountByStatus(),
      'totalOrders': await orderProvider.getTotalOrdersCount(),
      'recentOrders': await orderProvider.getRecentOrders(5),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistiques'),
        backgroundColor: AppColors.primaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed:
                () => setState(() {
                  _statsFuture = _loadStats();
                }),
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _statsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Erreur: ${snapshot.error}'));
          }

          final stats = snapshot.data!;
          final ordersByStatus = stats['ordersByStatus'] as Map<String, int>;
          final totalOrders = stats['totalOrders'] as int;
          final recentOrders = stats['recentOrders'] as List<dynamic>;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildStatsCard('Commandes totales', totalOrders.toString()),
                const SizedBox(height: 20),
                SizedBox(height: 200, child: _buildStatusChart(ordersByStatus)),
                const SizedBox(height: 20),
                const Text(
                  'Dernières commandes',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                ...recentOrders.map(
                  (order) => Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      title: Text('Commande #${order['id']}'),
                      subtitle: Text('Statut: ${order['status']}'),
                      trailing: Icon(
                        Icons.chevron_right,
                        color: AppColors.primaryColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatsCard(String title, String value) {
    return Card(
      elevation: 4,
      color: AppColors.primaryColor.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, color: Colors.black54),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChart(Map<String, int> data) {
    // Générer des couleurs différentes pour chaque section
    final colors = [
      AppColors.primaryColor,
      Colors.orange,
      Colors.green,
      Colors.red,
      Colors.blue,
      Colors.purple,
    ];

    final List<PieChartSectionData> sections =
        data.entries.map((e) {
          final index = data.keys.toList().indexOf(e.key) % colors.length;
          return PieChartSectionData(
            color: colors[index],
            value: e.value.toDouble(),
            title: '${e.value}',
            radius: 60,
            titleStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            badgeWidget: Container(
              padding: const EdgeInsets.all(4),
              child: Text(
                e.key,
                style: const TextStyle(fontSize: 10, color: Colors.white),
              ),
            ),
            badgePositionPercentageOffset: 1.2,
          );
        }).toList();

    return PieChart(
      PieChartData(
        sections: sections,
        centerSpaceRadius: 40,
        sectionsSpace: 2,
        startDegreeOffset: -90,
      ),
    );
  }
}
