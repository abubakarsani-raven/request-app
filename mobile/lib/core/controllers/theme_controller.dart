import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class ThemeController extends GetxController {
  final GetStorage _storage = GetStorage();
  static const String _themeKey = 'theme_mode';
  
  final Rx<ThemeMode> themeMode = ThemeMode.light.obs;
  
  @override
  void onInit() {
    super.onInit();
    _loadThemeMode();
  }
  
  void _loadThemeMode() {
    final savedTheme = _storage.read(_themeKey);
    if (savedTheme != null) {
      themeMode.value = ThemeMode.values.firstWhere(
        (mode) => mode.toString() == savedTheme,
        orElse: () => ThemeMode.light,
      );
    } else {
      // Default to system theme
      themeMode.value = ThemeMode.system;
    }
  }
  
  void setThemeMode(ThemeMode mode) {
    themeMode.value = mode;
    _storage.write(_themeKey, mode.toString());
    Get.changeThemeMode(mode);
  }
  
  void toggleTheme() {
    final newMode = themeMode.value == ThemeMode.light 
        ? ThemeMode.dark 
        : ThemeMode.light;
    setThemeMode(newMode);
  }
  
  bool get isDarkMode => themeMode.value == ThemeMode.dark;
  bool get isLightMode => themeMode.value == ThemeMode.light;
}
