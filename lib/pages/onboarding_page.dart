import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/onboarding_controller.dart';
import '../controllers/translation_controller.dart';
import '../models/onboarding_models.dart';
import '../widgets/onboarding_controls.dart';
import 'onboarding_welcome_page.dart';
import 'onboarding_feature_page.dart';
import 'onboarding_trading_terms_page.dart';
import 'onboarding_complete_page.dart';

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final onboardingController = Get.find<OnboardingController>();
    final translationController = Get.find<TranslationController>();

    return Obx(() => Directionality(
      textDirection: translationController.isRTL ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        body: SafeArea(
          child: PageView.builder(
            controller: onboardingController.pageController,
            onPageChanged: (index) {
              onboardingController.goToPage(index);
            },
            itemCount: OnboardingContent.pages.length,
            itemBuilder: (context, index) {
              final page = OnboardingContent.pages[index];
              
              switch (page.type) {
                case OnboardingPageType.welcome:
                  return OnboardingWelcomePage(page: page);
                case OnboardingPageType.tradingTerms:
                  return OnboardingTradingTermsPage(page: page);
                case OnboardingPageType.complete:
                  return OnboardingCompletePage(page: page);
                default:
                  return OnboardingFeaturePage(page: page);
              }
            },
          ),
        ),
        bottomNavigationBar: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Theme and Language Controls
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: const OnboardingControls(),
            ),
            // Bottom Navigation
            _buildBottomNavigationBar(context),
          ],
        ),
      ),
    ));
  }

  Widget _buildBottomNavigationBar(BuildContext context) {
    final onboardingController = Get.find<OnboardingController>();

    return Obx(() => Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Page indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              OnboardingContent.pages.length,
              (index) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: onboardingController.currentPageIndex == index ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: onboardingController.currentPageIndex == index
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.outline.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          
          // Navigation buttons
          Row(
            children: [
              // Previous button
              if (!onboardingController.isFirstPage)
                Expanded(
                  child: OutlinedButton(
                    onPressed: onboardingController.previousPage,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                    child: Text(
                      'onboardingPrevious'.tr,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
              
              if (!onboardingController.isFirstPage) const SizedBox(width: 16),
              
              // Skip button (only on first few pages)
              if (onboardingController.currentPageIndex < 3)
                Expanded(
                  child: TextButton(
                    onPressed: onboardingController.skipOnboarding,
                    child: Text(
                      'onboardingSkip'.tr,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ),
                ),
              
              if (onboardingController.currentPageIndex < 3) const SizedBox(width: 16),
              
              // Next/Finish button
              Expanded(
                flex: onboardingController.isFirstPage ? 1 : 2,
                child: ElevatedButton(
                  onPressed: onboardingController.isLastPage
                      ? onboardingController.finishOnboarding
                      : onboardingController.nextPage,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  ),
                  child: Text(
                    onboardingController.isLastPage
                        ? 'onboardingFinish'.tr
                        : 'onboardingNext'.tr,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ));
  }
}
