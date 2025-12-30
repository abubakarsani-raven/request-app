import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../driver_selection_card.dart';
import '../../controllers/assignment_controller.dart';
import '../../controllers/assignment_selection_controller.dart';
import '../skeleton_loader.dart';

class DriverSelectionBottomSheet extends StatelessWidget {
  const DriverSelectionBottomSheet({Key? key}) : super(key: key);

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const DriverSelectionBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final assignmentController = Get.find<AssignmentController>();
    final selectionController = Get.find<AssignmentSelectionController>();

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppConstants.radiusXL),
            ),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.symmetric(vertical: AppConstants.spacingM),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkBorderDefined : AppColors.borderLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacingL),
                child: Row(
                  children: [
                    Icon(
                      Icons.person,
                      color: AppColors.primary,
                      size: 24,
                    ),
                    const SizedBox(width: AppConstants.spacingM),
                    Expanded(
                      child: Text(
                        'Select Driver',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Search bar
              Padding(
                padding: const EdgeInsets.all(AppConstants.spacingL),
                child: _buildSearchBar(
                  context,
                  'Search drivers...',
                  selectionController.driverSearchQuery,
                  selectionController.clearDriverSearch,
                ),
              ),
              // Driver list
              Expanded(
                child: Obx(() {
                  if (assignmentController.isLoadingDrivers.value) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SkeletonCard(height: 100),
                          SizedBox(height: AppConstants.spacingM),
                          SkeletonCard(height: 100),
                        ],
                      ),
                    );
                  }

                  if (assignmentController.availableDrivers.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.person_outline,
                            size: 64,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                          ),
                          const SizedBox(height: AppConstants.spacingM),
                          Text(
                            'No available drivers',
                            style: TextStyle(
                              fontSize: 16,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final filteredDrivers = _filterDrivers(
                    assignmentController.availableDrivers,
                    selectionController.driverSearchQuery.value,
                  );

                  if (filteredDrivers.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 64,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                          ),
                          const SizedBox(height: AppConstants.spacingM),
                          Text(
                            'No drivers found',
                            style: TextStyle(
                              fontSize: 16,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return GridView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.all(AppConstants.spacingL),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: AppConstants.spacingS,
                      mainAxisSpacing: AppConstants.spacingS,
                      childAspectRatio: 1.1,
                    ),
                    itemCount: filteredDrivers.length,
                    itemBuilder: (context, index) {
                      final driver = filteredDrivers[index];
                      final driverId = driver['_id'] ?? driver['id'];
                      final isSelected = selectionController.selectedDriverId.value == driverId?.toString();
                      return DriverSelectionCard(
                        driver: driver,
                        isSelected: isSelected,
                        searchQuery: selectionController.driverSearchQuery.value.isEmpty
                            ? null
                            : selectionController.driverSearchQuery.value,
                        onTap: () {
                          selectionController.selectDriver(driverId?.toString());
                          Navigator.pop(context);
                        },
                      );
                    },
                  );
                }),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSearchBar(
    BuildContext context,
    String hint,
    RxString searchQuery,
    VoidCallback onClear,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return TextField(
      onChanged: (value) => searchQuery.value = value,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(Icons.search, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
        suffixIcon: searchQuery.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear, size: 20),
                onPressed: onClear,
              )
            : null,
        filled: true,
        fillColor: isDark ? AppColors.darkSurfaceLight : AppColors.surfaceLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
          borderSide: BorderSide(
            color: isDark ? AppColors.darkBorderDefined : AppColors.borderLight,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
          borderSide: BorderSide(
            color: isDark ? AppColors.darkBorderDefined : AppColors.borderLight,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _filterDrivers(List<dynamic> drivers, String query) {
    if (query.isEmpty) return drivers.cast<Map<String, dynamic>>();
    final lowerQuery = query.toLowerCase();
    return drivers.where((driver) {
      final name = (driver['name'] ?? '').toString().toLowerCase();
      final licenseNumber = (driver['licenseNumber'] ?? driver['employeeId'] ?? '').toString().toLowerCase();
      final phone = (driver['phone'] ?? '').toString().toLowerCase();
      return name.contains(lowerQuery) ||
          licenseNumber.contains(lowerQuery) ||
          phone.contains(lowerQuery);
    }).cast<Map<String, dynamic>>().toList();
  }
}
