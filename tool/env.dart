import 'package:path/path.dart' as p;
import 'dart:io';

void main(List<String> args) {
  if (args.isEmpty || (args[0] != 'staging' && args[0] != 'prod')) {
    print('Usage: dart run tool/env.dart [staging|prod]');
    exit(1);
  }

  final env = args[0];
  print('Switching Mobile Environment to: ${env.toUpperCase()}');

  final currentDir = Directory.current.path;
  final configDir = p.join(currentDir, 'config', env);

  final androidTarget = p.join(currentDir, 'android', 'app', 'google-services.json');
  final iosTarget = p.join(currentDir, 'ios', 'Runner', 'GoogleService-Info.plist');

  final androidSource = p.join(configDir, 'google-services.json');
  final iosSource = p.join(configDir, 'GoogleService-Info.plist');

  try {
    File(androidSource).copySync(androidTarget);
    print('✅ Copied Android google-services.json');
  } catch (e) {
    print('❌ Failed to copy Android config: \$e');
  }

  try {
    File(iosSource).copySync(iosTarget);
    print('✅ Copied iOS GoogleService-Info.plist');
  } catch (e) {
    print('❌ Failed to copy iOS config: \$e');
  }

  print('Done! You can now run the app on mobile.');
}
