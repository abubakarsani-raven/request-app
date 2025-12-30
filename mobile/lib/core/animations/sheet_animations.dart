import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Standardized animation curves for bottom sheets
class SheetAnimations {
  /// Spring physics curve for natural feel
  static const SpringCurve springCurve = SpringCurve();
  
  /// Standard entrance animation duration
  static const Duration entranceDuration = Duration(milliseconds: 300);
  
  /// Standard exit animation duration
  static const Duration exitDuration = Duration(milliseconds: 250);
  
  /// Standard animation curve
  static const Curve standardCurve = Curves.easeOutCubic;
  
  /// Bounce animation curve
  static const Curve bounceCurve = Curves.elasticOut;
}

/// Custom spring curve for natural animations
class SpringCurve extends Curve {
  final double damping;
  final double stiffness;
  
  const SpringCurve({
    this.damping = 0.8,
    this.stiffness = 100.0,
  });
  
  @override
  double transformInternal(double t) {
    // Simplified spring physics using exponential decay
    // For a more natural feel, we use a simplified approach
    final double e = math.e;
    final double w = stiffness / damping;
    final double d = damping / (2 * stiffness);
    
    if (d < 1) {
      // Underdamped - oscillating spring
      final double wd = w * math.sqrt(1 - d * d);
      final num expTerm = math.pow(e, -d * w * t);
      final double cosTerm = math.cos(wd * t);
      final double sinTerm = math.sin(wd * t);
      return 1 - (expTerm * (cosTerm + (d * w / wd) * sinTerm)).toDouble();
    } else {
      // Overdamped or critically damped - no oscillation
      return 1 - math.pow(e, -d * w * t).toDouble();
    }
  }
}

/// Haptic feedback helper for bottom sheet interactions
class SheetHaptics {
  /// Light impact for button taps
  static void lightImpact() {
    HapticFeedback.lightImpact();
  }
  
  /// Medium impact for selections
  static void mediumImpact() {
    HapticFeedback.mediumImpact();
  }
  
  /// Heavy impact for confirmations
  static void heavyImpact() {
    HapticFeedback.heavyImpact();
  }
  
  /// Selection feedback
  static void selectionClick() {
    HapticFeedback.selectionClick();
  }
}
