import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';

/// Base skeleton widget with shimmer effect
class Skeleton extends StatelessWidget {
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final Color? baseColor;
  final Color? highlightColor;

  const Skeleton({
    Key? key,
    this.width,
    this.height,
    this.borderRadius,
    this.baseColor,
    this.highlightColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: baseColor ?? AppColors.surfaceLight,
      highlightColor: highlightColor ?? Colors.white,
      period: const Duration(milliseconds: 1200),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: borderRadius ?? BorderRadius.circular(8),
        ),
      ),
    );
  }
}

/// Skeleton for text lines
class SkeletonText extends StatelessWidget {
  final double? width;
  final double height;
  final int lines;
  final double spacing;

  const SkeletonText({
    Key? key,
    this.width,
    this.height = 16,
    this.lines = 1,
    this.spacing = 8,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (lines == 1) {
      return Skeleton(
        width: width ?? double.infinity,
        height: height,
        borderRadius: BorderRadius.circular(4),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(
        lines,
        (index) => Padding(
          padding: EdgeInsets.only(bottom: index < lines - 1 ? spacing : 0),
          child: Skeleton(
            width: index == lines - 1 ? (width ?? double.infinity) * 0.7 : (width ?? double.infinity),
            height: height,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }
}

/// Skeleton for list items
class SkeletonListTile extends StatelessWidget {
  final bool hasLeading;
  final bool hasTrailing;
  final double? height;

  const SkeletonListTile({
    Key? key,
    this.hasLeading = true,
    this.hasTrailing = false,
    this.height,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height ?? 72,
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingL,
        vertical: AppConstants.spacingM,
      ),
      child: Row(
        children: [
          if (hasLeading) ...[
            Skeleton(
              width: 48,
              height: 48,
              borderRadius: BorderRadius.circular(24),
            ),
            const SizedBox(width: AppConstants.spacingM),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                SkeletonText(
                  width: double.infinity,
                  height: 11,
                  lines: 1,
                ),
                const SizedBox(height: 3),
                Flexible(
                  child: SkeletonText(
                    width: double.infinity * 0.6,
                    height: 10,
                    lines: 1,
                  ),
                ),
              ],
            ),
          ),
          if (hasTrailing) ...[
            const SizedBox(width: AppConstants.spacingM),
            Skeleton(
              width: 24,
              height: 24,
              borderRadius: BorderRadius.circular(12),
            ),
          ],
        ],
      ),
    );
  }
}

/// Skeleton for cards
class SkeletonCard extends StatelessWidget {
  final double? height;
  final EdgeInsets? padding;

  const SkeletonCard({
    Key? key,
    this.height,
    this.padding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      margin: const EdgeInsets.only(bottom: AppConstants.spacingM),
      padding: padding ?? const EdgeInsets.all(AppConstants.spacingL),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Skeleton(
                width: 40,
                height: 40,
                borderRadius: BorderRadius.circular(20),
              ),
              const SizedBox(width: AppConstants.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonText(
                      width: double.infinity,
                      height: 16,
                      lines: 1,
                    ),
                    const SizedBox(height: 6),
                    SkeletonText(
                      width: double.infinity * 0.5,
                      height: 14,
                      lines: 1,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (height == null) ...[
            const SizedBox(height: AppConstants.spacingL),
            SkeletonText(
              width: double.infinity,
              height: 14,
              lines: 2,
              spacing: 8,
            ),
            const SizedBox(height: AppConstants.spacingM),
            Skeleton(
              width: double.infinity,
              height: 8,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ],
      ),
    );
  }
}

/// Skeleton for grid items
class SkeletonGrid extends StatelessWidget {
  final int crossAxisCount;
  final int itemCount;
  final double childAspectRatio;

  const SkeletonGrid({
    Key? key,
    this.crossAxisCount = 2,
    this.itemCount = 4,
    this.childAspectRatio = 1.1,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: AppConstants.spacingL,
        mainAxisSpacing: AppConstants.spacingL,
        childAspectRatio: childAspectRatio,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                spreadRadius: 0,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Skeleton(
                  width: 48,
                  height: 48,
                  borderRadius: BorderRadius.circular(16),
                ),
                const SizedBox(height: 12),
                SkeletonText(
                  width: double.infinity,
                  height: 14,
                  lines: 1,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Skeleton for dashboard stats
class SkeletonStatCard extends StatelessWidget {
  const SkeletonStatCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingL),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Skeleton(
            width: 40,
            height: 40,
            borderRadius: BorderRadius.circular(12),
          ),
          const SizedBox(height: AppConstants.spacingM),
          SkeletonText(
            width: double.infinity * 0.6,
            height: 12,
            lines: 1,
          ),
          const SizedBox(height: 8),
          SkeletonText(
            width: double.infinity * 0.8,
            height: 24,
            lines: 1,
          ),
        ],
      ),
    );
  }
}

