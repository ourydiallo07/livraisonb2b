import 'package:flutter/material.dart';
import 'package:livraisonb2b/account/Admin/admin_orders_screen.dart';
import 'package:livraisonb2b/account/Admin/admin_stats_screen.dart';
import 'package:livraisonb2b/account/Admin/admin_users_screen.dart';
import 'package:livraisonb2b/constants/theme.dart';

class AdminHomeScreen extends StatelessWidget {
  static const String idScreen = "AdminHomeScreen";

  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tableau de bord Admin'),
        backgroundColor: AppColors.primaryColor,
      ),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16),
        children: [
          _buildAdminCard(
            context,
            Icons.people,
            'Utilisateurs',
            () => Navigator.pushNamed(context, AdminUsersScreen.idScreen),
          ),
          _buildAdminCard(
            context,
            Icons.shopping_cart,
            'Commandes',
            () => Navigator.pushNamed(context, AdminOrdersScreen.idScreen),
          ),
          _buildAdminCard(
            context,
            Icons.bar_chart,
            'Statistiques',
            () => Navigator.pushNamed(context, AdminStatsScreen.idScreen),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminCard(
    BuildContext context,
    IconData icon,
    String title,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 50, color: AppColors.primaryColor),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(fontSize: 18)),
          ],
        ),
      ),
    );
  }
}
