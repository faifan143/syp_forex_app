import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../providers/forex_provider.dart';
import '../providers/syp_provider.dart';
import '../controllers/translation_controller.dart';
import '../controllers/theme_controller.dart';
import '../controllers/onboarding_controller.dart';
import '../services/api_config_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _useDemoData = false;
  bool _autoRefresh = true;
  int _refreshInterval = 30; // seconds
  
  // API Configuration controllers
  final _hostController = TextEditingController();
  // Ports are fixed: Forex = 5001, SYP = 5002

  @override
  void initState() {
    super.initState();
    // Load current settings
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final forexProvider = Get.find<ForexProvider>();
      setState(() {
        _useDemoData = false; // Always false for paper trading
      });
      
      // Load current API configuration
      _hostController.text = ApiConfigService.sypApiHost;
    });
  }

  @override
  void dispose() {
    _hostController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final translationController = Get.find<TranslationController>();
    
    return Scaffold(
      appBar: AppBar(
        title: Text('settings'.tr),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Language Selection Section
          _buildSectionCard(
            title: 'language'.tr,
            icon: Icons.language,
            children: [
              ListTile(
                leading: const Icon(Icons.language),
                title: Text('selectLanguage'.tr),
                subtitle: Obx(() => Text(translationController.currentLanguageName)),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () => _showLanguageDialog(context, translationController),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Theme Section
          _buildSectionCard(
            title: 'theme'.tr,
            icon: Icons.palette,
            children: [
              GetBuilder<ThemeController>(
                builder: (themeController) {
                  return ListTile(
                    leading: Icon(themeController.themeIcon),
                    title: Text('selectTheme'.tr),
                    subtitle: Text(themeController.themeName),
                    trailing: Switch(
                      value: themeController.isDarkMode,
                      onChanged: (_) => themeController.toggleTheme(),
                    ),
                  );
                },
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Onboarding Section
          _buildSectionCard(
            title: 'onboarding'.tr,
            icon: Icons.school,
            children: [
              ListTile(
                leading: const Icon(Icons.refresh),
                title: Text('resetOnboarding'.tr),
                subtitle: Text('resetOnboardingDescription'.tr),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () => _showResetOnboardingDialog(),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Unified API Configuration
          _buildSectionCard(
            title: 'apiConfiguration'.tr,
            icon: Icons.api,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🌐 ${'serverConfiguration'.tr}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Single IP Configuration
                    TextField(
                      controller: _hostController,
                      decoration: InputDecoration(
                        labelText: 'serverIpAddress'.tr,
                        border: const OutlineInputBorder(),
                        hintText: 'serverIpHint'.tr,
                        prefixIcon: const Icon(Icons.computer),
                      ),
                    ),
         
                    const SizedBox(height: 20),
                    
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _updateAllApiConfigs,
                            icon: const Icon(Icons.save),
                            label: Text('updateAllApis'.tr),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _testAllConnections,
                            icon: const Icon(Icons.wifi),
                            label: Text('testAll'.tr),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 12),
                    
                    Center(
                      child: TextButton.icon(
                        onPressed: _resetApiConfigs,
                        icon: const Icon(Icons.refresh, color: Colors.red),
                        label: Text(
                          'resetToDefaults'.tr,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
   
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }



  void _showResetWalletDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Virtual Wallet'),
        content: const Text(
          'This will reset your paper trading wallet to the initial \$100,000 balance and clear all positions and trade history. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Reset wallet logic would go here
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Virtual wallet reset successfully!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  void _updateAllApiConfigs() {
    final host = _hostController.text.trim();
    
    if (!ApiConfigService.isValidHost(host)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid host format'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Update all APIs with the same host and fixed ports
    ApiConfigService.setForexApiConfig(host, 5001); // Fixed port
    ApiConfigService.setSypApiConfig(host, 5002);   // Fixed port
    setState(() {});
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('All APIs updated: $host (Forex:5001, SYP:5002)'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _resetApiConfigs() {
    ApiConfigService.resetToDefaults();
    _hostController.text = ApiConfigService.forexApiHost;
    setState(() {});
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('API configurations reset to defaults'),
        backgroundColor: Colors.green,
      ),
    );
  }
  
  Future<void> _testAllConnections() async {
    final host = _hostController.text.trim();
    
    if (host.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a host IP address first'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Testing connections...'),
          ],
        ),
      ),
    );
    
    try {
      List<String> results = [];
      
      // Test Forex API (Fixed port 5001)
      try {
        final response = await http.get(
          Uri.parse('http://$host:5001/health'),
          headers: {'Content-Type': 'application/json'},
        ).timeout(const Duration(seconds: 5));
        results.add('✅ Forex API (Port 5001): ${response.statusCode == 200 ? "Connected" : "Failed"}');
      } catch (e) {
        results.add('❌ Forex API (Port 5001): Connection failed');
      }
      
      // Test SYP API (Fixed port 5002)
      try {
        final sypProvider = Get.find<SypProvider>();
        final isConnected = await sypProvider.testServerConnection();
        results.add(isConnected ? '✅ SYP API (Port 5002): Connected' : '❌ SYP API (Port 5002): Failed');
      } catch (e) {
        results.add('❌ SYP API (Port 5002): Connection failed');
      }
      
      // Close loading dialog
      Navigator.of(context).pop();
      
      // Show results
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Connection Test Results'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: results.map((result) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(result),
            )).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      
    } catch (e) {
      // Close loading dialog
      Navigator.of(context).pop();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Connection test failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }


  void _showResetOnboardingDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('resetOnboarding'.tr),
          content: Text('resetOnboardingConfirm'.tr),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('cancel'.tr),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                final onboardingController = Get.find<OnboardingController>();
                onboardingController.resetOnboarding();
              },
              child: Text('reset'.tr),
            ),
          ],
        );
      },
    );
  }

  void _showLanguageDialog(BuildContext context, TranslationController translationController) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('selectLanguage'.tr),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: translationController.availableLanguages.map((language) {
            return RadioListTile<String>(
              title: Text(language['nativeName']!),
              subtitle: Text(language['name']!),
              value: language['code']!,
              groupValue: translationController.languageCode,
              onChanged: (value) async {
                if (value != null) {
                  await translationController.changeLanguage(value);
                  Navigator.of(context).pop();
                }
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('cancel'.tr),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About SYP Forex App'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('SYP Forex App'),
            SizedBox(height: 8),
            Text('Version: 1.0.0'),
            SizedBox(height: 8),
            Text('A comprehensive forex and SYP trading application with:'),
            SizedBox(height: 8),
            Text('• Real-time forex rates'),
            Text('• ML-powered predictions'),
            Text('• SYP black market rates'),
            Text('• Paper trading simulation'),
            Text('• MetaTrader5 integration'),
            SizedBox(height: 16),
            Text('Developed for educational and research purposes.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
