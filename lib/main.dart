import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'providers/syp_provider.dart';
import 'providers/forex_provider.dart';
import 'providers/paper_trading_provider.dart';
import 'controllers/translation_controller.dart';
import 'translations/app_translations.dart';
import 'pages/home_page.dart';
import 'pages/enhanced_syp_page.dart';
import 'pages/comprehensive_paper_trading_page.dart';
import 'pages/settings_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SypForexApp());
}

class SypForexApp extends StatelessWidget {
  const SypForexApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'SYP Forex App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      translations: AppTranslations(),
      locale: const Locale('en', ''),
      fallbackLocale: const Locale('en', ''),
      home: const MainNavigationPage(),
      debugShowCheckedModeBanner: false,
      initialBinding: AppBinding(),
    );
  }
}

// App Binding for dependency injection
class AppBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(TranslationController());
    Get.put(SypProvider());
    Get.put(ForexProvider());
    Get.put(PaperTradingProvider());
  }
}

class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({super.key});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  int _selectedIndex = 0;
  final TranslationController _translationController = Get.find<TranslationController>();

  static const List<Widget> _pages = [
    HomePage(),
    EnhancedSypPage(),
    ComprehensivePaperTradingPage(),
    SettingsPage(),
  ];

  static const List<IconData> _pageIcons = [
    Icons.home,
    Icons.currency_exchange,
    Icons.games,
    Icons.settings,
  ];

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final pageTitles = [
        'home'.tr,
        'syp'.tr,
        'paperTrading'.tr,
        'settings'.tr,
      ];

      return Directionality(
        textDirection: _translationController.isRTL ? TextDirection.rtl : TextDirection.ltr,
        child: Scaffold(
          body: IndexedStack(
            index: _selectedIndex,
            children: _pages,
          ),
          bottomNavigationBar: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            currentIndex: _selectedIndex,
            onTap: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            items: List.generate(_pageIcons.length, (index) {
              return BottomNavigationBarItem(
                icon: Icon(_pageIcons[index]),
                label: pageTitles[index],
              );
            }),
          ),
        ),
      );
    });
  }
}
