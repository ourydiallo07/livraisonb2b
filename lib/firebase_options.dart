// File firebase_options.dart sécurisé avec .env
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Default [FirebaseOptions] for use with your Firebase apps.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for Linux',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform',
        );
    }
  }

  // Web
  static FirebaseOptions web = FirebaseOptions(
    apiKey: dotenv.env['FIREBASE_API_KEY_WEB']!,
    appId: '1:259602366484:web:3c24e77a2422e37f4fa701',
    messagingSenderId: dotenv.env['FIREBASE_SENDER_ID']!,
    projectId: dotenv.env['FIREBASE_PROJECT_ID']!,
    authDomain: '${dotenv.env['FIREBASE_PROJECT_ID']}.firebaseapp.com',
    storageBucket: dotenv.env['FIREBASE_STORAGE_BUCKET']!,
    measurementId: 'G-E5MTMN3GF9',
  );

  // Android
  static FirebaseOptions android = FirebaseOptions(
    apiKey: dotenv.env['FIREBASE_API_KEY_ANDROID']!,
    appId: '1:259602366484:android:917282a2679faa944fa701',
    messagingSenderId: dotenv.env['FIREBASE_SENDER_ID']!,
    projectId: dotenv.env['FIREBASE_PROJECT_ID']!,
    storageBucket: dotenv.env['FIREBASE_STORAGE_BUCKET']!,
  );

  // iOS
  static FirebaseOptions ios = FirebaseOptions(
    apiKey: dotenv.env['FIREBASE_API_KEY_IOS']!,
    appId: '1:259602366484:ios:07427b5a3de138f54fa701',
    messagingSenderId: dotenv.env['FIREBASE_SENDER_ID']!,
    projectId: dotenv.env['FIREBASE_PROJECT_ID']!,
    storageBucket: dotenv.env['FIREBASE_STORAGE_BUCKET']!,
    iosBundleId: 'com.example.livraisonb2b',
  );

  // MacOS
  static FirebaseOptions macos = ios;

  // Windows
  static FirebaseOptions windows = FirebaseOptions(
    apiKey: dotenv.env['FIREBASE_API_KEY_WINDOWS']!,
    appId: '1:259602366484:web:46811fbc26e5108d4fa701',
    messagingSenderId: dotenv.env['FIREBASE_SENDER_ID']!,
    projectId: dotenv.env['FIREBASE_PROJECT_ID']!,
    authDomain: '${dotenv.env['FIREBASE_PROJECT_ID']}.firebaseapp.com',
    storageBucket: dotenv.env['FIREBASE_STORAGE_BUCKET']!,
    measurementId: 'G-RH6D87REFD',
  );
}
