import 'package:flutter/material.dart';
import 'package:livraisonb2b/constants/theme.dart';
import 'package:livraisonb2b/home/home_screen.dart';
import 'package:livraisonb2b/home/tab_screen/commandes_screen.dart';
import 'package:livraisonb2b/home/tab_screen/panier_screen.dart';
import 'package:livraisonb2b/home/tab_screen/profil_screen.dart';

class MainScreen extends StatefulWidget {
  static const String idScreen = "main_screen";

  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const PanierScreen(),
    const CommandesScreen(),
    const ProfilScreen(),
  ];

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        selectedItemColor: AppColors.primaryGreen,
        unselectedItemColor: AppColors.textGrey,
        backgroundColor: AppColors.backgroundWhite,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Accueil'),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Panier',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Commandes'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }
}
