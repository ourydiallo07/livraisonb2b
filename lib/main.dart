import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_storage_s3/amplify_storage_s3.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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
    final auth = AmplifyAuthCognito();
    final storage = AmplifyStorageS3();
    await Amplify.addPlugins([auth, storage]);

    await Amplify.configure(amplifyconfig);
  } on Exception catch (e) {
    safePrint('An error occurred configuring Amplify: $e');
  }
}

Future<void> _configureFirebaseEmulators() async {
  final host = kIsWeb ? 'localhost' : '10.0.2.2';

  try {
    // Configuration atomique
    await FirebaseAuth.instance.useAuthEmulator(host, 9099);

    FirebaseFirestore.instance.settings = Settings(
      host: '$host:8080',
      sslEnabled: false,
      persistenceEnabled: false,
    );

    FirebaseDatabase.instance.useDatabaseEmulator(host, 9000);

    debugPrint('''
✅ Émulateurs configurés:
- Auth: http://$host:9099
- Firestore: http://$host:8080
- Realtime DB: http://$host:9000
''');
  } catch (e, stack) {
    debugPrint('''
❌ Erreur configuration émulateurs:
$e
Stack: $stack
''');
    rethrow;
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialisation Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('✅ Firebase initialisé avec succès');
  } catch (e, stack) {
    debugPrint('❌ Erreur initialisation Firebase: $e\n$stack');
    rethrow;
  }

  // 2. Configuration des émulateurs (debug seulement)
  if (kDebugMode) {
    try {
      await _configureFirebaseEmulators();
    } catch (e, stack) {
      debugPrint('❌ Erreur configuration émulateurs: $e\n$stack');
      // Ne pas bloquer l'application si les émulateurs échouent
    }
  }

  // 3. Configuration Amplify (optionnel)
  try {
    await _configureAmplify();
  } catch (e, stack) {
    debugPrint('⚠ Amplify non configuré: $e\n$stack');
  }
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
        AddProductScreen.idScreen:
            (context) => const AddProductScreen(), // Ajoutez cette ligne
        CommandesScreen.idScreen:
            (context) => const CommandesScreen(), // Ajoutez cette ligne

        AdminHomeScreen.idScreen:
            (context) => const AdminHomeScreen(), // Ajoutez cette ligne

        AdminUsersScreen.idScreen: (context) => const AdminUsersScreen(),

        AdminOrdersScreen.idScreen: (context) => const AdminOrdersScreen(),
        AdminStatsScreen.idScreen: (context) => const AdminStatsScreen(),
      },
    );
  }
}
