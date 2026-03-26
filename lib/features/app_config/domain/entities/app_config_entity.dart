import 'package:equatable/equatable.dart';

class AppConfigEntity extends Equatable {
  final String minVersion;
  final String forceUpdateUrl;

  const AppConfigEntity({
    required this.minVersion,
    required this.forceUpdateUrl,
  });

  @override
  List<Object?> get props => [minVersion, forceUpdateUrl];
}
