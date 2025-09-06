import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/syp_provider.dart';
import '../models/api_responses.dart';

class ForecastSection extends StatelessWidget {
  const ForecastSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SypProvider>(
      builder: (context, provider, child) {
        if (provider.forecast == null) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Tomorrow\'s Prediction',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TomorrowPredictionCard(forecast: provider.forecast!),
          ],
        );
      },
    );
  }
}

class TomorrowPredictionCard extends StatelessWidget {
  const TomorrowPredictionCard({super.key, required this.forecast});
  final ForecastResponse forecast;

  @override
  Widget build(BuildContext context) {
    return Consumer<SypProvider>(
      builder: (context, provider, child) {
        final prediction = forecast.prediction;

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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.trending_up,
                    color: Colors.blue[600],
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Tomorrow\'s Prediction',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // Predicted Rate
              Center(
                child: Column(
                  children: [
                    Text(
                      provider.formatRate(prediction.rate),
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[800],
                      ),
                    ),
                    Text(
                      'SYP per USD',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Expected Change
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: provider.isPositiveChange(prediction.expectedChange)
                      ? Colors.green[50]
                      : Colors.red[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: provider.isPositiveChange(prediction.expectedChange)
                        ? Colors.green[200]!
                        : Colors.red[200]!,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Expected Change',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                    Text(
                      provider.formatChange(prediction.expectedChange),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: provider.isPositiveChange(prediction.expectedChange)
                            ? Colors.green[600]
                            : Colors.red[600],
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Confidence Interval
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Confidence Interval',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Range: ${prediction.confidenceInterval.rangePct.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          '${provider.formatRate(prediction.confidenceInterval.lower)} - ${provider.formatRate(prediction.confidenceInterval.upper)}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Day Type
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: provider.isCalmDay(prediction.dayType)
                      ? Colors.green[100]
                      : Colors.orange[100],
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: provider.isCalmDay(prediction.dayType)
                        ? Colors.green[300]!
                        : Colors.orange[300]!,
                  ),
                ),
                child: Text(
                  'Predicted: ${prediction.dayType.toUpperCase()} DAY',
                  style: TextStyle(
                    color: provider.isCalmDay(prediction.dayType)
                        ? Colors.green[700]
                        : Colors.orange[700],
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

