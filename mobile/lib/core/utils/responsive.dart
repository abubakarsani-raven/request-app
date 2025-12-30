import 'package:flutter/material.dart';
import '../constants/screen_breakpoints.dart';

class Responsive {
  final BuildContext context;
  final MediaQueryData mediaQuery;

  Responsive(this.context) : mediaQuery = MediaQuery.of(context);

  // Screen dimensions
  double get width => mediaQuery.size.width;
  double get height => mediaQuery.size.height;
  
  // Screen size checks
  bool get isSmallScreen => ScreenBreakpoints.isSmallScreen(width);
  bool get isMediumScreen => ScreenBreakpoints.isMediumScreen(width);
  bool get isLargeScreen => ScreenBreakpoints.isLargeScreen(width);
  
  ScreenSize get screenSize => ScreenBreakpoints.getScreenSize(width);
  
  // Responsive spacing multipliers
  double get spacingMultiplier {
    if (isSmallScreen) return 0.85; // Reduce spacing on small screens
    if (isLargeScreen) return 1.15; // Increase spacing on large screens
    return 1.0; // Standard spacing
  }
  
  // Responsive font size multiplier
  double get fontSizeMultiplier {
    if (isSmallScreen) return 0.95; // Slightly smaller text on small screens
    if (isLargeScreen) return 1.05; // Slightly larger text on large screens
    return 1.0; // Standard size
  }
  
  // Responsive padding
  EdgeInsets getScreenPadding() {
    final base = 16.0;
    if (isSmallScreen) return EdgeInsets.all(base * 0.85);
    if (isLargeScreen) return EdgeInsets.all(base * 1.15);
    return EdgeInsets.all(base);
  }
  
  // Responsive horizontal padding
  EdgeInsets getHorizontalPadding() {
    final base = 16.0;
    if (isSmallScreen) return EdgeInsets.symmetric(horizontal: base * 0.85);
    if (isLargeScreen) return EdgeInsets.symmetric(horizontal: base * 1.15);
    return EdgeInsets.symmetric(horizontal: base);
  }
  
  // Responsive vertical padding
  EdgeInsets getVerticalPadding() {
    final base = 16.0;
    if (isSmallScreen) return EdgeInsets.symmetric(vertical: base * 0.85);
    if (isLargeScreen) return EdgeInsets.symmetric(vertical: base * 1.15);
    return EdgeInsets.symmetric(vertical: base);
  }
  
  // Get responsive value based on screen size
  T value<T>({
    required T small,
    required T medium,
    required T large,
  }) {
    if (isSmallScreen) return small;
    if (isLargeScreen) return large;
    return medium;
  }
  
  // Get number of columns for grid
  int getGridColumns() {
    if (isSmallScreen) return 1;
    if (isMediumScreen) return 2;
    return 2; // Keep 2 columns even on large screens for better UX
  }
  
  // Get max width for content (prevents content from being too wide)
  double getMaxContentWidth() {
    if (isLargeScreen) return 600.0; // Max width on large screens
    return double.infinity; // Full width on smaller screens
  }
}

// Extension for easy access
extension ResponsiveExtension on BuildContext {
  Responsive get responsive => Responsive(this);
}
