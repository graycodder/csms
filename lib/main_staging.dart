import 'package:csms/main.dart';
import 'package:csms/core/config/app_config.dart';
import 'package:csms/firebase_options_staging.dart';

void main() async {
  print('DEBUG: main_staging started');
  await bootstrap(AppConfig(
    environment: Environment.staging,
    firebaseOptions: DefaultFirebaseOptions.currentPlatform,
    appTitle: 'CSMS',
  ));
}
