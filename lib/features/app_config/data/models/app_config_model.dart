import '../../domain/entities/app_config_entity.dart';

class AppConfigModel extends AppConfigEntity {
  const AppConfigModel({
    required super.minVersion,
    required super.forceUpdateUrl,
  });

  factory AppConfigModel.fromJson(Map<dynamic, dynamic> json) {
    return AppConfigModel(
      minVersion: json['min_version'] ?? '1.0.0',
      forceUpdateUrl: json['force_update_url'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'min_version': minVersion,
      'force_update_url': forceUpdateUrl,
    };
  }
}
