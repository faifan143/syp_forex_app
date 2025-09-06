import 'lib/services/market_simulation_service.dart';

void main() {
  print('🚀 Testing Market Simulation Service...');
  
  final marketService = MarketSimulationService();
  
  // Start simulation
  marketService.startSimulation();
  
  // Test price updates
  marketService.priceStream.listen((prices) {
    print('📈 Current Prices:');
    prices.forEach((symbol, price) {
      print('  $symbol: ${price.toStringAsFixed(5)}');
    });
    print('---');
  });
  
  // Test chart data
  marketService.chartStream.listen((chartData) {
    print('📊 Chart Data Updated for ${chartData.length} symbols');
  });
  
  // Test specific symbol
  print('🎯 Testing EUR/USD:');
  print('  Current Price: ${marketService.getCurrentPrice('EUR/USD').toStringAsFixed(5)}');
  print('  Bid Price: ${marketService.getBidPrice('EUR/USD').toStringAsFixed(5)}');
  print('  Ask Price: ${marketService.getAskPrice('EUR/USD').toStringAsFixed(5)}');
  
  // Keep running for 10 seconds
  Future.delayed(Duration(seconds: 10), () {
    print('✅ Test completed!');
    marketService.dispose();
  });
}

