import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_storage_s3/amplify_storage_s3.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import 'package:livraisonb2b/account/Admin/admin_home_screen.dart';
import 'package:livraisonb2b/account/Admin/admin_orders_screen.dart';
import 'package:livraisonb2b/account/Admin/admin_stats_screen.dart';
import 'package:livraisonb2b/account/Admin/admin_users_screen.dart';
import 'package:livraisonb2b/account/add_product_screen.dart';
import 'package:livraisonb2b/account/edit_profile.dart';
import 'package:livraisonb2b/amplifyconfiguration.dart';
import 'package:livraisonb2b/constants/theme.dart';
import 'package:livraisonb2b/home/home_screen.dart';
import 'package:livraisonb2b/home/tab_screen/commandes_screen.dart';
import 'package:livraisonb2b/main_screen.dart';
import 'package:livraisonb2b/provider_data/Login_data.dart';
import 'package:livraisonb2b/provider_data/app_data.dart';
import 'package:livraisonb2b/provider_data/cart_provider.dart';
import 'package:livraisonb2b/provider_data/order_provider.dart';
import 'package:livraisonb2b/provider_data/product_provider.dart';
import 'package:provider/provider.dart';
import 'package:livraisonb2b/account/registration_screen.dart';
import 'package:livraisonb2b/firebase_options.dart';

Future<void> _configureAmplify() async {
  try {
    await Amplify.addPlugins([AmplifyAuthCognito(), AmplifyStorageS3()]);
    await Amplify.configure(amplifyconfig);
    debugPrint('✅ Amplify configuré avec succès');
  } on Exception catch (e) {
    debugPrint('⚠️ Erreur Amplify (fonctionnalités réduites): $e');
    // L'application peut continuer sans Amplify en mode dégradé
  }
}

Future<void> _configureFirebaseEmulators() async {
  final host = Platform.isAndroid ? '10.0.2.2' : 'localhost';

  try {
    // Configuration Firestore
    FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
    //await FirebaseFirestore.instance.disableNetwork();

    // Configuration Auth
    await FirebaseAuth.instance.useAuthEmulator(host, 9099);

    debugPrint('🔥 Émulateurs actifs sur $host');
  } catch (e, stack) {
    debugPrint('''⚠️ Mode émulateur désactivé:
    Erreur: $e
    Stack: $stack''');
    // Fallback automatique en production
    FirebaseFirestore.instance.settings = Settings(persistenceEnabled: true);
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialisation Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Mode développement seulement
  if (kDebugMode) {
    await _configureFirebaseEmulators();

    // Active les logs détaillés
    FirebaseFirestore.instance.settings = Settings(persistenceEnabled: false);

    // Debug Config
    debugPrint('=== MODE DÉVELOPPEMENT ===');
    debugPrint('• Firestore: émulateur @ 10.0.2.2:8080');
    debugPrint('• Auth: émulateur @ 10.0.2.2:9099');
  }

  // Configuration Amplify (optionnelle)
  await _configureAmplify();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LoginData()),
        ChangeNotifierProvider(create: (_) => AppData()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProxyProvider<LoginData, CartProvider>(
          create: (context) => CartProvider(),
          update: (context, loginData, cart) {
            if (loginData.currentUserApp.id != null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                cart?.loadCart(loginData.currentUserApp.id!);
              });
            }
            return cart ?? CartProvider();
          },
        ),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Livraison B2B',
      theme: appTheme,
      initialRoute: RegistrationScreen.idScreen,
      routes: {
        MainScreen.idScreen: (context) => const MainScreen(),
        RegistrationScreen.idScreen: (context) => RegistrationScreen(),
        EditProfile.idScreen: (context) => const EditProfile(),
        HomeScreen.idScreen: (context) => const HomeScreen(),
        AddProductScreen.idScreen: (context) => const AddProductScreen(),
        CommandesScreen.idScreen: (context) => const CommandesScreen(),
        AdminHomeScreen.idScreen: (context) => const AdminHomeScreen(),
        AdminUsersScreen.idScreen: (context) => const AdminUsersScreen(),
        AdminOrdersScreen.idScreen: (context) => const AdminOrdersScreen(),
        AdminStatsScreen.idScreen: (context) => const AdminStatsScreen(),
      },
    );
  }
}
