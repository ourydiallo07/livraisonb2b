import 'package:flutter/material.dart';
import 'package:livraisonb2b/account/registration_screen.dart';
import 'package:livraisonb2b/constants/theme.dart';
import 'package:livraisonb2b/home/home_screen.dart';
import 'package:livraisonb2b/home/tab_screen/commandes_screen.dart';
import 'package:livraisonb2b/home/tab_screen/panier_screen.dart';
import 'package:livraisonb2b/home/tab_screen/profil_screen.dart';
import 'package:livraisonb2b/account/Admin/admin_home_screen.dart';
import 'package:livraisonb2b/provider_data/Login_data.dart';
import 'package:provider/provider.dart';

class MainScreen extends StatefulWidget {
  static const String idScreen = "main_screen";

  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  List<Widget> _getUserScreens() {
    return [
      const HomeScreen(),
      const PanierScreen(),
      const CommandesScreen(),
      const ProfilScreen(),
    ];
  }

  List<Widget> _getAdminScreens() {
    return [
      const HomeScreen(),
      const PanierScreen(),
      const CommandesScreen(),
      const AdminHomeScreen(),
    ];
  }

  List<BottomNavigationBarItem> _getUserNavItems() {
    return const [
      BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Accueil'),
      BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Panier'),
      BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Commandes'),
      BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
    ];
  }

  List<BottomNavigationBarItem> _getAdminNavItems() {
    return const [
      BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Accueil'),
      BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Panier'),
      BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Commandes'),
      BottomNavigationBarItem(
        icon: Icon(Icons.admin_panel_settings),
        label: 'Admin',
      ),
    ];
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final loginData = Provider.of<LoginData>(context);
    final user = loginData.currentUserApp;

    // Vérifier si l'utilisateur est connecté
    if (user.phone == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          RegistrationScreen.idScreen,
          (route) => false,
        );
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Déterminer si c'est un admin (en utilisant isAdmin comme dans votre AuthService)
    final isAdmin = user.isAdmin == true;

    final screens = isAdmin ? _getAdminScreens() : _getUserScreens();
    final navItems = isAdmin ? _getAdminNavItems() : _getUserNavItems();

    return Scaffold(
      body: screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        selectedItemColor: AppColors.primaryGreen,
        unselectedItemColor: AppColors.textGrey,
        backgroundColor: AppColors.backgroundWhite,
        type: BottomNavigationBarType.fixed,
        items: navItems,
      ),
    );
  }
}
