import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_advanced_drawer/flutter_advanced_drawer.dart';
import '../app/presentation/controllers/auth_controller.dart';
import '../app/presentation/widgets/custom_button.dart';
import '../app/presentation/widgets/app_drawer.dart';
import '../core/theme/app_colors.dart';
import '../core/constants/app_constants.dart';
import '../core/constants/app_icons.dart';
import '../core/controllers/theme_controller.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AdvancedDrawerController _drawerController = AdvancedDrawerController();

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();

    return AppDrawer(
      controller: _drawerController,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(AppIcons.menu),
            onPressed: () => _drawerController.showDrawer(),
          ),
          title: const Text('Profile'),
        ),
      body: Obx(
        () {
          final user = authController.user.value;
          if (user == null) {
            return const Center(child: Text('Not logged in'));
          }

          final themeController = Get.find<ThemeController>();
          
          return ListView(
            padding: const EdgeInsets.all(AppConstants.spacingL),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.spacingL),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(user.email),
                      const SizedBox(height: 8),
                      Text('Level: ${user.level}'),
                      const SizedBox(height: 8),
                      Text('Roles: ${user.roles.join(", ")}'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Dark Mode Toggle
              Card(
                child: Obx(() => SwitchListTile(
                  title: const Text('Dark Mode'),
                  subtitle: Text(
                    themeController.isDarkMode 
                        ? 'Dark theme is enabled' 
                        : 'Light theme is enabled',
                  ),
                  value: themeController.isDarkMode,
                  onChanged: (value) {
                    themeController.toggleTheme();
                  },
                  secondary: Icon(
                    themeController.isDarkMode 
                        ? AppIcons.darkMode 
                        : AppIcons.lightMode,
                  ),
                )),
              ),
              const SizedBox(height: 24),
              CustomButton(
                text: 'Logout',
                icon: AppIcons.logout,
                backgroundColor: AppColors.error,
                textColor: AppColors.textOnPrimary,
                onPressed: () async {
                  await authController.logout();
                },
              ),
            ],
          );
        },
      ),
      ),
    );
  }
}
