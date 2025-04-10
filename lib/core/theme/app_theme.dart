import 'package:flutter/material.dart';

class AppTheme {
  // Colores principales para tema claro (estilo Facebook)
  static const Color primaryColor = Color(0xFF1877F2);      // Azul principal
  static const Color secondaryColor = Color(0xFF42B72A);    // Verde para botones de acción
  static const Color lightBackground = Color(0xFFF0F2F5);   // Fondo gris claro
  static const Color cardColor = Colors.white;              // Tarjetas blancas
  static const Color darkTextColor = Color(0xFF050505);     // Texto oscuro
  static const Color lightTextColor = Color(0xFF65676B);    // Texto gris
  
  // Colores principales para tema oscuro
  static const Color darkPrimaryColor = Color(0xFF1877F2);  // Mantener azul principal
  static const Color darkSecondaryColor = Color(0xFF42B72A); // Mantener verde de acción
  static const Color darkBackground = Color(0xFF18191A);    // Fondo negro
  static const Color darkCardColor = Color(0xFF242526);     // Tarjetas gris oscuro
  static const Color lightDarkTextColor = Colors.white;     // Texto claro
  static const Color secondaryDarkTextColor = Color(0xFFB0B3B8); // Texto gris claro

  // Tema claro
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.light(
      primary: primaryColor,
      secondary: secondaryColor,
      background: lightBackground,
      surface: cardColor,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onBackground: darkTextColor,
      onSurface: darkTextColor,
    ),
    scaffoldBackgroundColor: lightBackground,
    appBarTheme: const AppBarTheme(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    cardTheme: CardTheme(
      color: cardColor,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryColor,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
    fontFamily: 'Montserrat',
    dividerTheme: const DividerThemeData(
      color: Color(0xFFCCD0D5),
      thickness: 1,
    ),
  );

  // Tema oscuro
  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.dark(
      primary: darkPrimaryColor,
      secondary: darkSecondaryColor,
      background: darkBackground,
      surface: darkCardColor,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onBackground: lightDarkTextColor,
      onSurface: lightDarkTextColor,
    ),
    scaffoldBackgroundColor: darkBackground,
    appBarTheme: const AppBarTheme(
      backgroundColor: darkCardColor,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    cardTheme: CardTheme(
      color: darkCardColor,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: darkPrimaryColor,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: darkPrimaryColor,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Color(0xFF3A3B3C),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: darkPrimaryColor, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
    fontFamily: 'Montserrat',
    dividerTheme: const DividerThemeData(
      color: Color(0xFF3A3B3C),
      thickness: 1,
    ),
  );
}