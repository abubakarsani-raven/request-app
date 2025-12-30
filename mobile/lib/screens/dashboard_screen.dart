import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../app/presentation/controllers/auth_controller.dart';
import '../app/presentation/controllers/request_controller.dart';
import '../app/data/models/request_model.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    final requestController = Get.find<RequestController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: RefreshIndicator(
        onRefresh: () async {
          await requestController.loadVehicleRequests(myRequests: true);
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Obx(
                () => Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome, ${authController.user.value?.name ?? "User"}',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Level ${authController.user.value?.level ?? 0}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Quick Actions',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _buildActionCard(
                    context,
                    'Vehicle Request',
                    Icons.directions_car,
                    Colors.blue,
                    () {
                      Get.toNamed('/create-request', parameters: {'type': RequestType.vehicle.name});
                    },
                  ),
                  _buildActionCard(
                    context,
                    'ICT Request',
                    Icons.computer,
                    Colors.green,
                    () {
                      Get.toNamed('/create-request', parameters: {'type': RequestType.ict.name});
                    },
                  ),
                  _buildActionCard(
                    context,
                    'Store Request',
                    Icons.inventory,
                    Colors.orange,
                    () {
                      Get.toNamed('/create-request', parameters: {'type': RequestType.store.name});
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: color),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

