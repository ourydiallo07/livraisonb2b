import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_storage_s3/amplify_storage_s3.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:livraisonb2b/account/add_product_screen.dart';
import 'package:livraisonb2b/account/edit_profile.dart';
import 'package:livraisonb2b/amplifyconfiguration.dart';
import 'package:livraisonb2b/constants/theme.dart';
import 'package:livraisonb2b/home/home_screen.dart';
import 'package:livraisonb2b/main_screen.dart';
import 'package:livraisonb2b/provider_data/Login_data.dart';
import 'package:livraisonb2b/provider_data/app_data.dart';
import 'package:livraisonb2b/provider_data/cart_provider.dart';
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
  try {
    final host = kIsWeb ? 'localhost' : '10.0.2.2';

    FirebaseFirestore.instance.useFirestoreEmulator(
      host,
      8080,
      sslEnabled: false,
    );
    FirebaseDatabase.instance.useDatabaseEmulator(host, 9000);
    await FirebaseAuth.instance.useAuthEmulator(host, 9099);

    debugPrint('✅ Émulateurs configurés sur http://$host');
  } catch (e) {
    debugPrint('❌ Erreur configuration émulateurs: $e');
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: false,
    sslEnabled: false,
    host: '10.0.2.2:8080',
  );

  if (kDebugMode) {
    await _configureFirebaseEmulators();
  }

  await _configureAmplify();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LoginData()),
        ChangeNotifierProvider(create: (_) => AppData()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
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
      },
    );
  }
}
