import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        error: AppColors.error,
        surface: AppColors.surface,
        onPrimary: AppColors.textOnPrimary,
        onSecondary: AppColors.textOnPrimary,
        onError: AppColors.textOnPrimary,
        onSurface: AppColors.textPrimary,
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 22,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.5,
        ),
        // Add subtle bottom border for flat design (more defined)
        shape: Border(
          bottom: BorderSide(
            color: AppColors.border.withOpacity(0.5), // More defined
            width: 1.5, // Slightly thicker
          ),
        ),
        iconTheme: const IconThemeData(
          color: AppColors.textPrimary,
          size: 24,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0, // Remove elevation for flat design
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16), // Updated from 12px
          side: BorderSide(
            color: AppColors.border.withOpacity(0.5), // More defined border
            width: 1.5, // Slightly thicker for better definition
          ),
        ),
        color: AppColors.surface,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12), // Updated from 8px
          borderSide: BorderSide(
            color: AppColors.border.withOpacity(0.6), // More defined
            width: 1.5, // Slightly thicker
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppColors.border.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18), // Increased padding
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0, // Remove elevation for flat design
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18), // Increased padding
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12), // Updated from 8px
          ),
          textStyle: AppTextStyles.button,
          minimumSize: const Size(88, 48), // Ensure minimum touch target
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16), // Increased padding
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12), // Updated from 8px
          ),
          textStyle: AppTextStyles.button,
          minimumSize: const Size(88, 48), // Ensure minimum touch target
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18), // Increased padding
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12), // Updated from 8px
          ),
          side: BorderSide(
            color: AppColors.primary,
            width: 1.5,
          ),
          textStyle: AppTextStyles.button,
          minimumSize: const Size(88, 48), // Ensure minimum touch target
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1.5, // More defined
        space: 1,
      ),
      // Bottom Sheet Theme Configuration
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        elevation: 8,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        clipBehavior: Clip.antiAlias,
        constraints: const BoxConstraints(
          maxWidth: double.infinity,
        ),
        modalBackgroundColor: Colors.black.withOpacity(0.5),
        modalElevation: 8,
      ),
      // Dialog Theme (for critical confirmations)
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        titleTextStyle: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 22,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        ),
        contentTextStyle: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 16,
          height: 1.5,
        ),
      ),
    );
  }
  
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: AppColors.primaryLight,
      scaffoldBackgroundColor: AppColors.darkBackground,
      colorScheme: ColorScheme.dark(
        primary: AppColors.primaryLight,
        secondary: AppColors.secondaryLight,
        error: AppColors.error,
        surface: AppColors.darkSurface,
        onPrimary: AppColors.textOnPrimary,
        onSecondary: AppColors.darkTextPrimary,
        onError: AppColors.textOnPrimary,
        onSurface: AppColors.darkTextPrimary,
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: AppColors.darkSurface,
        foregroundColor: AppColors.darkTextPrimary,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: TextStyle(
          color: AppColors.darkTextPrimary,
          fontSize: 22,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.5,
          shadows: [], // Remove any text shadows that could cause glowing
        ),
        // Add subtle bottom border for flat design (more defined)
        shape: Border(
          bottom: BorderSide(
            color: AppColors.darkBorderDefined.withOpacity(0.3),
            width: 1,
          ),
        ),
        iconTheme: IconThemeData(
          color: AppColors.darkTextPrimary,
          size: 24,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0, // Remove elevation for flat design
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: AppColors.darkBorderDefined.withOpacity(0.5),
            width: 1.5, // Match light theme
          ),
        ),
        color: AppColors.darkSurface,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppColors.darkBorderDefined.withOpacity(0.6),
            width: 1.5, // Match light theme
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppColors.darkBorderDefined.withOpacity(0.6),
            width: 1.5, // Match light theme
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primaryLight, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppColors.darkBorderDefined.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18), // Increased padding
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: AppTextStyles.button,
          minimumSize: const Size(88, 48),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          side: BorderSide(
            color: AppColors.primaryLight,
            width: 1.5,
          ),
          textStyle: AppTextStyles.button,
          minimumSize: const Size(88, 48),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: AppColors.darkDivider,
        thickness: 1.5, // Match light theme
        space: 1,
      ),
      // Bottom Sheet Theme Configuration
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.darkSurface,
        elevation: 8,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        clipBehavior: Clip.antiAlias,
        constraints: const BoxConstraints(
          maxWidth: double.infinity,
        ),
        modalBackgroundColor: Colors.black.withOpacity(0.7),
        modalElevation: 8,
      ),
      // Dialog Theme (for critical confirmations)
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.darkSurface,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        titleTextStyle: TextStyle(
          color: AppColors.darkTextPrimary,
          fontSize: 22,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        ),
        contentTextStyle: TextStyle(
          color: AppColors.darkTextPrimary,
          fontSize: 16,
          height: 1.5,
        ),
      ),
    );
  }
}

