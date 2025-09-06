# SYP Forex App

A comprehensive Flutter application for tracking Syrian Pound (SYP) exchange rates with real-time data, forecasting, and city comparisons.

## Features

### 🏦 Current Exchange Rates

- Real-time USD/SYP exchange rates
- Bid/Ask prices with spread calculation
- Daily change tracking with color-coded indicators
- Market day type classification (Calm/Normal)
- Support for multiple cities: Aleppo, Damascus, Idlib

### 🔮 Forecasting

- Tomorrow's rate prediction with confidence intervals
- Multi-day forecasts (7, 14, 30 days)
- Interactive line charts for trend visualization
- Day type predictions for market volatility

### 🌍 City Comparison

- Side-by-side rate comparison across cities
- Market statistics (average, min, max, spread)
- Real-time city switching
- Visual indicators for selected city

### 📊 Market Information

- Forecasting methodology explanation
- Volatility guide for different market conditions
- Data source attribution (SP-Today.com)
- Important disclaimers and educational content

### 🔄 Data Management

- Auto-refresh every 5 minutes
- Pull-to-refresh functionality
- Manual refresh button
- Background data updates
- Offline data caching

## Technical Architecture

### Dependencies

- **fl_chart**: Interactive charts and data visualization
- **http**: API communication with the SYP webserver
- **provider**: State management using Provider pattern
- **pull_to_refresh**: Pull-to-refresh functionality
- **shared_preferences**: Local data persistence
- **intl**: Date and number formatting

### Project Structure

```
lib/
├── models/           # Data models for API responses
├── providers/        # State management
├── services/         # API service layer
├── widgets/          # Reusable UI components
├── pages/           # Main application pages
└── main.dart        # Application entry point
```

### API Integration

The app integrates with the `syp_webserver.py` API endpoints:

- **Base URL**: `http://localhost:5000` (configurable for production)
- **Current Rates**: `GET /api/current/{city}`
- **Forecast**: `GET /api/forecast/{days}/{city}`
- **Batch Forecast**: `GET /api/batch-forecast/{days}`
- **City Comparison**: `GET /api/comparison`
- **OHLCV Data**: `GET /api/ohlcv/{city}`

## Getting Started

### Prerequisites

- Flutter SDK (3.8.0 or higher)
- Android Studio / VS Code
- Android device or emulator

### Installation

1. **Clone the repository**

   ```bash
   git clone <repository-url>
   cd syp_forex_app
   ```

2. **Install dependencies**

   ```bash
   flutter pub get
   ```

3. **Configure API endpoint**

   - Update the `baseUrl` in `lib/services/api_service.dart`
   - For production, replace `localhost:5000` with your actual server URL

4. **Run the application**
   ```bash
   flutter run
   ```

### Configuration

#### API Server Setup

Ensure your SYP webserver is running and accessible at the configured URL. The app expects the following response format:

```json
{
  "success": true,
  "timestamp": 1735569600,
  "date": "2025-01-01",
  "time": "12:00:00",
  "pair": "USD/SYP",
  "market": "black_market",
  "city": "aleppo",
  "current_rates": {
    "ask": 10870.0,
    "bid": 10820.0,
    "mid": 10845.0,
    "spread": 50.0,
    "change": -25.0,
    "change_percentage": -0.23
  }
}
```

#### Environment Variables

For production deployment, consider using environment variables for:

- API base URL
- API keys (if required)
- Feature flags

## Usage

### Main Interface

1. **Header**: City selector and refresh button
2. **Current Rates**: Large display of current exchange rate
3. **Forecast Section**: Tomorrow's prediction and multi-day charts
4. **City Comparison**: Rates across all supported cities
5. **Market Info**: Methodology and educational content

### Navigation

- **City Selection**: Tap the city icon in the header to switch between cities
- **Refresh Data**: Pull down to refresh or tap the refresh button
- **Forecast Periods**: Select 7, 14, or 30 days for extended forecasts

### Data Interpretation

- **Green Indicators**: Positive changes, calm market days
- **Red Indicators**: Negative changes, normal market days
- **Blue Highlights**: Selected city and current data
- **Confidence Intervals**: Range of predicted rates

## Development

### Adding New Features

1. **Data Models**: Extend models in `lib/models/`
2. **API Integration**: Add endpoints in `lib/services/api_service.dart`
3. **State Management**: Update `lib/providers/syp_provider.dart`
4. **UI Components**: Create widgets in `lib/widgets/`

### Testing

```bash
# Run unit tests
flutter test

# Run integration tests
flutter test integration_test/
```

### Building for Production

```bash
# Android APK
flutter build apk --release

# Android App Bundle
flutter build appbundle --release
```

## Deployment

### Android

1. Update `android/app/build.gradle` version information
2. Configure signing keys in `android/app/`
3. Build release APK or App Bundle
4. Upload to Google Play Store

### Production Considerations

- Update API base URL to production server
- Enable HTTPS for all API communications
- Implement proper error handling and logging
- Add analytics and crash reporting
- Configure push notifications for rate alerts

## Contributing

1. Fork the repository
2. Create a feature branch
3. Implement changes with proper testing
4. Submit a pull request with detailed description

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Disclaimer

**Important**: This application is for educational purposes only. Exchange rates are subject to change and may not reflect actual market conditions. Always consult with financial professionals before making investment decisions.

## Support

For technical support or feature requests:

- Create an issue in the repository
- Contact the development team
- Check the documentation for common solutions

## Changelog

### Version 1.0.0

- Initial release with core functionality
- Real-time exchange rate tracking
- Forecasting capabilities
- City comparison features
- Comprehensive market information
