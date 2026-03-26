import 'package:csms/main.dart';
import 'package:csms/core/config/app_config.dart';
import 'package:csms/firebase_options.dart';

void main() async {
  await bootstrap(AppConfig(
    environment: Environment.production,
    firebaseOptions: DefaultFirebaseOptions.currentPlatform,
    appTitle: 'Business Manager',
  ));
}
