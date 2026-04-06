import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:livraisonb2b/account/edit_profile.dart';
import 'package:livraisonb2b/global_utils/utils.dart';
import 'package:livraisonb2b/models/app_user.dart';
import 'package:livraisonb2b/provider_data/Login_data.dart';
import 'package:livraisonb2b/provider_data/app_data.dart';
import 'package:livraisonb2b/services/aws_services.dart';
import 'package:provider/provider.dart';

class UserService {
  // ignore: constant_identifier_names
  static const String USERS_REF = "USERS";

  // ignore: constant_identifier_names
  static const int USER_BONUS = 3;
  static final currentUserId = Utils.calculateSHA256(
    FirebaseAuth.instance.currentUser?.phoneNumber ?? "",
  );

  static final db = FirebaseFirestore.instance;

  static Future<void> createUserApp(UserApp userApp) {
    userApp.bonus = USER_BONUS;
    return db
        .collection(USERS_REF)
        .doc(userApp.id)
        .set(userApp.toFirestore(), SetOptions(merge: true));
  }

  static CollectionReference getUserCollection() {
    return db.collection(USERS_REF);
  }

  static Future<UserApp?> getUserFromDB(String userId) async {
    final docRef = getUserCollection()
        .doc(userId)
        .withConverter(
          fromFirestore: UserApp.fromFirestore,
          toFirestore: (UserApp userApp, _) => userApp.toFirestore(),
        );

    final docSnap = await docRef.get();
    return docSnap.data();
  }

  static Future<UserApp?> getCurrentLoggedUser() async {
    final docRef = getUserCollection()
        .doc(currentUserId)
        .withConverter(
          fromFirestore: UserApp.fromFirestore,
          toFirestore: (UserApp userApp, _) => userApp.toFirestore(),
        );

    final docSnap = await docRef.get();
    return docSnap.data();
  }

  static Future<void> updateUserBonus(String userId, int bonus) async {
    await db.collection(USERS_REF).doc(userId).update({
      'bonus': bonus,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // stream current user
  static Stream<DocumentSnapshot<UserApp>> streamCurrentLoggedUser() {
    return getUserCollection()
        .doc(currentUserId)
        .withConverter(
          fromFirestore: UserApp.fromFirestore,
          toFirestore: (UserApp userApp, _) => userApp.toFirestore(),
        )
        .snapshots();
  }

  static Future<void> updateUserApp(UserApp user) {
    return getUserCollection()
        .doc(user.id)
        .set(user.toMap(), SetOptions(merge: true));
  }

  static Future<void> deleteUser(String userId) {
    return getUserCollection().doc(userId).delete();
  }

  static Future<void> updateCurrentLoggedUser(LoginData loginData) async {
    if (FirebaseAuth.instance.currentUser != null) {
      String userId = FirebaseAuth.instance.currentUser?.uid ?? "";
      UserApp? userApp = await getUserFromDB(userId);

      if (userApp != null) {
        if (userApp.imageKey != null) {
          userApp.profileUrl = await AwsServices.downloadPicture(
            keyName: userApp.imageKey!,
          );
        }

        loginData.updateUserApp(userApp);
        loginData.updateProfileImage(userApp.profileUrl);
      }
    }
  }

  static Future<void> selectImage(context, LoginData loginData) async {
    bool? isCamera = await showDialog(
      context: context,
      builder: (context) => const ImageDialog(),
    );
    if (isCamera == null) {
      return;
    }
    final appData = Provider.of<AppData>(context, listen: false);
    Utils.showLoadingDialog(context);
    await UserService.pickImage(
      isCamera ? ImageSource.camera : ImageSource.gallery,
      loginData,
      appData,
    );
    UserApp currentUserApp = loginData.getUserApp;
    if (currentUserApp.profileUrl != null) {
      loginData.updateProfileImage(currentUserApp.profileUrl!);
    } else {
      customPrint("User profile url is not set ");
    }
    if (context.mounted) {
      Navigator.pop(context);
    }
  }

  static Future<void> pickImage(
    ImageSource source,
    LoginData loginData,
    AppData appData,
  ) async {
    final imagePicked = ImagePicker();
    XFile? file = await imagePicked.pickImage(source: source);
    if (file != null) {
      File imageFile = File(file.path);
      File compressedFile = await Utils.compressFile(imageFile);
      await AwsServices.uploadProfile(compressedFile, loginData, appData);
    }
  }

  // Ajoute dans lib/services/user_service.dart
  static Future<void> promoteToAdmin(String userId) async {
    await db.collection(USERS_REF).doc(userId).update({'isAdmin': true});
  }

  static Future<void> demoteFromAdmin(String userId) async {
    await db.collection(USERS_REF).doc(userId).update({'isAdmin': false});
  }

  static Future<List<UserApp>> getAdmins() async {
    final snapshot =
        await db
            .collection(USERS_REF)
            .where('isAdmin', isEqualTo: true)
            .withConverter(
              fromFirestore: UserApp.fromFirestore,
              toFirestore: (UserApp userApp, _) => userApp.toFirestore(),
            )
            .get();

    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  static Future<void> updateUserAdminStatus(String userId, bool isAdmin) async {
    await db.collection(USERS_REF).doc(userId).update({'isAdmin': isAdmin});
  }

  // Ajoutez cette méthode
  static Future<void> updateUserLocation({
    required String userId,
    required String address,
    required GeoPoint location,
  }) async {
    await db.collection(USERS_REF).doc(userId).update({
      'address': address,
      'location': location,
      'lastLocationUpdate': FieldValue.serverTimestamp(),
    });
  }

  // Dans UserService
  static Future<void> createInitialAdmin(String phoneNumber) async {
    String adminId = Utils.calculateSHA256(phoneNumber);
    UserApp adminUser = UserApp(
      id: adminId,
      phone: phoneNumber,
      firstName: "Admin",
      lastName: "User",
      isAdmin: true,
    );
    await createUserApp(adminUser);
  }

  static Future<void> promoteToAgent(String userId) async {
    await db.collection(USERS_REF).doc(userId).update({
      'isAgent': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Rétrograder un agent
  static Future<void> demoteFromAgent(String userId) async {
    await db.collection(USERS_REF).doc(userId).update({
      'isAgent': false,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Récupérer tous les agents
  static Stream<QuerySnapshot> getAgentsStream() {
    return db
        .collection(USERS_REF)
        .where('isAgent', isEqualTo: true)
        .snapshots();
  }

  // Récupérer la liste des agents avec conversion en UserApp
  static Stream<List<UserApp>> getAgentsListStream() {
    return db
        .collection(USERS_REF)
        .where('isAgent', isEqualTo: true)
        .withConverter(
          fromFirestore: UserApp.fromFirestore,
          toFirestore: (UserApp userApp, _) => userApp.toFirestore(),
        )
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  // Récupérer les agents de manière asynchrone
  static Future<List<UserApp>> getAgents() async {
    final snapshot =
        await db
            .collection(USERS_REF)
            .where('isAgent', isEqualTo: true)
            .withConverter(
              fromFirestore: UserApp.fromFirestore,
              toFirestore: (UserApp userApp, _) => userApp.toFirestore(),
            )
            .get();

    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  // Mettre à jour le statut d'agent
  static Future<void> updateUserAgentStatus(String userId, bool isAgent) async {
    await db.collection(USERS_REF).doc(userId).update({
      'isAgent': isAgent,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Vérifier si un utilisateur est agent
  static Future<bool> isUserAgent(String userId) async {
    final user = await getUserFromDB(userId);
    return user?.isAgent ?? false;
  }

  // Récupérer tous les utilisateurs (pour la sélection des clients par les agents)
  static Stream<List<UserApp>> getAllUsersStream() {
    return db
        .collection(USERS_REF)
        .where('isAdmin', isEqualTo: false) // Exclure les admins
        .withConverter(
          fromFirestore: UserApp.fromFirestore,
          toFirestore: (UserApp userApp, _) => userApp.toFirestore(),
        )
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  // Rechercher des utilisateurs par nom, prénom ou téléphone
  static Future<List<UserApp>> searchUsers(String query) async {
    final snapshot =
        await db
            .collection(USERS_REF)
            .where('isAdmin', isEqualTo: false)
            .withConverter(
              fromFirestore: UserApp.fromFirestore,
              toFirestore: (UserApp userApp, _) => userApp.toFirestore(),
            )
            .get();

    final allUsers = snapshot.docs.map((doc) => doc.data()).toList();

    // Filtrage local par recherche
    return allUsers.where((user) {
      final searchLower = query.toLowerCase();
      return user.firstName?.toLowerCase().contains(searchLower) == true ||
          user.lastName?.toLowerCase().contains(searchLower) == true ||
          user.phone?.toLowerCase().contains(searchLower) == true;
    }).toList();
  }

  // Dans UserService
  static Future<List<UserApp>> getAllNonAdminUsers() async {
    try {
      final snapshot =
          await db
              .collection(USERS_REF)
              .where('isAdmin', isEqualTo: false)
              .withConverter(
                fromFirestore: UserApp.fromFirestore,
                toFirestore: (UserApp userApp, _) => userApp.toFirestore(),
              )
              .get();

      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      debugPrint('Erreur récupération utilisateurs: $e');
      return [];
    }
  }
}
