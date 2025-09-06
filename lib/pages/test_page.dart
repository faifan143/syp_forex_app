import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/translation_controller.dart';

class TestPage extends StatelessWidget {
  const TestPage({super.key});

  @override
  Widget build(BuildContext context) {
    final translationController = Get.find<TranslationController>();
    
    return Scaffold(
      appBar: AppBar(
        title: Text('appTitle'.tr),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Welcome to SYP Forex App',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 20),
            Text('Current Language: ${translationController.currentLanguageName}'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                translationController.toggleLanguage();
              },
              child: Text('Toggle Language'.tr),
            ),
            const SizedBox(height: 20),
            Text('home'.tr),
            Text('syp'.tr),
            Text('paperTrading'.tr),
            Text('settings'.tr),
          ],
        ),
      ),
    );
  }
}
