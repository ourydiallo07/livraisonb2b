import 'package:flutter/material.dart';

class AppColors {
  static const Color primaryGreen = Color(0xFF4CAF50);
  static const Color secondaryGreen = Color(
    0xFFCCE3D1,
  ); // vert clair (Register)
  static const Color backgroundWhite = Color(0xFFFFFFFF);
  static const Color textDark = Color(0xFF333333);
  static const Color textGrey = Color(0xFF666666);
  static const Color borderGrey = Color(0xFFE0E0E0);
}

final ThemeData appTheme = ThemeData(
  primaryColor: AppColors.primaryGreen,
  scaffoldBackgroundColor: AppColors.backgroundWhite,
  textTheme: TextTheme(bodyMedium: TextStyle(color: AppColors.textDark)),
  inputDecorationTheme: InputDecorationTheme(
    border: OutlineInputBorder(
      borderSide: BorderSide(color: AppColors.borderGrey),
      borderRadius: BorderRadius.circular(8),
    ),
    filled: true,
    fillColor: AppColors.backgroundWhite,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.primaryGreen,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
  ),
);
