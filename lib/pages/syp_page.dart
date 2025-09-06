import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import '../providers/syp_provider.dart';
import '../widgets/current_rates_card.dart';
import '../widgets/forecast_section.dart';
import '../services/api_service.dart';

class SypPage extends StatefulWidget {
  const SypPage({super.key});

  @override
  State<SypPage> createState() => _SypPageState();
}

class _SypPageState extends State<SypPage> {
  final RefreshController _refreshController = RefreshController(initialRefresh: false);

  @override
  void initState() {
    super.initState();
    // Initialize data when page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SypProvider>().initializeData();
    });
  }

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }

  void _onRefresh() async {
    await context.read<SypProvider>().refreshData();
    _refreshController.refreshCompleted();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SmartRefresher(
        controller: _refreshController,
        onRefresh: _onRefresh,
        child: CustomScrollView(
          slivers: [
            // Header
            SliverAppBar(
              expandedHeight: 120,
              floating: false,
              pinned: true,
              backgroundColor: Colors.blue[800],
              flexibleSpace: FlexibleSpaceBar(
                title: const Text(
                  'Syrian Pound (SYP) Rates',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.blue[800]!,
                        Colors.blue[600]!,
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                // Debug button
                IconButton(
                  icon: const Icon(Icons.bug_report, color: Colors.white),
                  onPressed: () => _showDebugDialog(context),
                  tooltip: 'Debug Info',
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  onPressed: () => context.read<SypProvider>().refreshData(),
                ),
              ],
            ),
            
            // Content
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Last Updated Info
                    Consumer<SypProvider>(
                      builder: (context, provider, child) {
                        if (provider.currentRates != null) {
                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.1),
                                  spreadRadius: 1,
                                  blurRadius: 3,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.access_time,
                                  color: Colors.grey[600],
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Last Updated: ${provider.currentRates!.date} ${provider.currentRates!.time}',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Current Rates Card
                    const CurrentRatesCard(),
                    
                    const SizedBox(height: 16),
                    
                    // Forecast Section
                    const ForecastSection(),
                    
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDebugDialog(BuildContext context) {
    final provider = context.read<SypProvider>();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🔍 Debug Information'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('🏙️ Selected City: ${provider.selectedCity.toUpperCase()}'),
              Text('📅 Forecast Days: ${provider.selectedForecastDays}'),
              Text('⏳ Loading: ${provider.isLoading}'),
              if (provider.error != null) Text('🚨 Error: ${provider.error}'),
              const SizedBox(height: 16),
              Text('💱 Current Rates: ${provider.currentRates != null ? "✅ Loaded" : "❌ Not loaded"}'),
              Text('🔮 Forecast: ${provider.forecast != null ? "✅ Loaded" : "❌ Not loaded"}'),
              const SizedBox(height: 16),
              const Text('Click "Test Connection" to check server connectivity'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              _testServerConnection(context);
            },
            child: const Text('🧪 Test Connection'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              _testBasicConnection(context);
            },
            child: const Text('🔌 Basic Connection'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              provider.debugCurrentState();
            },
            child: const Text('🔍 Debug State'),
          ),
        ],
      ),
    );
  }

  void _testServerConnection(BuildContext context) {
    final provider = context.read<SypProvider>();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        title: Text('🧪 Testing Connection'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Testing connection to server...'),
          ],
        ),
      ),
    );

    provider.testServerConnection().then((isConnected) {
      Navigator.of(context).pop(); // Close loading dialog
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(isConnected ? '✅ Connected' : '❌ Connection Failed'),
          content: Text(
            isConnected 
              ? 'Successfully connected to the SYP webserver!'
              : 'Failed to connect to the SYP webserver. Check if the server is running and accessible.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
            if (!isConnected)
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _showDebugDialog(context);
                },
                child: const Text('Debug'),
              ),
          ],
        ),
      );
    }).catchError((error) {
      Navigator.of(context).pop(); // Close loading dialog
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('❌ Connection Error'),
          content: Text('Error testing connection: $error'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    });
  }

  void _testBasicConnection(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        title: Text('🔌 Testing Basic Connection'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Testing basic connection to server...'),
          ],
        ),
      ),
    );

    try {
      final isConnected = await ApiService.testBasicConnection();
      Navigator.of(context).pop(); // Close loading dialog
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(isConnected ? '✅ Basic Connection OK' : '❌ Basic Connection Failed'),
          content: Text(
            isConnected 
              ? 'Basic connection to server successful! The server is reachable.'
              : 'Basic connection failed. This suggests a network configuration issue.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
            if (!isConnected)
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _showDebugDialog(context);
                },
                child: const Text('Debug'),
              ),
          ],
        ),
      );
    } catch (error) {
      Navigator.of(context).pop(); // Close loading dialog
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('❌ Basic Test Failed'),
          content: Text('Basic connection test failed with error: $error'),
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
}

