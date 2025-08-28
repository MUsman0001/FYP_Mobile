import 'package:flutter/material.dart';

class AppTheme {
  // Your project's exact color palette
  static const Color primaryGreen = Color(0xFF00704A);
  static const Color secondaryGreen = Color(0xFF1B825D);
  static const Color accentGreen = Color(0xFF3A9D68);
  static const Color tealGreen = Color(0xFF2F9E8F);
  static const Color darkGreen = Color(0xFF004A31);
  static const Color lightGreen = Color(0xFFE6F3EE);
  static const Color paleGreen = Color(0xFFC9E5DB);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: false, // Use Material 2 to avoid deprecation issues
      primarySwatch: Colors.green,
      primaryColor: primaryGreen,
      scaffoldBackgroundColor: const Color(0xFFF8F9FA),

      // AppBar theme
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),

      // Elevated Button theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),

      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primaryGreen, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF721C24)),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        labelStyle: const TextStyle(
          color: Color(0xFF333333),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
