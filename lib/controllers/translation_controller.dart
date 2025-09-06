import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TranslationController extends GetxController {
  static const String _languageKey = 'selected_language';
  
  final RxString _currentLanguage = 'en'.obs;
  final RxBool _isRTL = false.obs;

  String get currentLanguage => _currentLanguage.value;
  bool get isRTL => _isRTL.value;
  String get languageCode => _currentLanguage.value;

  @override
  void onInit() {
    super.onInit();
    _loadSavedLanguage();
  }

  // Load saved language from preferences
  Future<void> _loadSavedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLanguage = prefs.getString(_languageKey) ?? 'en';
    await changeLanguage(savedLanguage);
  }

  // Change language and save to preferences
  Future<void> changeLanguage(String languageCode) async {
    _currentLanguage.value = languageCode;
    _isRTL.value = languageCode == 'ar';
    
    // Update GetX locale
    Get.updateLocale(Locale(languageCode));
    
    // Save to preferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, languageCode);
  }

  // Toggle between English and Arabic
  Future<void> toggleLanguage() async {
    final newLanguage = _currentLanguage.value == 'en' ? 'ar' : 'en';
    await changeLanguage(newLanguage);
  }

  // Get available languages
  List<Map<String, String>> get availableLanguages => [
    {'code': 'en', 'name': 'English', 'nativeName': 'English'},
    {'code': 'ar', 'name': 'Arabic', 'nativeName': 'العربية'},
  ];

  // Get current language name
  String get currentLanguageName {
    final language = availableLanguages.firstWhere(
      (lang) => lang['code'] == _currentLanguage.value,
      orElse: () => availableLanguages.first,
    );
    return language['nativeName']!;
  }

  // Check if current language is Arabic
  bool get isArabic => _currentLanguage.value == 'ar';

  // Check if current language is English
  bool get isEnglish => _currentLanguage.value == 'en';

  // Get translation by key
  String tr(String key, {Map<String, String>? args}) {
    return key.tr;
  }
}
