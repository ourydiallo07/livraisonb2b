import 'package:flutter/material.dart';
import 'package:livraisonb2b/constants/theme.dart';
import 'package:livraisonb2b/main_screen.dart';
import 'package:livraisonb2b/models/app_user.dart';
import 'package:livraisonb2b/services/auth_service.dart';
import 'package:livraisonb2b/provider_data/Login_data.dart';
import 'package:provider/provider.dart';

class ProfilScreen extends StatefulWidget {
  const ProfilScreen({super.key});

  @override
  State<ProfilScreen> createState() => _ProfilScreenState();
}

class _ProfilScreenState extends State<ProfilScreen> {
  Future<void> _signOut(BuildContext context) async {
    try {
      // Appeler la méthode de déconnexion du service d'authentification
      await AuthService.signOutAppUser();

      // Réinitialiser les données de l'utilisateur dans le provider
      final loginData = Provider.of<LoginData>(context, listen: false);
      loginData.updateUserApp(UserApp()); // Réinitialiser à un utilisateur vide

      // Rediriger vers l'écran principal (qui devrait rediriger vers le login)
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          MainScreen.idScreen,
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la déconnexion: ${e.toString()}'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loginData = Provider.of<LoginData>(context);
    final UserApp currentUser = loginData.currentUserApp;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Profil"),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.secondaryGreen,
                  border: Border.all(color: AppColors.primaryGreen, width: 2),
                ),
                child: Icon(
                  Icons.photo_camera,
                  size: 40,
                  color: AppColors.primaryGreen,
                ),
              ),
            ),

            const SizedBox(height: 16),

            Center(
              child: Text(
                "${currentUser.firstName ?? ''} ${currentUser.lastName ?? ''}"
                        .trim()
                        .isEmpty
                    ? "Utilisateur"
                    : "${currentUser.firstName} ${currentUser.lastName}",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Option: Numéro de téléphone (non modifiable)
            _buildInfoDisplay(
              icon: Icons.phone,
              title: "Numéro de téléphone",
              value:
                  currentUser.phone?.isNotEmpty == true
                      ? currentUser.phone!
                      : "Non renseigné",
            ),

            const SizedBox(height: 16),

            // Option 1: Modifier mon profil
            _buildProfileOption(
              icon: Icons.edit,
              title: "Modifier mon profil",
              onTap: () {
                // Ajouter la navigation vers l'écran de modification du profil
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Fonctionnalité à implémenter")),
                );
              },
            ),

            const SizedBox(height: 16),

            // Option 3: Déconnexion
            _buildProfileOption(
              icon: Icons.logout,
              title: "Déconnexion",
              color: Colors.orange,
              onTap: () => _signOut(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color color = AppColors.primaryGreen,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: color, size: 24),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: color == AppColors.primaryGreen ? AppColors.textDark : color,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: AppColors.textGrey,
        ),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  Widget _buildInfoDisplay({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: AppColors.textGrey, size: 24),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppColors.textDark,
          ),
        ),
        subtitle: Text(
          value,
          style: TextStyle(fontSize: 14, color: AppColors.textGrey),
        ),
        // Pas de trailing arrow pour les informations non modifiables
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
    );
  }
}
