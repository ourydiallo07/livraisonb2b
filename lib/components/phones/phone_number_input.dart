import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PhoneNumberInput extends StatelessWidget {
  final TextEditingController controller;
  final String countryCode;
  final FocusNode? focusNode;
  final String? Function(String?)? validator;

  // ✅ Nouveaux paramètres optionnels pour personnaliser les couleurs
  final Color? labelColor;
  final Color? textColor;
  final Color? borderColor;
  final Color? prefixBackgroundColor;

  const PhoneNumberInput({
    super.key,
    required this.controller,
    required this.countryCode,
    this.focusNode,
    this.validator,
    this.labelColor,
    this.textColor,
    this.borderColor,
    this.prefixBackgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final Color defaultLabelColor = labelColor ?? Colors.white70;
    final Color defaultTextColor = textColor ?? Colors.white;
    final Color defaultBorderColor =
        borderColor ?? Colors.white.withOpacity(0.5);
    final Color defaultPrefixBgColor =
        prefixBackgroundColor ?? Colors.white.withOpacity(0.15);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Préfixe avec bordure arrondie
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Préfixe',
                  style: TextStyle(
                    fontSize: 14,
                    color: defaultLabelColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: defaultPrefixBgColor, // ✅ Fond semi-transparent
                    border: Border.all(color: defaultBorderColor),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    countryCode,
                    style: TextStyle(
                      fontSize: 16,
                      color: defaultTextColor,
                      fontWeight: FontWeight.bold,
                    ),
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
                  Text(
                    'Numéro de téléphone',
                    style: TextStyle(
                      fontSize: 14,
                      color: defaultLabelColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: controller,
                    focusNode: focusNode,
                    keyboardType: TextInputType.phone,
                    style: TextStyle(color: defaultTextColor, fontSize: 16),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(9),
                    ],
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      filled: true,
                      fillColor: Colors.white.withOpacity(
                        0.1,
                      ), // ✅ Fond semi-transparent
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: defaultBorderColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: defaultBorderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFF4CAF50),
                          width: 2,
                        ),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Colors.redAccent,
                          width: 1.5,
                        ),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Colors.redAccent,
                          width: 2,
                        ),
                      ),
                      hintText: 'Ex: 612345678',
                      hintStyle: TextStyle(
                        color: defaultTextColor.withOpacity(0.5),
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
