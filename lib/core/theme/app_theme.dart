import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ── Monochrome Zinc Palette ──
  static const zinc50 = Color(0xFFFAFAFA);
  static const zinc100 = Color(0xFFF4F4F5);
  static const zinc200 = Color(0xFFE4E4E7);
  static const zinc300 = Color(0xFFD4D4D8);
  static const zinc400 = Color(0xFFA1A1AA);
  static const zinc500 = Color(0xFF71717A);
  static const zinc600 = Color(0xFF52525B);
  static const zinc700 = Color(0xFF3F3F46);
  static const zinc800 = Color(0xFF27272A);
  static const zinc900 = Color(0xFF18181B);
  static const zinc950 = Color(0xFF09090B);

  // Semantic colors (kept minimal for status indicators only)
  static const dangerColor = Color(0xFFEF4444);
  static const warningColor = Color(0xFFF59E0B);

  // Background
  static const bgLight = Color(0xFFF8F9FA);

  // ── Legacy aliases (for existing code that references old names) ──
  static const primaryColor = zinc950;
  static const primaryDark = zinc900;
  static const secondaryColor = zinc700;
  static const accentColor = zinc800;
  static const emerald500 = Color(0xFF10B981);
  static const emerald600 = Color(0xFF059669);
  static const red500 = Color(0xFFEF4444);
  static const red600 = Color(0xFFDC2626);
  static const amber400 = Color(0xFFFBBF24);
  static const amber500 = Color(0xFFF59E0B);
  static const amber600 = Color(0xFFD97706);
  static const bgDark = bgLight;
  static const cardDark = Colors.white;
  static const cardBorder = zinc200;
  static const slate50 = zinc50;
  static const slate100 = zinc100;
  static const slate200 = zinc200;
  static const slate300 = zinc300;
  static const slate400 = zinc400;
  static const slate500 = zinc500;
  static const slate600 = zinc600;
  static const slate700 = zinc700;
  static const slate800 = zinc800;
  static const slate900 = zinc900;

  static TextTheme _plusJakartaTextTheme(TextTheme base) {
    return GoogleFonts.plusJakartaSansTextTheme(base);
  }

  static ThemeData get lightTheme {
    final base = ThemeData.light(useMaterial3: true);
    final textTheme = _plusJakartaTextTheme(base.textTheme);

    return base.copyWith(
      brightness: Brightness.light,
      scaffoldBackgroundColor: bgLight,
      primaryColor: zinc950,
      colorScheme: const ColorScheme.light(
        primary: zinc950,
        onPrimary: Colors.white,
        secondary: zinc700,
        onSecondary: Colors.white,
        surface: Colors.white,
        onSurface: zinc950,
        error: dangerColor,
        onError: Colors.white,
        outline: zinc200,
      ),
      textTheme: textTheme.apply(
        bodyColor: zinc950,
        displayColor: zinc950,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: zinc200, width: 1),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: zinc950),
        titleTextStyle: textTheme.titleMedium?.copyWith(
          color: zinc950,
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: zinc900,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: zinc950,
          side: const BorderSide(color: zinc200),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: zinc50,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: zinc200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: zinc200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: zinc900, width: 2),
        ),
        hintStyle: textTheme.bodySmall?.copyWith(color: zinc400, fontSize: 13),
        labelStyle: textTheme.bodySmall?.copyWith(color: zinc500),
      ),
      dividerTheme: const DividerThemeData(
        color: zinc200,
        thickness: 1,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: zinc950,
        unselectedItemColor: zinc400,
        elevation: 0,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: zinc100,
        side: const BorderSide(color: zinc200),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        labelStyle: textTheme.labelSmall?.copyWith(
          color: zinc900,
          fontWeight: FontWeight.w700,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: zinc900,
        contentTextStyle: textTheme.bodySmall?.copyWith(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Keep darkTheme as alias for backward compatibility
  static ThemeData get darkTheme => lightTheme;
}
