import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const String appName = 'Ride Together';
  static const String appSlogan = 'Cost Efficient & Eco-Friendly';
  static const Color primaryColor = Colors.black;
  static const Color secondaryColor = Colors.white;
  static const Color accentColor = Colors.green;
  static const Color errorColor = Colors.red;
  static const Color greyColor = Color(0xFF757575);

  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: primaryColor,
      scaffoldBackgroundColor: secondaryColor,
      textTheme: GoogleFonts.poppinsTextTheme(
        TextTheme(
          headlineLarge: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: primaryColor,
          ),
          headlineMedium: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: primaryColor,
          ),
          bodyLarge: TextStyle(
            fontSize: 16,
            color: primaryColor,
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            color: greyColor,
          ),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: secondaryColor,
        foregroundColor: primaryColor,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: primaryColor,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: secondaryColor,
          padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: primaryColor),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        labelStyle: TextStyle(color: greyColor),
      ),
      cardTheme: CardTheme(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        color: Colors.grey[50],
      ),
    );
  }
} 