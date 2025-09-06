import 'package:flutter/material.dart';

class OnboardingPage {
  final String id;
  final String titleKey;
  final String descriptionKey;
  final String imagePath;
  final IconData icon;
  final Color primaryColor;
  final Color secondaryColor;
  final List<String> features;
  final OnboardingPageType type;

  const OnboardingPage({
    required this.id,
    required this.titleKey,
    required this.descriptionKey,
    required this.imagePath,
    required this.icon,
    required this.primaryColor,
    required this.secondaryColor,
    required this.features,
    required this.type,
  });
}

enum OnboardingPageType {
  welcome,
  homePage,
  sypPage,
  paperTrading,
  tradingTerms,
  predictions,
  charts,
  riskManagement,
  settings,
  complete,
}

class OnboardingContent {
  static const List<OnboardingPage> pages = [
    OnboardingPage(
      id: 'welcome',
      titleKey: 'onboardingWelcomeTitle',
      descriptionKey: 'onboardingWelcomeDescription',
      imagePath: 'assets/images/onboarding/welcome.png',
      icon: Icons.waving_hand,
      primaryColor: Colors.blue,
      secondaryColor: Colors.lightBlue,
      features: [
        'onboardingWelcomeFeature1',
        'onboardingWelcomeFeature2',
        'onboardingWelcomeFeature3',
        'onboardingWelcomeFeature4',
      ],
      type: OnboardingPageType.welcome,
    ),
    OnboardingPage(
      id: 'home',
      titleKey: 'onboardingHomeTitle',
      descriptionKey: 'onboardingHomeDescription',
      imagePath: 'assets/images/onboarding/home.png',
      icon: Icons.home,
      primaryColor: Colors.green,
      secondaryColor: Colors.lightGreen,
      features: [
        'onboardingHomeFeature1',
        'onboardingHomeFeature2',
        'onboardingHomeFeature3',
        'onboardingHomeFeature4',
      ],
      type: OnboardingPageType.homePage,
    ),
    OnboardingPage(
      id: 'syp',
      titleKey: 'onboardingSypTitle',
      descriptionKey: 'onboardingSypDescription',
      imagePath: 'assets/images/onboarding/syp.png',
      icon: Icons.currency_exchange,
      primaryColor: Colors.orange,
      secondaryColor: Colors.amber,
      features: [
        'onboardingSypFeature1',
        'onboardingSypFeature2',
        'onboardingSypFeature3',
        'onboardingSypFeature4',
      ],
      type: OnboardingPageType.sypPage,
    ),
    OnboardingPage(
      id: 'paper_trading',
      titleKey: 'onboardingPaperTradingTitle',
      descriptionKey: 'onboardingPaperTradingDescription',
      imagePath: 'assets/images/onboarding/paper_trading.png',
      icon: Icons.trending_up,
      primaryColor: Colors.purple,
      secondaryColor: Colors.deepPurple,
      features: [
        'onboardingPaperTradingFeature1',
        'onboardingPaperTradingFeature2',
        'onboardingPaperTradingFeature3',
        'onboardingPaperTradingFeature4',
      ],
      type: OnboardingPageType.paperTrading,
    ),
    OnboardingPage(
      id: 'trading_terms',
      titleKey: 'onboardingTradingTermsTitle',
      descriptionKey: 'onboardingTradingTermsDescription',
      imagePath: 'assets/images/onboarding/trading_terms.png',
      icon: Icons.book,
      primaryColor: Colors.indigo,
      secondaryColor: Colors.blue,
      features: [
        'onboardingTradingTermsFeature1',
        'onboardingTradingTermsFeature2',
        'onboardingTradingTermsFeature3',
        'onboardingTradingTermsFeature4',
      ],
      type: OnboardingPageType.tradingTerms,
    ),
    OnboardingPage(
      id: 'predictions',
      titleKey: 'onboardingPredictionsTitle',
      descriptionKey: 'onboardingPredictionsDescription',
      imagePath: 'assets/images/onboarding/predictions.png',
      icon: Icons.psychology,
      primaryColor: Colors.teal,
      secondaryColor: Colors.cyan,
      features: [
        'onboardingPredictionsFeature1',
        'onboardingPredictionsFeature2',
        'onboardingPredictionsFeature3',
        'onboardingPredictionsFeature4',
      ],
      type: OnboardingPageType.predictions,
    ),
    OnboardingPage(
      id: 'charts',
      titleKey: 'onboardingChartsTitle',
      descriptionKey: 'onboardingChartsDescription',
      imagePath: 'assets/images/onboarding/charts.png',
      icon: Icons.bar_chart,
      primaryColor: Colors.red,
      secondaryColor: Colors.pink,
      features: [
        'onboardingChartsFeature1',
        'onboardingChartsFeature2',
        'onboardingChartsFeature3',
        'onboardingChartsFeature4',
      ],
      type: OnboardingPageType.charts,
    ),
    OnboardingPage(
      id: 'risk_management',
      titleKey: 'onboardingRiskManagementTitle',
      descriptionKey: 'onboardingRiskManagementDescription',
      imagePath: 'assets/images/onboarding/risk_management.png',
      icon: Icons.shield,
      primaryColor: Colors.brown,
      secondaryColor: Colors.amber,
      features: [
        'onboardingRiskManagementFeature1',
        'onboardingRiskManagementFeature2',
        'onboardingRiskManagementFeature3',
        'onboardingRiskManagementFeature4',
      ],
      type: OnboardingPageType.riskManagement,
    ),
    OnboardingPage(
      id: 'settings',
      titleKey: 'onboardingSettingsTitle',
      descriptionKey: 'onboardingSettingsDescription',
      imagePath: 'assets/images/onboarding/settings.png',
      icon: Icons.settings,
      primaryColor: Colors.grey,
      secondaryColor: Colors.blueGrey,
      features: [
        'onboardingSettingsFeature1',
        'onboardingSettingsFeature2',
        'onboardingSettingsFeature3',
        'onboardingSettingsFeature4',
      ],
      type: OnboardingPageType.settings,
    ),
    OnboardingPage(
      id: 'complete',
      titleKey: 'onboardingCompleteTitle',
      descriptionKey: 'onboardingCompleteDescription',
      imagePath: 'assets/images/onboarding/complete.png',
      icon: Icons.check_circle,
      primaryColor: Colors.green,
      secondaryColor: Colors.lightGreen,
      features: [
        'onboardingCompleteFeature1',
        'onboardingCompleteFeature2',
        'onboardingCompleteFeature3',
        'onboardingCompleteFeature4',
      ],
      type: OnboardingPageType.complete,
    ),
  ];
}

class TradingTerm {
  final String termKey;
  final String definitionKey;
  final String exampleKey;
  final IconData icon;
  final Color color;

  const TradingTerm({
    required this.termKey,
    required this.definitionKey,
    required this.exampleKey,
    required this.icon,
    required this.color,
  });
}

class TradingTermsData {
  static const List<TradingTerm> terms = [
    TradingTerm(
      termKey: 'tradingTermBid',
      definitionKey: 'tradingTermBidDefinition',
      exampleKey: 'tradingTermBidExample',
      icon: Icons.arrow_downward,
      color: Colors.red,
    ),
    TradingTerm(
      termKey: 'tradingTermAsk',
      definitionKey: 'tradingTermAskDefinition',
      exampleKey: 'tradingTermAskExample',
      icon: Icons.arrow_upward,
      color: Colors.green,
    ),
    TradingTerm(
      termKey: 'tradingTermSpread',
      definitionKey: 'tradingTermSpreadDefinition',
      exampleKey: 'tradingTermSpreadExample',
      icon: Icons.compare_arrows,
      color: Colors.orange,
    ),
    TradingTerm(
      termKey: 'tradingTermPip',
      definitionKey: 'tradingTermPipDefinition',
      exampleKey: 'tradingTermPipExample',
      icon: Icons.timeline,
      color: Colors.blue,
    ),
    TradingTerm(
      termKey: 'tradingTermLeverage',
      definitionKey: 'tradingTermLeverageDefinition',
      exampleKey: 'tradingTermLeverageExample',
      icon: Icons.auto_awesome,
      color: Colors.purple,
    ),
    TradingTerm(
      termKey: 'tradingTermMargin',
      definitionKey: 'tradingTermMarginDefinition',
      exampleKey: 'tradingTermMarginExample',
      icon: Icons.account_balance,
      color: Colors.indigo,
    ),
    TradingTerm(
      termKey: 'tradingTermStopLoss',
      definitionKey: 'tradingTermStopLossDefinition',
      exampleKey: 'tradingTermStopLossExample',
      icon: Icons.stop,
      color: Colors.red,
    ),
    TradingTerm(
      termKey: 'tradingTermTakeProfit',
      definitionKey: 'tradingTermTakeProfitDefinition',
      exampleKey: 'tradingTermTakeProfitExample',
      icon: Icons.trending_up,
      color: Colors.green,
    ),
    TradingTerm(
      termKey: 'tradingTermLong',
      definitionKey: 'tradingTermLongDefinition',
      exampleKey: 'tradingTermLongExample',
      icon: Icons.keyboard_arrow_up,
      color: Colors.green,
    ),
    TradingTerm(
      termKey: 'tradingTermShort',
      definitionKey: 'tradingTermShortDefinition',
      exampleKey: 'tradingTermShortExample',
      icon: Icons.keyboard_arrow_down,
      color: Colors.red,
    ),
  ];
}
