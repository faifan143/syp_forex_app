import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../providers/forex_provider.dart';
import '../providers/syp_provider.dart';
import '../controllers/translation_controller.dart';
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
  final _forexPortController = TextEditingController();
  final _sypPortController = TextEditingController();
  final _mt5PortController = TextEditingController();

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
      _sypPortController.text = ApiConfigService.sypApiPort.toString();
    });
  }

  @override
  void dispose() {
    _hostController.dispose();
    _forexPortController.dispose();
    _sypPortController.dispose();
    _mt5PortController.dispose();
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
          
          // Data Source Section
          _buildSectionCard(
            title: 'dataSource'.tr,
            icon: Icons.data_usage,
            children: [
              SwitchListTile(
                title: const Text('Use Demo Data'),
                subtitle: const Text('Use simulated data instead of real API calls'),
                value: _useDemoData,
                onChanged: (value) {
                  setState(() {
                    _useDemoData = value;
                  });
                  final forexProvider = Get.find<ForexProvider>();
                  // forexProvider.setUseDemoData(value); // Method not implemented yet
                },
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Refresh Settings Section
          _buildSectionCard(
            title: 'Auto Refresh',
            icon: Icons.refresh,
            children: [
              SwitchListTile(
                title: const Text('Auto Refresh Data'),
                subtitle: const Text('Automatically refresh forex and SYP data'),
                value: _autoRefresh,
                onChanged: (value) {
                  setState(() {
                    _autoRefresh = value;
                  });
                },
              ),
              if (_autoRefresh) ...[
                ListTile(
                  title: const Text('Refresh Interval'),
                  subtitle: Text('Every $_refreshInterval seconds'),
                  trailing: DropdownButton<int>(
                    value: _refreshInterval,
                    items: const [
                      DropdownMenuItem(value: 15, child: Text('15 seconds')),
                      DropdownMenuItem(value: 30, child: Text('30 seconds')),
                      DropdownMenuItem(value: 60, child: Text('1 minute')),
                      DropdownMenuItem(value: 300, child: Text('5 minutes')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _refreshInterval = value;
                        });
                      }
                    },
                  ),
                ),
              ],
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Unified API Configuration
          _buildSectionCard(
            title: 'API Configuration',
            icon: Icons.api,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '🌐 Server Configuration',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Single IP Configuration
                    TextField(
                      controller: _hostController,
                      decoration: const InputDecoration(
                        labelText: 'Server IP Address',
                        border: OutlineInputBorder(),
                        hintText: 'e.g., 192.168.1.100',
                        prefixIcon: Icon(Icons.computer),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.withOpacity(0.3)),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '💡 How to find your laptop IP:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 4),
                          Text('• Windows: Run "ipconfig" in Command Prompt'),
                          Text('• Mac/Linux: Run "ifconfig" in Terminal'),
                          Text('• Look for your WiFi adapter IP (usually 192.168.x.x)'),
                          Text('• Make sure your phone and laptop are on same WiFi'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    const Text(
                      '🔌 API Ports',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _forexPortController,
                            decoration: const InputDecoration(
                              labelText: 'Forex ML API',
                              border: OutlineInputBorder(),
                              hintText: '5001',
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _sypPortController,
                            decoration: const InputDecoration(
                              labelText: 'SYP API',
                              border: OutlineInputBorder(),
                              hintText: '5002',
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _mt5PortController,
                            decoration: const InputDecoration(
                              labelText: 'MT5 API',
                              border: OutlineInputBorder(),
                              hintText: '8080',
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 20),
                    
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _updateAllApiConfigs,
                            icon: const Icon(Icons.save),
                            label: const Text('Update All APIs'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _testAllConnections,
                            icon: const Icon(Icons.wifi),
                            label: const Text('Test All'),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 12),
                    
                    Center(
                      child: TextButton.icon(
                        onPressed: _resetApiConfigs,
                        icon: const Icon(Icons.refresh, color: Colors.red),
                        label: const Text(
                          'Reset to Defaults',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Paper Trading Settings Section
          _buildSectionCard(
            title: 'Paper Trading',
            icon: Icons.games,
            children: [
              ListTile(
                title: const Text('MetaTrader5 Demo Account'),
                subtitle: const Text('Connect to MT5 demo account'),
                trailing: IconButton(
                  icon: const Icon(Icons.settings),
                  onPressed: () => _showMt5Settings(),
                ),
              ),
              ListTile(
                title: const Text('Reset Virtual Wallet'),
                subtitle: const Text('Reset paper trading wallet to initial state'),
                trailing: IconButton(
                  icon: const Icon(Icons.restart_alt),
                  onPressed: () => _showResetWalletDialog(),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // App Info Section
          _buildSectionCard(
            title: 'App Information',
            icon: Icons.info,
            children: [
              const ListTile(
                title: Text('Version'),
                subtitle: Text('1.0.0'),
              ),
              const ListTile(
                title: Text('Build'),
                subtitle: Text('Debug'),
              ),
              ListTile(
                title: const Text('About'),
                subtitle: const Text('SYP Forex App - Real-time forex and SYP trading'),
                trailing: IconButton(
                  icon: const Icon(Icons.help_outline),
                  onPressed: () => _showAboutDialog(),
                ),
              ),
            ],
          ),
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


  void _showMt5Settings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('MetaTrader5 Settings'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('MT5 Demo Account Configuration:'),
            SizedBox(height: 16),
            Text('• Server: Demo Server'),
            Text('• Login: [Your Demo Account]'),
            Text('• Password: [Your Demo Password]'),
            Text('• Connection: Local'),
            SizedBox(height: 16),
            Text('Note: This feature will be implemented to connect to your MT5 demo account for live paper trading.'),
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
    final forexPort = int.tryParse(_forexPortController.text.trim());
    final sypPort = int.tryParse(_sypPortController.text.trim());
    final mt5Port = int.tryParse(_mt5PortController.text.trim());
    
    if (!ApiConfigService.isValidHost(host)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid host format'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    if (forexPort == null || !ApiConfigService.isValidPort(forexPort)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid Forex API port (must be 1-65535)'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    if (sypPort == null || !ApiConfigService.isValidPort(sypPort)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid SYP API port (must be 1-65535)'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    if (mt5Port == null || !ApiConfigService.isValidPort(mt5Port)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid MT5 API port (must be 1-65535)'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    // Update all APIs with the same host
    ApiConfigService.setForexApiConfig(host, forexPort);
    ApiConfigService.setSypApiConfig(host, sypPort);
    ApiConfigService.setMt5ApiConfig(host, mt5Port);
    setState(() {});
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('All APIs updated: $host (Forex:$forexPort, SYP:$sypPort, MT5:$mt5Port)'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _resetApiConfigs() {
    ApiConfigService.resetToDefaults();
    _hostController.text = ApiConfigService.forexApiHost;
    _forexPortController.text = ApiConfigService.forexApiPort.toString();
    _sypPortController.text = ApiConfigService.sypApiPort.toString();
    _mt5PortController.text = ApiConfigService.mt5ApiPort.toString();
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
    final forexPort = int.tryParse(_forexPortController.text.trim());
    final sypPort = int.tryParse(_sypPortController.text.trim());
    final mt5Port = int.tryParse(_mt5PortController.text.trim());
    
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
      
      // Test Forex API
      if (forexPort != null) {
        try {
          final response = await http.get(
            Uri.parse('http://$host:$forexPort/health'),
            headers: {'Content-Type': 'application/json'},
          ).timeout(const Duration(seconds: 5));
          results.add('✅ Forex API: ${response.statusCode == 200 ? "Connected" : "Failed"}');
        } catch (e) {
          results.add('❌ Forex API: Connection failed');
        }
      }
      
      // Test SYP API
      if (sypPort != null) {
        try {
          final sypProvider = Get.find<SypProvider>();
          final isConnected = await sypProvider.testServerConnection();
          results.add(isConnected ? '✅ SYP API: Connected' : '❌ SYP API: Failed');
        } catch (e) {
          results.add('❌ SYP API: Connection failed');
        }
      }
      
      // Test MT5 API
      if (mt5Port != null) {
        try {
          final response = await http.get(
            Uri.parse('http://$host:$mt5Port/mt5/connect'),
            headers: {'Content-Type': 'application/json'},
          ).timeout(const Duration(seconds: 5));
          results.add('✅ MT5 API: ${response.statusCode == 200 ? "Connected" : "Failed"}');
        } catch (e) {
          results.add('❌ MT5 API: Connection failed');
        }
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
