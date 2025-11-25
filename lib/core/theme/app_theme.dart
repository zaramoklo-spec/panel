import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AppTheme {

  static const Color primaryColor = Color(0xFF6366F1);
  static const Color secondaryColor = Color(0xFF8B5CF6);
  static const Color accentColor = Color(0xFFEC4899);
  static const Color successColor = Color(0xFF10B981);
  static const Color warningColor = Color(0xFFF59E0B);
  static const Color errorColor = Color(0xFFEF4444);
  static const Color infoColor = Color(0xFF3B82F6);

  static void setupSystemUI() {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
      overlays: [SystemUiOverlay.top],
    );
  }

  static void syncSystemUI(BuildContext context, {Color? customColor}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = customColor ?? (isDark
        ? const Color(0xFF0B0F19)
        : const Color(0xFFF8FAFC));

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: backgroundColor,
        systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarDividerColor: backgroundColor,
      ),
    );
  }

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: primaryColor,
    scaffoldBackgroundColor: const Color(0xFFF8FAFC),

    colorScheme: const ColorScheme.light(
      primary: primaryColor,
      secondary: secondaryColor,
      surface: Colors.white,
      error: errorColor,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Color(0xFF1E293B),
      onError: Colors.white,
    ),

    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: GoogleFonts.poppins(
        fontSize: 17.6,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF1E293B),
        letterSpacing: -0.5,
      ),
      iconTheme: const IconThemeData(color: Color(0xFF1E293B)),
    ),

    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.24),
      ),
      color: Colors.white,
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFF1F5F9),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.96),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.96),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.96),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.96),
        borderSide: const BorderSide(color: errorColor, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12.8, vertical: 11.2),
      hintStyle: GoogleFonts.inter(
        color: Color(0xFF94A3B8),
        fontSize: 11.2,
      ),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 19.2, vertical: 11.2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.96),
        ),
        textStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryColor,
        textStyle: GoogleFonts.inter(
          fontSize: 11.2,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    chipTheme: ChipThemeData(
      backgroundColor: const Color(0xFFF1F5F9),
      selectedColor: primaryColor.withOpacity(0.15),
      labelStyle: GoogleFonts.inter(fontSize: 10.4, fontWeight: FontWeight.w500),
      padding: const EdgeInsets.symmetric(horizontal: 9.6, vertical: 6.4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6.4),
      ),
    ),

    textTheme: GoogleFonts.interTextTheme(
      const TextTheme(
        displayLarge: TextStyle(fontSize: 25.6, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
        displayMedium: TextStyle(fontSize: 22.4, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
        displaySmall: TextStyle(fontSize: 19.2, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
        headlineMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
        titleLarge: TextStyle(fontSize: 14.4, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
        titleMedium: TextStyle(fontSize: 12.8, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
        bodyLarge: TextStyle(fontSize: 12, color: Color(0xFF475569)),
        bodyMedium: TextStyle(fontSize: 11.2, color: Color(0xFF64748B)),
        bodySmall: TextStyle(fontSize: 9.6, color: Color(0xFF94A3B8)),
      ),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: primaryColor,
    scaffoldBackgroundColor: const Color(0xFF0B0F19),

    colorScheme: const ColorScheme.dark(
      primary: primaryColor,
      secondary: secondaryColor,
      surface: Color(0xFF1A1F2E),
      error: errorColor,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Color(0xFFE8EAF0),
      onError: Colors.white,
    ),

    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: GoogleFonts.poppins(
        fontSize: 17.6,
        fontWeight: FontWeight.w700,
        color: const Color(0xFFE8EAF0),
        letterSpacing: -0.5,
      ),
      iconTheme: const IconThemeData(color: Color(0xFFE8EAF0)),
    ),

    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.24),
      ),
      color: const Color(0xFF1A1F2E),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF252B3D),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.96),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.96),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.96),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.96),
        borderSide: const BorderSide(color: errorColor, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12.8, vertical: 11.2),
      hintStyle: GoogleFonts.inter(
        color: Color(0xFF6B7280),
        fontSize: 11.2,
      ),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 19.2, vertical: 11.2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.96),
        ),
        textStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryColor,
        textStyle: GoogleFonts.inter(
          fontSize: 11.2,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    chipTheme: ChipThemeData(
      backgroundColor: const Color(0xFF252B3D),
      selectedColor: primaryColor.withOpacity(0.2),
      labelStyle: GoogleFonts.inter(
        fontSize: 10.4,
        fontWeight: FontWeight.w500,
        color: const Color(0xFFE8EAF0),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 9.6, vertical: 6.4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6.4),
      ),
    ),

    textTheme: GoogleFonts.interTextTheme(
      const TextTheme(
        displayLarge: TextStyle(fontSize: 25.6, fontWeight: FontWeight.w800, color: Color(0xFFE8EAF0)),
        displayMedium: TextStyle(fontSize: 22.4, fontWeight: FontWeight.w700, color: Color(0xFFE8EAF0)),
        displaySmall: TextStyle(fontSize: 19.2, fontWeight: FontWeight.w700, color: Color(0xFFE8EAF0)),
        headlineMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFFE8EAF0)),
        titleLarge: TextStyle(fontSize: 14.4, fontWeight: FontWeight.w600, color: Color(0xFFD1D5DB)),
        titleMedium: TextStyle(fontSize: 12.8, fontWeight: FontWeight.w600, color: Color(0xFFD1D5DB)),
        bodyLarge: TextStyle(fontSize: 12, color: Color(0xFFB5BAC1)),
        bodyMedium: TextStyle(fontSize: 11.2, color: Color(0xFF9CA3AF)),
        bodySmall: TextStyle(fontSize: 9.6, color: Color(0xFF6B7280)),
      ),
    ),
  );
}