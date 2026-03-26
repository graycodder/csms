import 'package:csms/main.dart';
import 'package:csms/core/config/app_config.dart';
import 'package:csms/firebase_options.dart';

void main() async {
  // TODO: Replace with StagingFirebaseOptions when available
  await bootstrap(AppConfig(
    environment: Environment.staging,
    firebaseOptions: DefaultFirebaseOptions.currentPlatform,
    appTitle: 'Business Manager Staging',
  ));
}
