import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController extends GetxController {
  static const String _themeKey = 'selected_theme';
  
  final RxBool _isDarkMode = false.obs;
  
  bool get isDarkMode => _isDarkMode.value;
  ThemeMode get themeMode => _isDarkMode.value ? ThemeMode.dark : ThemeMode.light;
  
  @override
  void onInit() {
    super.onInit();
    _loadTheme();
  }
  
  // Load theme from preferences
  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool(_themeKey) ?? false;
    _isDarkMode.value = isDark;
    Get.changeThemeMode(themeMode);
  }
  
  // Toggle theme and save to preferences
  Future<void> toggleTheme() async {
    _isDarkMode.value = !_isDarkMode.value;
    Get.changeThemeMode(themeMode);
    
    // Save to preferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, _isDarkMode.value);
  }
  
  // Set specific theme
  Future<void> setTheme(bool isDark) async {
    _isDarkMode.value = isDark;
    Get.changeThemeMode(themeMode);
    
    // Save to preferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, isDark);
  }
  
  // Get theme name for display
  String get themeName => _isDarkMode.value ? 'dark'.tr : 'light'.tr;
  
  // Get theme icon
  IconData get themeIcon => _isDarkMode.value ? Icons.dark_mode : Icons.light_mode;
}
