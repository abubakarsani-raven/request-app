import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/request_controller.dart';
import '../controllers/auth_controller.dart';
import '../widgets/request_card.dart';
import 'request_detail_page.dart';
import '../widgets/empty_state.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/skeleton_loader.dart';
import '../../data/models/request_model.dart';
import '../../../core/services/permission_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/custom_toast.dart';

class AssignVehicleListPage extends StatefulWidget {
  const AssignVehicleListPage({Key? key}) : super(key: key);

  @override
  State<AssignVehicleListPage> createState() => _AssignVehicleListPageState();
}

class _AssignVehicleListPageState extends State<AssignVehicleListPage> {
  final RequestController controller = Get.find<RequestController>();
  final AuthController authController = Get.find<AuthController>();
  final PermissionService permissionService = Get.find<PermissionService>();
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAssignableRequests();
    });
  }

  Future<void> _loadAssignableRequests() async {
    // Load all requests, then filter client-side
    await controller.loadVehicleRequests();
  }

  List<VehicleRequestModel> get _assignableRequests {
    final user = authController.user.value;
    if (user == null) return [];

    final isDGS = user.roles.any((role) => role.toUpperCase() == 'DGS');
    
    return controller.vehicleRequests.where((request) {
      // Must not have vehicle assigned
      if (request.vehicleId != null) return false;
      
      // User must have permission to assign vehicles
      if (!permissionService.canAssignVehicle(user)) return false;
      
      // Status filter based on role
      if (isDGS) {
        // DGS can assign to pending, corrected, or approved requests
        return request.status == RequestStatus.pending ||
            request.status == RequestStatus.corrected ||
            request.status == RequestStatus.approved;
      } else {
        // TO can only assign to approved requests
        return request.status == RequestStatus.approved;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return AppScaffold(
      title: 'Assign Vehicle',
      showBackButton: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.filter_list_rounded),
          tooltip: 'Filter',
          onPressed: () => CustomToast.info('Filter feature coming soon'),
        ),
      ],
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.darkBackground,
                    AppColors.darkSurface,
                    AppColors.darkSurfaceLight,
                  ],
                )
              : AppColors.backgroundGradient,
        ),
        child: Column(
          children: [
            Expanded(
                child: Obx(
                  () {
                    if (controller.isLoading.value &&
                        controller.vehicleRequests.isEmpty) {
                      return ListView.builder(
                        padding: const EdgeInsets.all(AppConstants.spacingM),
                        itemCount: 5,
                        itemBuilder: (context, index) => Padding(
                          padding: const EdgeInsets.only(bottom: AppConstants.spacingM),
                          child: const SkeletonCard(),
                        ),
                      );
                    }

                    if (controller.error.value.isNotEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 64,
                              color: AppColors.error,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              controller.error.value,
                              style: TextStyle(
                                color: AppColors.error,
                                fontSize: 16,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: () => _loadAssignableRequests(),
                              icon: const Icon(Icons.refresh),
                              label: const Text('Retry'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: AppColors.textOnPrimary,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    final assignable = _assignableRequests;

                    if (assignable.isEmpty) {
                      return EmptyState(
                        title: 'No Requests Found',
                        message: 'There are no requests that need vehicle assignment at this time',
                        icon: Icons.assignment_outlined,
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: () => _loadAssignableRequests(),
                      color: AppColors.primary,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(AppConstants.spacingM),
                        itemCount: assignable.length,
                        itemBuilder: (context, index) {
                          final request = assignable[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: AppConstants.spacingM),
                            child: RequestCard(
                              request: request,
                              source: RequestDetailSource.assignVehicle,
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
    );
  }
}

