import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/syp_provider.dart';
import '../models/api_responses.dart';

class CurrentRatesCard extends StatelessWidget {
  const CurrentRatesCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SypProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return _buildLoadingCard();
        }

        if (provider.currentRates == null) {
          return _buildErrorCard(context, provider);
        }

        return _buildRatesCard(context, provider.currentRates!, provider);
      },
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildErrorCard(BuildContext context, SypProvider provider) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red[400],
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            'Failed to load rates',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          if (provider.error != null)
            Text(
              provider.error!,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => provider.refreshData(),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildRatesCard(BuildContext context, CurrentRatesResponse rates, SypProvider provider) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Last updated
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Last Updated: ${rates.date} ${rates.time}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Main rate display
            Center(
              child: Column(
                children: [
                  Text(
                    provider.formatRate(rates.currentRates.mid),
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  Text(
                    'SYP per USD',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Day type indicator
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: provider.isCalmDay(rates.ohlcv.dayType)
                      ? Colors.green
                      : Colors.orange,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  rates.ohlcv.dayType.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Rate details
            Row(
              children: [
                Expanded(
                  child: _buildRateItem(
                    'Bid',
                    provider.formatRate(rates.currentRates.bid),
                    Colors.red,
                  ),
                ),
                Expanded(
                  child: _buildRateItem(
                    'Ask',
                    provider.formatRate(rates.currentRates.ask),
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildRateItem(
                    'Spread',
                    provider.formatRate(rates.currentRates.spread),
                    Colors.orange,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Daily change
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Daily Change',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      Icon(
                        provider.isPositiveChange(rates.currentRates.change)
                            ? Icons.trending_up
                            : Icons.trending_down,
                        color: provider.isPositiveChange(rates.currentRates.change)
                            ? Colors.green
                            : Colors.red,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        provider.formatChange(rates.currentRates.change),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: provider.isPositiveChange(rates.currentRates.change)
                              ? Colors.green
                              : Colors.red,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '(${rates.currentRates.changePercentage.toStringAsFixed(2)}%)',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: provider.isPositiveChange(rates.currentRates.change)
                              ? Colors.green
                              : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRateItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

