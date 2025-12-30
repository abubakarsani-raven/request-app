import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';

class VehicleSelectionCard extends StatelessWidget {
  final Map<String, dynamic> vehicle;
  final bool isSelected;
  final VoidCallback onTap;
  final String? searchQuery;
  final double? estimatedFuelLiters;

  const VehicleSelectionCard({
    Key? key,
    required this.vehicle,
    required this.isSelected,
    required this.onTap,
    this.searchQuery,
    this.estimatedFuelLiters,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final plateNumber = vehicle['plateNumber'] ?? 'N/A';
    final make = vehicle['make'] ?? '';
    final model = vehicle['model'] ?? '';
    final type = vehicle['type'] ?? 'N/A';
    final capacity = vehicle['capacity'] ?? vehicle['seats'] ?? 'N/A';
    final isAvailable = vehicle['isAvailable'] ?? false;
    final status = vehicle['status'] ?? 'N/A';

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppConstants.shortAnimation,
        margin: const EdgeInsets.only(bottom: AppConstants.spacingS),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppColors.primary.withOpacity(0.2) : AppColors.primary.withOpacity(0.1))
              : (isDark ? AppColors.darkSurface : AppColors.surface),
          borderRadius: BorderRadius.circular(AppConstants.radiusL),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : (isDark ? AppColors.darkBorderDefined : AppColors.borderLight),
            width: isSelected ? 2 : 1,
          ),
        ),
        padding: const EdgeInsets.all(AppConstants.spacingS),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildHighlightedText(
                        plateNumber,
                        searchQuery,
                        isDark,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                        ),
                      ),
                      if (make.isNotEmpty || model.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        _buildHighlightedText(
                          '$make $model'.trim(),
                          searchQuery,
                          isDark,
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (isSelected)
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check,
                      color: AppColors.textOnPrimary,
                      size: 14,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                _buildCompactChip(type, isDark),
                _buildCompactChip('$capacity seats', isDark),
                if (estimatedFuelLiters != null)
                  _buildCompactChip('${estimatedFuelLiters!.toStringAsFixed(1)}L', isDark),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                _buildCompactBadge(
                  isAvailable ? 'Available' : 'Unavailable',
                  isAvailable ? AppColors.success : AppColors.error,
                ),
                if (status != 'N/A' && status.toLowerCase() != 'available' && status.toLowerCase() != 'unavailable') ...[
                  const SizedBox(width: 4),
                  _buildCompactBadge(
                    status,
                    _getStatusColor(status, isDark),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHighlightedText(
    String text,
    String? query,
    bool isDark, {
    required TextStyle style,
  }) {
    if (query == null || query.isEmpty) {
      return Text(text, style: style);
    }

    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final index = lowerText.indexOf(lowerQuery);

    if (index == -1) {
      return Text(text, style: style);
    }

    return RichText(
      text: TextSpan(
        style: style,
        children: [
          TextSpan(text: text.substring(0, index)),
          TextSpan(
            text: text.substring(index, index + query.length),
            style: style.copyWith(
              backgroundColor: AppColors.warning.withOpacity(0.3),
              fontWeight: FontWeight.bold,
            ),
          ),
          TextSpan(text: text.substring(index + query.length)),
        ],
      ),
    );
  }

  Widget _buildCompactChip(String label, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkSurfaceLight
            : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildCompactBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Color _getStatusColor(String status, bool isDark) {
    final lowerStatus = status.toLowerCase();
    if (lowerStatus.contains('available')) {
      return AppColors.success;
    } else if (lowerStatus.contains('maintenance')) {
      return AppColors.warning;
    } else if (lowerStatus.contains('unavailable')) {
      return AppColors.error;
    }
    return isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
  }
}
