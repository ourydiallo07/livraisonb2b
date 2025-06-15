import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:livraisonb2b/account/registration_screen.dart';
import 'package:livraisonb2b/models/app_user.dart';
import 'package:livraisonb2b/services/user_service.dart';

class LoginData extends ChangeNotifier {
  late StreamSubscription<DocumentSnapshot<UserApp>> listener;

  LoginData() {
    listToUserChange();
  }
  String loginPath = RegistrationScreen.idScreen;
  UserApp currentUserApp = UserApp();

  String? authPhoneNumber;

  var retryText = "";
  String verificationId = "";
  int? resendToken;

  UserApp get getUserApp => currentUserApp;

  void listToUserChange() {
    listener = UserService.streamCurrentLoggedUser().listen((snapSchot) {
      if (snapSchot.data() != null) {
        currentUserApp = snapSchot.data()!;
        notifyListeners();
      }
    });
  }

  /// Updates the user's bonus by creating a total bonus and weight,
  /// then retrieves the current logged user's bonus and updates the
  // /// current user app's bonus if it exists.
  // Future<void> updateUserBonus() async {
  //   double totalBonus = await BonusServices.getTotalBonus();
  //   if (totalBonus == 0.0) {
  //     currentUserApp.bonus = 0;
  //     await UserService.updateUserApp(currentUserApp);
  //     notifyListeners();
  //   } else {
  //     final loggedUser = await UserService.getCurrentLoggedUser();
  //     if (loggedUser != null && loggedUser.bonus != null) {
  //       currentUserApp.bonus = loggedUser.bonus;
  //       notifyListeners();
  //     }
  //   }
  // }

  void setAUthCode(String verificationIdState, int? resendTokenState) {
    verificationId = verificationIdState;
    resendToken = resendTokenState;
  }

  /// Updates the current user app state.
  ///
  /// Parameters:
  ///   state (UserApp): The new state of the user app.
  ///
  /// Returns:
  ///   None
  void updateUserApp(UserApp state) {
    currentUserApp = state;
  }

  /// Updates the user's login state by setting the `loginPath` to the provided `path`.
  ///
  /// Parameters:
  ///   - path: The new login path.
  ///
  /// This function does not return anything. It notifies all the listeners that the login state has been updated.
  void updateUserLoginState(String path) {
    loginPath = path;

    notifyListeners();
  }

  /// Updates the authorization phone number.
  ///
  /// Parameters:
  ///   state (String?): The new authorization phone number.
  ///
  /// Returns:
  ///   None
  void updateAuthPhoneNumber(String? state) {
    authPhoneNumber = state;
  }

  /// Updates the retry text with the provided state and notifies all the listeners.
  ///
  /// Parameters:
  ///   - state: The new state of the retry text.
  ///
  /// This function does not return anything.
  void updateRetryText(String state) {
    retryText = state;
    notifyListeners();
  }

  /// Updates the profile image URL of the current user app.
  ///
  /// Parameters:
  ///   state (String?): The new profile image URL.
  ///
  /// Returns:
  ///   None
  void updateProfileImage(String? state) {
    currentUserApp.profileUrl = state;
    notifyListeners();
  }

  @override
  void dispose() {
    listener.cancel();
    super.dispose();
  }
}
