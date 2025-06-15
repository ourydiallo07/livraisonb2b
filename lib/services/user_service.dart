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
}
