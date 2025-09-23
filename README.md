# Forex Trading App - Flutter Frontend

A comprehensive Flutter application for forex trading with real-time data and ML-powered predictions.

## 🏗️ Architecture

This Flutter app connects to a **Flask-based Forex API server** that provides:

- Real-time exchange rates from multiple sources
- Advanced ML predictions using LSTM and Transformer models
- Historical data analysis and trend detection
- Rate limiting and caching for optimal performance

### Backend Services

- **Forex API Server** (Flask/Python) - Port 5001

  - Real-time forex data and predictions
  - LSTM neural networks for time series prediction
  - Transformer models for market sentiment analysis
  - Ensemble methods for improved accuracy

- **SYP API Server** (Flask/Python) - Port 5002

  - Syrian Pound specific data and analysis
  - Custom prediction algorithms

- **MT5 API Server** (Node.js) - Port 8080
  - MetaTrader 5 integration
  - Trading signal processing

## 🚀 Getting Started

### Prerequisites

1. **Flutter SDK** (3.0+)
2. **Dart SDK** (3.0+)
3. **Flask API Server** running on localhost:5001
4. **PostgreSQL** database
5. **Redis** cache server

### Installation

1. Clone the repository:

```bash
git clone https://github.com/your-org/forex-app.git
cd forex-app
```

2. Install Flutter dependencies:

```bash
flutter pub get
```

3. Start the Flask API server:

```bash
cd server
python app.py
```

4. Run the Flutter app:

```bash
flutter run
```

## 🔧 Configuration

The app connects to the Flask server via the `ApiConfigService`. Update the server configuration in:

- `lib/config/server_config.dart` - Server endpoints and settings
- `lib/services/api_config_service.dart` - API URL configuration

### Environment Variables

Set these environment variables for the Flask server:

```bash
export FOREX_API_HOST=localhost
export FOREX_API_PORT=5001
export DATABASE_URL=postgresql://forex:password@localhost:5432/forex_db
export REDIS_URL=redis://localhost:6379/0
export EXCHANGE_RATE_API_KEY=your_api_key
export ALPHA_VANTAGE_API_KEY=your_api_key
```

## 📱 Features

### Real-time Forex Data

- Live exchange rates from multiple sources
- 7-day ML-powered predictions
- Historical data analysis
- Currency trend analysis

### ML Predictions

- **LSTM Neural Networks** for time series prediction
- **Transformer Models** for market sentiment analysis
- **Ensemble Methods** for improved accuracy
- **Real-time Processing** with caching

### Trading Features

- Paper trading simulation
- Portfolio management
- Risk assessment
- Performance analytics

## 🏛️ API Integration

The app communicates with the Flask server through these endpoints:

- `GET /forex/dashboard` - Get comprehensive dashboard data
- `GET /health` - Health check endpoint
- `GET /forex/currencies` - Get available currencies
- `GET /forex/predictions/{currency}` - Get specific currency predictions
- `POST /forex/refresh` - Force refresh of data

### Example API Call

```dart
final forexService = ForexApiService();
final dashboard = await forexService.getForexDashboard();
```

## 🧠 ML Models

The Flask server uses advanced machine learning models:

- **LSTM Networks**: Long Short-Term Memory for time series prediction
- **Transformer Models**: Attention-based models for market analysis
- **Ensemble Methods**: Combining multiple models for better accuracy
- **Real-time Inference**: Fast prediction generation

## 📊 Data Sources

- **ExchangeRate-API**: Primary real-time data source
- **Alpha Vantage**: Historical data and technical indicators
- **Yahoo Finance**: Additional market data
- **Custom APIs**: Proprietary data sources

## 🔒 Security

- API rate limiting (1000 requests/day)
- Request authentication (configurable)
- Data encryption in transit
- Secure API key management

## 🚀 Deployment

### Development

```bash
# Start Flask server
cd server && python app.py

# Start Flutter app
flutter run
```

### Production

```bash
# Build Flutter app
flutter build apk --release

# Deploy Flask server
docker-compose up -d
```

## 📈 Performance

- **Response Time**: < 500ms average
- **Cache Hit Rate**: > 90%
- **Uptime**: 99.9%
- **Concurrent Users**: 1000+

## 🛠️ Development

### Project Structure

```
lib/
├── config/           # Configuration files
├── models/           # Data models
├── services/         # API services
│   ├── internal/     # Internal processing (Flask response handling)
│   └── forex_api_service.dart
├── providers/        # State management
├── pages/           # UI pages
└── widgets/         # Reusable widgets
```

### Key Services

- **`ForexApiService`**: Main API client for Flask server
- **`ForexDataProcessor`**: Processes Flask server responses
- **`MarketAnalysisEngine`**: Handles ML prediction processing
- **`DataCacheHandler`**: Manages local caching

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test with the Flask server
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🆘 Support

For support and questions:

- Create an issue on GitHub
- Check the Flask server logs
- Review the API documentation

## 🔗 Related Projects

- **Flask Forex API Server**: Backend API service
- **Forex ML Models**: Machine learning models
- **Forex Database**: PostgreSQL database schema
- **Forex Cache**: Redis cache configuration
