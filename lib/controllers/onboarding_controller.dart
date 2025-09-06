import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/onboarding_models.dart';

class OnboardingController extends GetxController {
  static const String _onboardingCompletedKey = 'onboarding_completed';
  
  final RxInt _currentPageIndex = 0.obs;
  final RxBool _isOnboardingCompleted = false.obs;
  final PageController pageController = PageController();

  // Getters
  int get currentPageIndex => _currentPageIndex.value;
  bool get isOnboardingCompleted => _isOnboardingCompleted.value;
  bool get isFirstPage => _currentPageIndex.value == 0;
  bool get isLastPage => _currentPageIndex.value == OnboardingContent.pages.length - 1;
  
  OnboardingPage get currentPage => OnboardingContent.pages[_currentPageIndex.value];
  int get totalPages => OnboardingContent.pages.length;

  @override
  void onInit() {
    super.onInit();
    _checkOnboardingStatus();
  }

  @override
  void onClose() {
    pageController.dispose();
    super.onClose();
  }

  Future<void> _checkOnboardingStatus() async {
    final prefs = await SharedPreferences.getInstance();
    _isOnboardingCompleted.value = prefs.getBool(_onboardingCompletedKey) ?? false;
  }

  Future<void> completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingCompletedKey, true);
    _isOnboardingCompleted.value = true;
  }

  Future<void> resetOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_onboardingCompletedKey);
    _isOnboardingCompleted.value = false;
    _currentPageIndex.value = 0;
    if (pageController.hasClients) {
      pageController.animateToPage(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void nextPage() {
    if (!isLastPage && pageController.hasClients) {
      _currentPageIndex.value++;
      pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void previousPage() {
    if (!isFirstPage && pageController.hasClients) {
      _currentPageIndex.value--;
      pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void goToPage(int index) {
    if (index >= 0 && index < totalPages && pageController.hasClients) {
      _currentPageIndex.value = index;
      pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void skipOnboarding() {
    completeOnboarding();
    Get.offAllNamed('/main');
  }

  void finishOnboarding() {
    completeOnboarding();
    Get.offAllNamed('/main');
  }
}
