class ScreenBreakpoints {
  // Screen width breakpoints (in logical pixels)
  static const double small = 360.0; // Compact phones
  static const double medium = 414.0; // Standard phones
  
  // Screen size categories
  static bool isSmallScreen(double width) => width < small;
  static bool isMediumScreen(double width) => width >= small && width <= medium;
  static bool isLargeScreen(double width) => width > medium;
  
  // Get screen category
  static ScreenSize getScreenSize(double width) {
    if (isSmallScreen(width)) return ScreenSize.small;
    if (isMediumScreen(width)) return ScreenSize.medium;
    return ScreenSize.large;
  }
}

enum ScreenSize {
  small, // < 360px
  medium, // 360px - 414px
  large, // > 414px
}
