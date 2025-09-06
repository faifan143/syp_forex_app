import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/onboarding_models.dart';
import '../controllers/translation_controller.dart';

class OnboardingTradingTermsPage extends StatefulWidget {
  final OnboardingPage page;

  const OnboardingTradingTermsPage({
    super.key,
    required this.page,
  });

  @override
  State<OnboardingTradingTermsPage> createState() => _OnboardingTradingTermsPageState();
}

class _OnboardingTradingTermsPageState extends State<OnboardingTradingTermsPage> {
  int _selectedTermIndex = 0;

  @override
  Widget build(BuildContext context) {
    final translationController = Get.find<TranslationController>();

    return Obx(() => Directionality(
      textDirection: translationController.isRTL ? TextDirection.rtl : TextDirection.ltr,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            // Title
            Text(
              widget.page.titleKey.tr,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 16),
            
            // Description
            Text(
              widget.page.descriptionKey.tr,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 32),
            
            // Terms grid
            SizedBox(
              height: 400, // Fixed height instead of Expanded
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: TradingTermsData.terms.length,
                itemBuilder: (context, index) {
                  final term = TradingTermsData.terms[index];
                  final isSelected = _selectedTermIndex == index;
                  
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedTermIndex = index;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? term.color.withOpacity(0.1)
                            : Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected 
                              ? term.color
                              : Theme.of(context).colorScheme.outline.withOpacity(0.2),
                          width: isSelected ? 2 : 1,
                        ),
                        boxShadow: isSelected ? [
                          BoxShadow(
                            color: term.color.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ] : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            term.icon,
                            color: isSelected ? term.color : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                            size: 32,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            term.termKey.tr,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isSelected ? term.color : Theme.of(context).colorScheme.onSurface,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Selected term details
            if (_selectedTermIndex < TradingTermsData.terms.length)
              _buildTermDetails(context, TradingTermsData.terms[_selectedTermIndex]),
          ],
        ),
      ),
    ));
  }

  Widget _buildTermDetails(BuildContext context, TradingTerm term) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: term.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: term.color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                term.icon,
                color: term.color,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  term.termKey.tr,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: term.color,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          Text(
            term.definitionKey.tr,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
              height: 1.5,
            ),
          ),
          
          const SizedBox(height: 12),
          
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: term.color.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: term.color.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: term.color,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    term.exampleKey.tr,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: term.color,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
