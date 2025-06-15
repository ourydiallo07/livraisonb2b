import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:livraisonb2b/account/edit_profile.dart';
import 'package:livraisonb2b/account/otp_input_screen.dart';
import 'package:livraisonb2b/global_utils/utils.dart';
import 'package:livraisonb2b/home/home_screen.dart';
import 'package:livraisonb2b/main_screen.dart';
import 'package:livraisonb2b/models/app_user.dart';
import 'package:livraisonb2b/provider_data/Login_data.dart';
import 'package:livraisonb2b/services/user_service.dart';

import 'package:provider/provider.dart';

class AuthService {
  static final _firebaseAuth = FirebaseAuth.instance;

  static int? _resendToken;

  /// Sends a one-time password (OTP) to the specified phone number.
  ///
  /// This function initiates the phone number verification process using Firebase Authentication.
  ///
  /// Parameters:
  ///   phoneNumber (String): The phone number to which the OTP should be sent.
  ///   context (BuildContext): The build context of the current widget.
  ///   isResend (bool): Optional parameter to specify whether this is a resend attempt. Defaults to false.
  ///
  /// Returns:
  ///   void: This function does not return any value.
  static void sendOTP(
    String phoneNumber,
    BuildContext context, {
    bool isResend = false,
  }) async {
    if (context.mounted) {
      await _firebaseAuth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: Duration(seconds: Utils.expireTimer),
        verificationCompleted: (PhoneAuthCredential credential) {
          verificationCompleted(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          verificationFailed(e, context);
        },
        codeSent: (String verificationId, int? resendToken) {
          codeSent(verificationId, resendToken, context);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          codeAutoRetrievalTimeout(verificationId, context);
        },
        forceResendingToken: isResend ? _resendToken : null,
      );
    }
  }

  static void codeAutoRetrievalTimeout(
    String verificationId,
    BuildContext context,
  ) {
    customPrint('SMS code auto retrieval timeout');
  }

  static Future<void> codeSent(
    String verificationId,
    int? resendToken,
    BuildContext context,
  ) async {
    final loginData = Provider.of<LoginData>(context, listen: false);
    loginData.setAUthCode(verificationId, resendToken);
    _resendToken = resendToken;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => OtpInputScreen(
              validateConfirmationCode: _validateConfirmationCode,
              resendCode:
                  () => sendOTP(
                    loginData.currentUserApp.phone!,
                    context,
                    isResend: true,
                  ),
            ),
      ),
    );

    if (context.mounted) {
      Navigator.pop(context);
    }
  }

  static Future<void> _validateConfirmationCode(
    BuildContext context,
    String? smsCode,
  ) async {
    final loginProvider = Provider.of<LoginData>(context, listen: false);
    PhoneAuthCredential credential = PhoneAuthProvider.credential(
      verificationId: loginProvider.verificationId,
      smsCode: smsCode ?? "",
    );
    final firebaseAuth = FirebaseAuth.instance;

    try {
      final userCredential = await firebaseAuth.signInWithCredential(
        credential,
      );
      if (userCredential.user?.phoneNumber != null) {
        var firebaseUser = userCredential.user;

        String userId = Utils.calculateSHA256(firebaseUser!.phoneNumber!);

        UserApp? userApp = await UserService.getUserFromDB(userId);

        if (userApp == null) {
          UserApp newUserApp = UserApp();
          newUserApp.id = userId;
          newUserApp.phone = firebaseUser.phoneNumber;

          loginProvider.updateUserApp(newUserApp);
          UserService.createUserApp(newUserApp);

          if (context.mounted) {
            displayMessage("Compte créé", context, false);
            Navigator.pushNamedAndRemoveUntil(
              context,
              EditProfile.idScreen,
              (route) => false,
            );
          }
        } else {
          loginProvider.updateUserApp(userApp);

          if (context.mounted) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              MainScreen.idScreen,
              (route) => false,
            );
          }
        }
      }
    } on FirebaseAuthException catch (error) {
      if (context.mounted) {
        displayMessage("Le code de vérification est invalide", context, true);

        customPrint(error);
      }
    } catch (e) {
      if (context.mounted) {
        customPrint(e.toString());
        displayMessage("Le code de vérification est invalide", context, true);
      }
    }
  }

  static void verificationFailed(
    FirebaseAuthException e,
    BuildContext context,
  ) {
    customPrint(e.message);
    if (context.mounted) {
      Navigator.pop(context);
    }
    displayMessage("Code invalide,réessayer", context, true);
  }

  static Future<void> verificationCompleted(
    PhoneAuthCredential credential,
  ) async {
    if (Platform.isAndroid) {
      await _firebaseAuth.signInWithCredential(credential);
    }
    customPrint("Vérification completed");
  }

  static Future<void> signOutAppUser() async {
    await _firebaseAuth.signOut();
  }
}
