import 'package:flutter/material.dart';
import 'package:livraisonb2b/components/phones/phone_number_input.dart';
import 'package:livraisonb2b/global_utils/utils.dart';
import 'package:livraisonb2b/provider_data/Login_data.dart';
import 'package:livraisonb2b/services/auth_service.dart';
import 'package:provider/provider.dart';

class RegistrationScreen extends StatefulWidget {
  static const String idScreen = '/registration';

  const RegistrationScreen({Key? key}) : super(key: key);

  @override
  _RegistrationScreenState createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();

  final _phoneController = TextEditingController();
  final _focusNode = FocusNode();
  final String _countryCode = '+224';
  final Color primaryColor = const Color(0xFF4CAF50);

  @override
  void dispose() {
    _phoneController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(24.0),
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Saisissez votre numéro de téléphone pour recevoir un code de confirmation de notre part dessus.',
                  style: TextStyle(fontSize: 16, color: Colors.black87),
                ),
                const SizedBox(height: 40),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      PhoneNumberInput(
                        controller: _phoneController,
                        countryCode: _countryCode,
                        focusNode: _focusNode,
                      ),
                      const SizedBox(height: 30),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            final loginData = Provider.of<LoginData>(
                              context,
                              listen: false,
                            );
                            loginData.authPhoneNumber =
                                _countryCode + _phoneController.text.trim();
                            registerUser(context, loginData);
                          },

                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'RECEVOIR LE CODE',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> registerUser(BuildContext context, LoginData loginData) async {
    String phoneNumber = loginData.authPhoneNumber ?? "";

    if (_formKey.currentState?.validate() == true && phoneNumber.isNotEmpty) {
      AuthService.sendOTP(phoneNumber, context);
    } else {
      displayMessage("Entrer un numéro valide", context, true);
    }
  }
}
