import 'package:flutter/material.dart';
import 'package:livraisonb2b/components/buttons/custom_button.dart';
import 'package:livraisonb2b/global_utils/utils.dart';
import 'package:livraisonb2b/main_screen.dart';
import 'package:livraisonb2b/models/app_user.dart';
import 'package:livraisonb2b/provider_data/Login_data.dart';
import 'package:livraisonb2b/services/user_service.dart';
import 'package:provider/provider.dart';

class EditProfile extends StatefulWidget {
  static const String idScreen = "edit_profile";

  const EditProfile({super.key});

  @override
  State<EditProfile> createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();

  final _lastNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    initUserProfile();
  }

  Future<void> initUserProfile() async {
    final loginData = Provider.of<LoginData>(context, listen: false);
    await UserService.updateCurrentLoggedUser(loginData);

    loginData.updateProfileImage(loginData.currentUserApp.profileUrl);
    // setState(() {
    //   _profileImage = currentUserApp.profileUrl;
    // });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LoginData>(
      builder: (context, loginData, child) {
        return Form(
          key: _formKey,
          child: Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: SafeArea(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: [
                  Column(
                    children: [
                      const SizedBox(height: 60),
                      Text(
                        'Profile',
                        style: Theme.of(context).textTheme.headlineLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 60.0),

                  const SizedBox(height: 60.0),

                  // FirstName
                  TextFormField(
                    controller: _firstNameController,
                    validator: validate,
                    decoration: const InputDecoration(
                      isDense: true,
                      labelText: 'Prénom',
                      focusedBorder: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12.0),
                  // name
                  TextFormField(
                    controller: _lastNameController,
                    validator: validate,
                    keyboardType: TextInputType.name,
                    decoration: const InputDecoration(
                      labelText: 'Nom',
                      isDense: true,
                      focusedBorder: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 60.0),

                  CustomButton(
                    fullWidth: true,
                    customPadding: const EdgeInsets.symmetric(horizontal: 50),
                    onPressedAction: () {
                      saveUserInfos(context);
                    },
                    label: "Valider",
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String shorthenName(LoginData loginData) {
    return loginData.currentUserApp.firstName == null &&
            loginData.currentUserApp.lastName == null
        ? "Ajouter"
        : "${loginData.currentUserApp.firstName?.substring(0, 1)}${loginData.currentUserApp.lastName?.substring(0, 1)}";
  }

  // save UserInfos
  void saveUserInfos(BuildContext context) {
    final loginData = Provider.of<LoginData>(context, listen: false);
    UserApp currentUserApp = loginData.getUserApp;
    if (_formKey.currentState!.validate()) {
      currentUserApp.firstName = _firstNameController.text;
      currentUserApp.lastName = _lastNameController.text;
      loginData.updateUserApp(currentUserApp);
      UserService.updateUserApp(currentUserApp);
      Navigator.pop(context);
      Navigator.pushNamedAndRemoveUntil(
        context,
        MainScreen.idScreen,
        (route) => false,
      );
    } else {
      displayMessage("Entrez votre prenom et nom", context, true);
    }
  }

  // Display profile
  // valide textfield
  String? validate(String? value) {
    if (value == null || value.isEmpty) {
      return 'Le champ ne pas être vide';
    }
    return null;
  }
}

// image dialog
class ImageDialog extends StatelessWidget {
  const ImageDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(true);
            },
            child: const Column(
              children: [
                Icon(Icons.camera_alt_outlined, size: 42),
                Text("Appareil"),
              ],
            ),
          ),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(false);
            },
            child: const Column(
              children: [
                Icon(Icons.image_search_sharp, size: 42),
                Text("Galerie"),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
