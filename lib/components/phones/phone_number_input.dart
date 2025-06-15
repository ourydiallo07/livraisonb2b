import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PhoneNumberInput extends StatelessWidget {
  final TextEditingController controller;
  final String countryCode;
  final FocusNode? focusNode;
  final String? Function(String?)? validator;

  const PhoneNumberInput({
    Key? key,
    required this.controller,
    required this.countryCode,
    this.focusNode,
    this.validator,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Row(
          children: [
            // Préfixe avec bordure arrondie
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Préfixe',
                  style: TextStyle(fontSize: 22, color: Colors.grey),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 27,
                    vertical: 25,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(
                      12,
                    ), // Bordure plus arrondie
                  ),
                  child: Text(
                    countryCode,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            // Champ de numéro avec bordure arrondie
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Numéro de téléphone',
                    style: TextStyle(fontSize: 22, color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  TextFormField(
                    controller: controller,
                    focusNode: focusNode,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(9),
                    ],
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 27,
                        vertical: 25,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          12,
                        ), // Bordure arrondie
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          12,
                        ), // Bordure arrondie
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          12,
                        ), // Bordure arrondie
                        borderSide: const BorderSide(
                          color: Color(0xFF4CAF50),
                          width: 1.5,
                        ),
                      ),
                    ),
                    validator:
                        validator ??
                        (value) {
                          if (value == null || value.isEmpty) {
                            return 'Veuillez entrer votre numéro';
                          }
                          if (value.length < 8) {
                            return 'Numéro trop court';
                          }
                          return null;
                        },
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
