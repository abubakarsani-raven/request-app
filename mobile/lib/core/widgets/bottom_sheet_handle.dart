import 'package:flutter/material.dart';

/// Reusable drag handle component for bottom sheets
/// Provides visual indicator for draggable bottom sheets
class BottomSheetHandle extends StatelessWidget {
  final Color? color;
  final double width;
  final double height;
  final double borderRadius;

  const BottomSheetHandle({
    Key? key,
    this.color,
    this.width = 48,
    this.height = 5,
    this.borderRadius = 3,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color ?? Colors.grey[400],
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

