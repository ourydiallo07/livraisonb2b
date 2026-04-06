import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:livraisonb2b/account/registration_screen.dart';
import 'package:livraisonb2b/models/app_user.dart';
import 'package:livraisonb2b/provider_data/cart_provider.dart';
import 'package:livraisonb2b/services/user_service.dart';
import 'package:provider/provider.dart';

class LoginData extends ChangeNotifier {
  late StreamSubscription<DocumentSnapshot<UserApp>> _userListener;
  String loginPath = RegistrationScreen.idScreen;
  UserApp currentUserApp = UserApp();
  String? authPhoneNumber;
  String retryText = "";
  String verificationId = "";
  int? resendToken;
  bool _isInitialized = false;

  UserApp get getUserApp => currentUserApp;

  void initialize(BuildContext context) {
    if (_isInitialized) return;

    _userListener = UserService.streamCurrentLoggedUser().listen((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        currentUserApp = snapshot.data()!;
        notifyListeners();

        // Charger le panier après mise à jour de l'utilisateur
        _loadUserCart(context);
      }
    });

    _isInitialized = true;
  }

  Future<void> _loadUserCart(BuildContext context) async {
    if (currentUserApp.id == null) return;

    try {
      final cartProvider = Provider.of<CartProvider>(context, listen: false);
      await cartProvider.loadCart(currentUserApp.id!);
    } catch (e) {
      debugPrint('Erreur chargement panier: $e');
    }
  }

  Future<void> handleUserLogin(BuildContext context, UserApp user) async {
    final auth = FirebaseAuth.instance;
    final oldUserId = auth.currentUser?.uid;
    final newUserId = user.id!;

    // Migration du panier si l'utilisateur change
    if (oldUserId != null && oldUserId != newUserId) {
      try {
        final cartProvider = Provider.of<CartProvider>(context, listen: false);
        await cartProvider.migrateCart(oldUserId, newUserId);
      } catch (e) {
        debugPrint('Erreur migration panier: $e');
      }
    }

    // Mettre à jour les données utilisateur
    currentUserApp = user;
    notifyListeners();

    // Charger le panier
    await _loadUserCart(context);
  }

  void setAuthCode(String verificationIdState, int? resendTokenState) {
    verificationId = verificationIdState;
    resendToken = resendTokenState;
    notifyListeners();
  }

  void updateUserApp(UserApp newUserApp) {
    currentUserApp = newUserApp;
    notifyListeners();
  }

  void updateUserLoginState(String path) {
    loginPath = path;
    notifyListeners();
  }

  void updateAuthPhoneNumber(String? phoneNumber) {
    authPhoneNumber = phoneNumber;
    notifyListeners();
  }

  void updateRetryText(String text) {
    retryText = text;
    notifyListeners();
  }

  void updateProfileImage(String? imageUrl) {
    currentUserApp.profileUrl = imageUrl;
    notifyListeners();
  }

  void updateUserAddress({required String address, GeoPoint? location}) {
    currentUserApp = currentUserApp.copyWith(
      address: address,
      location: location,
    );
    notifyListeners();
  }

  void resetAuthState() {
    verificationId = "";
    resendToken = null;
    authPhoneNumber = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _userListener.cancel();
    super.dispose();
  }
}
