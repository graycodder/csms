import 'package:firebase_core/firebase_core.dart';

enum Environment { staging, production }

class AppConfig {
  final Environment environment;
  final FirebaseOptions firebaseOptions;
  final String appTitle;

  AppConfig({
    required this.environment,
    required this.firebaseOptions,
    required this.appTitle,
  });

  bool get isStaging => environment == Environment.staging;
  bool get isProduction => environment == Environment.production;
}
