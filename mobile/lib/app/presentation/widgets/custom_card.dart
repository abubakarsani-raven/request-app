import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class CustomCard extends StatefulWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final VoidCallback? onTap;
  final Color? color;
  final double? elevation;
  final BorderRadius? borderRadius;
  final bool useGlassmorphism;
  final bool showShadow;

  const CustomCard({
    Key? key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.color,
    this.elevation,
    this.borderRadius,
    this.useGlassmorphism = false,
    this.showShadow = true,
  }) : super(key: key);

  @override
  State<CustomCard> createState() => _CustomCardState();
}

class _CustomCardState extends State<CustomCard> with SingleTickerProviderStateMixin {
  late AnimationController _hoverController;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return MouseRegion(
      onEnter: (_) {
        if (widget.onTap != null) {
          setState(() => _isHovered = true);
          _hoverController.forward();
        }
      },
      onExit: (_) {
        if (_isHovered) {
          setState(() => _isHovered = false);
          _hoverController.reverse();
        }
      },
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, 10 * (1 - value)),
                child: child,
              ),
            );
          },
          child: Container(
            margin: widget.margin ?? EdgeInsets.zero,
            decoration: BoxDecoration(
              color: widget.useGlassmorphism
                  ? (isDark ? AppColors.darkSurface : AppColors.surface).withOpacity(0.7)
                  : widget.color ?? (isDark ? AppColors.darkSurface : AppColors.surface),
              borderRadius: widget.borderRadius ?? BorderRadius.circular(20),
              border: Border.all(
                color: isDark
                    ? AppColors.darkBorderDefined.withOpacity(0.5)
                    : AppColors.border.withOpacity(0.2),
                width: 1.5,
              ),
              boxShadow: widget.showShadow
                  ? [
                      BoxShadow(
                        color: isDark
                            ? Colors.black.withOpacity(0.3)
                            : Colors.black.withOpacity(0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                        spreadRadius: 0,
                      ),
                      BoxShadow(
                        color: isDark
                            ? Colors.black.withOpacity(0.2)
                            : Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                        spreadRadius: 0,
                      ),
                    ]
                  : null,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onTap,
                borderRadius: widget.borderRadius ?? BorderRadius.circular(20),
                child: Padding(
                  padding: widget.padding ?? const EdgeInsets.all(24),
                  child: widget.child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

