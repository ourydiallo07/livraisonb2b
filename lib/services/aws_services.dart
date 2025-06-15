import 'dart:io';

// Importations nécessaires pour Amplify
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:livraisonb2b/models/app_user.dart';
import 'package:livraisonb2b/provider_data/Login_data.dart';
import 'package:livraisonb2b/provider_data/app_data.dart';
import 'package:livraisonb2b/services/user_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/v4.dart';

class AwsServices {
  // Dossier pour les profils utilisateurs
  static const String USER_FOLDER = "USERS_PROFILE";

  // Dossier pour les messages audio
  static const String AUDIO_MSG = "AUDIO_MSG";

  static const String PREFIX = "public/";

  static const String bucketName =
      'livraisonb2b72b16536a66a4280b2e86a3ab5ea3671ae459-dev';
  static const String region = 'us-east-1'; // Adaptez la région si nécessaire

  static Future<void> uploadProfile(
    File file,
    LoginData loginData,
    AppData appData,
  ) async {
    UserApp currentUserApp = loginData.getUserApp;
    String keyName = "$USER_FOLDER/${currentUserApp.id!}";

    await uploadFile(file, keyName, appData);

    // Générer URL publique permanente
    currentUserApp.profileUrl = getPublicUrl(keyName: keyName);
    currentUserApp.imageKey = keyName;

    loginData.updateUserApp(currentUserApp);
    UserService.updateUserApp(currentUserApp);
  }
  // Préfixe pour les fichiers publics

  static Future<void> uploadFile(
    File file,
    String keyName,
    AppData appData,
  ) async {
    try {
      appData.updateS3StateUploading(true);
      final awsFile = AWSFile.fromPath(
        file.path,
      ); // Utilise le chemin du fichier

      final uploadResult =
          await Amplify.Storage.uploadFile(
            localFile: awsFile,
            path: StoragePath.fromString("$PREFIX$keyName"),
            onProgress: (progress) {
              safePrint('fraction totalBytes: ${progress.totalBytes}');
              safePrint(
                'fraction transferredBytes: ${progress.transferredBytes}',
              );
              safePrint('fraction completed: ${progress.fractionCompleted}');
              appData.updateS3Progress(progress.fractionCompleted);
            },
          ).result;
      safePrint('Uploaded file: ${uploadResult.uploadedItem.path}');
    } on StorageException catch (e) {
      safePrint('Error uploading file: ${e.message}');

      rethrow;
    } finally {
      safePrint("Upload of file  completed");
      appData.updateS3StateUploading(false);
    }
  }

  static Future<String?> downloadPicture({required String keyName}) async {
    final documentsDir = await getTemporaryDirectory();
    final filepath = '${documentsDir.path}/${const UuidV4().generate()}';
    try {
      final result =
          await Amplify.Storage.downloadFile(
            path: StoragePath.fromString("$PREFIX$keyName"),
            localFile: AWSFile.fromPath(filepath),
            onProgress: (progress) {
              safePrint('fraction totalBytes: ${progress.totalBytes}');
              safePrint(
                'fraction transferredBytes: ${progress.transferredBytes}',
              );
              safePrint('fraction completed: ${progress.fractionCompleted}');
            },
          ).result;
      safePrint('Downloaded file is located at: ${result.localFile.path}');
      return result.localFile.path;
    } on StorageException catch (e) {
      safePrint("Failed to download file: ${e.message}");
      rethrow;
    }
  }

  static Future<String> uploadProductImage(File file, AppData appData) async {
    final keyName = "PRODUCTS/${DateTime.now().toIso8601String()}.jpg";
    await uploadFile(file, keyName, appData);
    return getPublicUrl(keyName: keyName);
  }

  // 📤 Générer URL publique permanente à partir du keyName
  static String getPublicUrl({required String keyName}) {
    return 'https://$bucketName.s3.$region.amazonaws.com/$PREFIX$keyName';
  }

  static Future<String?> downloadFile({required String keyName}) async {
    final documentsDir = await getTemporaryDirectory();
    final filepath = '${documentsDir.path}/${const UuidV4().generate()}.pdf';
    try {
      final result =
          await Amplify.Storage.downloadFile(
            path: StoragePath.fromString("$PREFIX$keyName"),
            localFile: AWSFile.fromPath(filepath),
          ).result;
      safePrint('Downloaded file is located at: ${result.localFile.path}');
      return result.localFile.path;
    } on StorageException catch (e) {
      safePrint("Failed to download file: ${e.message}");
      rethrow;
    }
  }
}
