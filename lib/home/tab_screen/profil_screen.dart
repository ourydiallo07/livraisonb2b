import 'package:flutter/material.dart';
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
    return Scaffold(
      appBar: AppBar(title: const Text("Profil")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Page de profil"),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _signOut(context),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    Colors.red, // Couleur rouge pour le bouton de déconnexion
                foregroundColor: Colors.white,
              ),
              child: const Text('Se déconnecter'),
            ),
          ],
        ),
      ),
    );
  }
}
