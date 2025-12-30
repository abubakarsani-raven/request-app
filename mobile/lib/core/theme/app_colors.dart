import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors - Green Theme (Muted)
  static const Color primary = Color(0xFF006B47); // Muted green (darker, less bright)
  static const Color primaryDark = Color(0xFF004A33); // Darker green
  static const Color primaryLight = Color(0xFF008A5C); // Lighter green (muted)
  
  // Secondary Colors - Complementary Teal/Green (Muted)
  static const Color secondary = Color(0xFF009D6B); // Muted green
  static const Color secondaryDark = Color(0xFF007A52);
  static const Color secondaryLight = Color(0xFF2AB389); // Muted teal
  
  // Accent Colors - Warm complementary colors (Muted)
  static const Color accent = Color(0xFFD45A2A); // Muted orange
  static const Color accentDark = Color(0xFFB84A1F);
  static const Color accentLight = Color(0xFFE67A4A);
  
  // Modern Gradients - Green based (Muted)
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF006B47), Color(0xFF008A5C), Color(0xFF009D6B)],
  );
  
  static const LinearGradient secondaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF009D6B), Color(0xFF00B37A), Color(0xFF2AB389)],
  );
  
  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFD45A2A), Color(0xFFE67A4A), Color(0xFFE89A6A)],
  );
  
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFF5F7FA),
      Color(0xFFEFF2F6),
      Color(0xFFE2E6EB),
    ],
  );
  
  // Status Colors - Muted and less bright
  static const Color success = Color(0xFF009D6B); // Muted green
  static const Color error = Color(0xFFC43D4A); // Muted red (much less bright than before)
  static const Color warning = Color(0xFFD99A2E); // Muted amber
  static const Color info = Color(0xFF006B47); // Primary green
  
  // Neutral Colors - Modern and Soft (Muted blacks)
  static const Color background = Color(0xFFF5F7FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF12181F); // Muted dark (not pure black)
  static const Color surfaceLight = Color(0xFFEFF2F6);
  
  // Dark Mode Colors - Muted and soft
  static const Color darkBackground = Color(0xFF12181F); // Muted dark background
  static const Color darkSurface = Color(0xFF1A2329); // Muted dark surface
  static const Color darkSurfaceLight = Color(0xFF232B32); // Lighter dark surface
  static const Color darkBorder = Color(0xFF2A3439); // Muted dark border
  
  // Text Colors - Light mode (Muted blacks)
  static const Color textPrimary = Color(0xFF1A1F24); // Muted black (not pure black)
  static const Color textSecondary = Color(0xFF6B7280); // Muted gray
  static const Color textDisabled = Color(0xFF9CA3AF); // Muted disabled
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  
  // Dark Mode Text Colors
  static const Color darkTextPrimary = Color(0xFFE5E7EB); // Soft white (not pure white)
  static const Color darkTextSecondary = Color(0xFF9CA3AF); // Muted gray
  static const Color darkTextDisabled = Color(0xFF6B7280);
  
  // Border & Divider - Updated for minimal flat design (More defined)
  static const Color border = Color(0xFFD1D5DB); // More defined border
  static const Color borderLight = Color(0xFFE5E7EB); // Very subtle border
  static const Color borderSubtle = Color(0xFFE8EAED); // Subtle border with opacity
  static const Color divider = Color(0xFFD1D5DB); // More defined divider
  
  // Dark Mode Borders
  static const Color darkBorderDefined = Color(0xFF2A3439); // Defined dark border
  static const Color darkDivider = Color(0xFF2A3439);
  
  // Surface Elevation - More defined for better hierarchy
  static const Color surfaceElevation1 = Color(0xFFF9FAFB); // Subtle elevation
  static const Color surfaceElevation2 = Color(0xFFF3F4F6); // Slightly more elevation
  
  // Dark Mode Elevation
  static const Color darkSurfaceElevation1 = Color(0xFF1A2329);
  static const Color darkSurfaceElevation2 = Color(0xFF232B32);
  
  // Request Status Colors - Muted and less bright
  static const Color statusPending = Color(0xFFD99A2E); // Muted amber
  static const Color statusApproved = Color(0xFF009D6B); // Muted green
  static const Color statusRejected = Color(0xFFC43D4A); // Muted red (much less bright)
  static const Color statusAssigned = Color(0xFF006B47); // Primary green
  static const Color statusCompleted = Color(0xFF009D6B); // Muted green
  static const Color statusCorrected = Color(0xFFD99A2E); // Muted amber
  
  // Dark Mode Status Colors (slightly adjusted for dark theme)
  static const Color darkStatusPending = Color(0xFFE5A84A);
  static const Color darkStatusApproved = Color(0xFF2AB389);
  static const Color darkStatusRejected = Color(0xFFD65A6A);
  static const Color darkStatusAssigned = Color(0xFF008A5C);
  static const Color darkStatusCompleted = Color(0xFF2AB389);
  static const Color darkStatusCorrected = Color(0xFFE5A84A);
}

