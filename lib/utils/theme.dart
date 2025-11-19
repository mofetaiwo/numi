import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    primarySwatch: Colors.green,
    primaryColor: Colors.green[600],
    scaffoldBackgroundColor: Colors.grey[50],
    fontFamily: 'Poppins',
    appBarTheme: AppBarTheme(
      elevation: 0,
      backgroundColor: Colors.green[600],
      foregroundColor: Colors.white,
      titleTextStyle: const TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
        fontFamily: 'Poppins',
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green[600],
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    primarySwatch: Colors.green,
    primaryColor: Colors.green[400],
    scaffoldBackgroundColor: Colors.grey[900],
    brightness: Brightness.dark,
    fontFamily: 'Poppins',
    appBarTheme: AppBarTheme(
      elevation: 0,
      backgroundColor: Colors.grey[850],
      foregroundColor: Colors.white,
      titleTextStyle: const TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
        fontFamily: 'Poppins',
      ),
    ),
  );
}