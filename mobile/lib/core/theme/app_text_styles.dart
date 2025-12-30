import 'package:flutter/material.dart';

class AppTextStyles {
  // Headings - Updated line heights for better readability
  static const TextStyle h1 = TextStyle(
    fontSize: 34, // Slightly increased
    fontWeight: FontWeight.bold,
    letterSpacing: -0.5,
    height: 1.3, // Updated from 1.2
  );
  
  static const TextStyle h2 = TextStyle(
    fontSize: 30, // Slightly increased
    fontWeight: FontWeight.bold,
    letterSpacing: -0.5,
    height: 1.3,
  );
  
  static const TextStyle h3 = TextStyle(
    fontSize: 26, // Slightly increased
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.3,
  );
  
  static const TextStyle h4 = TextStyle(
    fontSize: 22, // Slightly increased
    fontWeight: FontWeight.w600,
    letterSpacing: 0.15,
    height: 1.3, // Updated from 1.4
  );
  
  static const TextStyle h5 = TextStyle(
    fontSize: 20, // Slightly increased
    fontWeight: FontWeight.w600,
    letterSpacing: 0.15,
    height: 1.3, // Updated from 1.4
  );
  
  static const TextStyle h6 = TextStyle(
    fontSize: 18, // Slightly increased
    fontWeight: FontWeight.w600,
    letterSpacing: 0.15,
    height: 1.3, // Updated from 1.5
  );
  
  // Body Text - Maintained line height 1.5 for readability
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    letterSpacing: 0.5,
    height: 1.5,
  );
  
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    letterSpacing: 0.25,
    height: 1.5,
  );
  
  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    letterSpacing: 0.4,
    height: 1.5,
  );
  
  // Labels & Captions
  static const TextStyle labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    height: 1.4,
  );
  
  static const TextStyle labelMedium = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    height: 1.4,
  );
  
  static const TextStyle labelSmall = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    height: 1.4,
  );
  
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    letterSpacing: 0.4,
    height: 1.4,
  );
  
  // Button Text
  static const TextStyle button = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.75,
    height: 1.2,
  );
  
  // Overline
  static const TextStyle overline = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    letterSpacing: 1.5,
    height: 1.4,
  );
}

