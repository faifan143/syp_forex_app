import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/translation_controller.dart';
import '../controllers/theme_controller.dart';

class OnboardingControls extends StatelessWidget {
  const OnboardingControls({super.key});

  @override
  Widget build(BuildContext context) {
    final translationController = Get.find<TranslationController>();
    final themeController = Get.find<ThemeController>();

    return Obx(() => Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Theme Toggle
          _buildToggleButton(
            context: context,
            icon: themeController.isDarkMode ? Icons.dark_mode : Icons.light_mode,
            label: themeController.isDarkMode ? 'darkMode'.tr : 'lightMode'.tr,
            onTap: () => themeController.toggleTheme(),
            isActive: true,
          ),
          
          // Divider
          Container(
            height: 24,
            width: 1,
            color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
          ),
          
          // Language Toggle
          _buildToggleButton(
            context: context,
            icon: translationController.isRTL ? Icons.language : Icons.translate,
            label: translationController.isRTL ? 'arabic'.tr : 'english'.tr,
            onTap: () => translationController.toggleLanguage(),
            isActive: true,
          ),
        ],
      ),
    ));
  }

  Widget _buildToggleButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isActive,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive 
            ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
            : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isActive 
            ? Border.all(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                width: 1,
              )
            : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isActive 
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isActive 
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
