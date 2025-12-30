import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';

class AssignmentPreviewCard extends StatelessWidget {
  final Map<String, dynamic>? selectedVehicle;
  final Map<String, dynamic>? selectedDriver;
  final double? estimatedFuelLiters;
  final VoidCallback? onAssign;
  final bool isAssigning;

  const AssignmentPreviewCard({
    Key? key,
    this.selectedVehicle,
    this.selectedDriver,
    this.estimatedFuelLiters,
    this.onAssign,
    this.isAssigning = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusL),
        border: Border.all(
          color: isDark ? AppColors.darkBorderDefined : AppColors.borderLight,
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(AppConstants.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppConstants.spacingS),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppConstants.radiusM),
                ),
                child: Icon(
                  Icons.preview,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppConstants.spacingM),
              Text(
                'Assignment Preview',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingL),
          if (selectedVehicle != null) ...[
            _buildPreviewSection(
              context,
              'Vehicle',
              Icons.directions_car,
              [
                _buildPreviewItem(
                  'Plate',
                  selectedVehicle!['plateNumber'] ?? 'N/A',
                  isDark,
                ),
                _buildPreviewItem(
                  'Make/Model',
                  '${selectedVehicle!['make'] ?? ''} ${selectedVehicle!['model'] ?? ''}'.trim(),
                  isDark,
                  fallback: 'N/A',
                ),
                _buildPreviewItem(
                  'Type',
                  selectedVehicle!['type'] ?? 'N/A',
                  isDark,
                ),
                if (estimatedFuelLiters != null)
                  _buildPreviewItem(
                    'Est. Fuel',
                    '${estimatedFuelLiters!.toStringAsFixed(1)}L',
                    isDark,
                  ),
              ],
              isDark,
            ),
            const SizedBox(height: AppConstants.spacingM),
          ],
          _buildPreviewSection(
            context,
            'Driver',
            Icons.person,
            [
              _buildPreviewItem(
                'Name',
                selectedDriver != null
                    ? (selectedDriver!['name'] ?? 'N/A')
                    : 'Required - Please select a driver',
                isDark,
              ),
              if (selectedDriver != null) ...[
                _buildPreviewItem(
                  'ID',
                  selectedDriver!['licenseNumber'] ??
                      selectedDriver!['employeeId'] ??
                      'N/A',
                  isDark,
                ),
                _buildPreviewItem(
                  'Phone',
                  selectedDriver!['phone'] ?? 'N/A',
                  isDark,
                ),
              ],
            ],
            isDark,
          ),
          const SizedBox(height: AppConstants.spacingXL),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: selectedVehicle != null && selectedDriver != null && !isAssigning ? onAssign : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textOnPrimary,
                padding: const EdgeInsets.symmetric(vertical: AppConstants.spacingM),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppConstants.radiusM),
                ),
                elevation: 0,
              ),
              child: isAssigning
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.textOnPrimary),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.assignment, size: 20),
                        const SizedBox(width: AppConstants.spacingS),
                        const Text(
                          'Assign Vehicle',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewSection(
    BuildContext context,
    String title,
    IconData icon,
    List<Widget> items,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
            ),
            const SizedBox(width: AppConstants.spacingS),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppConstants.spacingS),
        ...items,
      ],
    );
  }

  Widget _buildPreviewItem(String label, String value, bool isDark, {String? fallback}) {
    if (value.isEmpty && fallback != null) {
      value = fallback;
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.spacingS),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
