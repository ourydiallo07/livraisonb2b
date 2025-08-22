import 'package:flutter/material.dart';
import 'package:livraisonb2b/account/Admin/admin_orders_screen.dart';
import 'package:livraisonb2b/account/Admin/admin_stats_screen.dart';
import 'package:livraisonb2b/account/Admin/admin_users_screen.dart';
import 'package:livraisonb2b/constants/theme.dart';
import 'package:livraisonb2b/main_screen.dart';
import 'package:livraisonb2b/models/app_user.dart';
import 'package:livraisonb2b/provider_data/Login_data.dart';
import 'package:livraisonb2b/services/auth_service.dart';
import 'package:provider/provider.dart';

class AdminHomeScreen extends StatelessWidget {
  static const String idScreen = "AdminHomeScreen";

  Future<void> _signOut(BuildContext context) async {
    try {
      // Appeler la méthode de déconnexion du service d'authentification
      await AuthService.signOutAppUser();

      // Réinitialiser les données de l'utilisateur dans le provider
      final loginData = Provider.of<LoginData>(context, listen: false);
      loginData.updateUserApp(UserApp()); // Réinitialiser à un utilisateur vide

      // Rediriger vers l'écran principal
      Navigator.pushNamedAndRemoveUntil(
        context,
        MainScreen.idScreen,
        (route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la déconnexion: ${e.toString()}'),
        ),
      );
    }
  }

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
          _buildAdminCard(
            context,
            Icons.logout,
            'Déconnexion',
            () => _signOut(context),
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
