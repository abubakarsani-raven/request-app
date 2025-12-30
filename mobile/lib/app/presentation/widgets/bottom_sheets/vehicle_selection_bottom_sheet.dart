import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../vehicle_selection_card.dart';
import '../../controllers/assignment_controller.dart';
import '../../controllers/assignment_selection_controller.dart';
import '../skeleton_loader.dart';

class VehicleSelectionBottomSheet extends StatelessWidget {
  final double? estimatedFuelLiters;

  const VehicleSelectionBottomSheet({
    Key? key,
    this.estimatedFuelLiters,
  }) : super(key: key);

  static Future<void> show(BuildContext context, {double? estimatedFuelLiters}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => VehicleSelectionBottomSheet(
        estimatedFuelLiters: estimatedFuelLiters,
      ),
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
                      Icons.directions_car,
                      color: AppColors.primary,
                      size: 24,
                    ),
                    const SizedBox(width: AppConstants.spacingM),
                    Expanded(
                      child: Text(
                        'Select Vehicle',
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
                  'Search vehicles...',
                  selectionController.vehicleSearchQuery,
                  selectionController.clearVehicleSearch,
                ),
              ),
              // Vehicle list
              Expanded(
                child: Obx(() {
                  if (assignmentController.isLoadingVehicles.value) {
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

                  if (assignmentController.availableVehicles.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.directions_car_outlined,
                            size: 64,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                          ),
                          const SizedBox(height: AppConstants.spacingM),
                          Text(
                            'No available vehicles',
                            style: TextStyle(
                              fontSize: 16,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final filteredVehicles = _filterVehicles(
                    assignmentController.availableVehicles,
                    selectionController.vehicleSearchQuery.value,
                  );

                  if (filteredVehicles.isEmpty) {
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
                            'No vehicles found',
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
                    itemCount: filteredVehicles.length,
                    itemBuilder: (context, index) {
                      final vehicle = filteredVehicles[index];
                      final vehicleId = vehicle['_id'] ?? vehicle['id'];
                      final isSelected = selectionController.selectedVehicleId.value == vehicleId?.toString();
                      return VehicleSelectionCard(
                        vehicle: vehicle,
                        isSelected: isSelected,
                        searchQuery: selectionController.vehicleSearchQuery.value.isEmpty
                            ? null
                            : selectionController.vehicleSearchQuery.value,
                        estimatedFuelLiters: estimatedFuelLiters,
                        onTap: () {
                          selectionController.selectVehicle(vehicleId?.toString());
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

  List<Map<String, dynamic>> _filterVehicles(List<dynamic> vehicles, String query) {
    if (query.isEmpty) return vehicles.cast<Map<String, dynamic>>();
    final lowerQuery = query.toLowerCase();
    return vehicles.where((vehicle) {
      final plateNumber = (vehicle['plateNumber'] ?? '').toString().toLowerCase();
      final make = (vehicle['make'] ?? '').toString().toLowerCase();
      final model = (vehicle['model'] ?? '').toString().toLowerCase();
      final type = (vehicle['type'] ?? '').toString().toLowerCase();
      return plateNumber.contains(lowerQuery) ||
          make.contains(lowerQuery) ||
          model.contains(lowerQuery) ||
          type.contains(lowerQuery);
    }).cast<Map<String, dynamic>>().toList();
  }
}
