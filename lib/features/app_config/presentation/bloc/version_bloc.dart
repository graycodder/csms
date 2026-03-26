import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:dartz/dartz.dart';
import 'dart:async';
import 'package:csms/core/error/failures.dart';
import '../../domain/entities/app_config_entity.dart';
import '../../domain/repositories/app_config_repository.dart';

// Events
abstract class VersionEvent extends Equatable {
  const VersionEvent();
  @override
  List<Object?> get props => [];
}

class MonitorVersion extends VersionEvent {}

// States
abstract class VersionState extends Equatable {
  const VersionState();
  @override
  List<Object?> get props => [];
}

class VersionInitial extends VersionState {}
class VersionLoading extends VersionState {}

class VersionUpToDate extends VersionState {
  final String currentVersion;
  const VersionUpToDate(this.currentVersion);
  @override
  List<Object?> get props => [currentVersion];
}

class UpdateRequired extends VersionState {
  final String minVersion;
  final String currentVersion;
  final String updateUrl;

  const UpdateRequired({
    required this.minVersion,
    required this.currentVersion,
    required this.updateUrl,
  });

  @override
  List<Object?> get props => [minVersion, currentVersion, updateUrl];
}

class VersionError extends VersionState {
  final String message;
  const VersionError(this.message);
  @override
  List<Object?> get props => [message];
}

// Bloc
class VersionBloc extends Bloc<VersionEvent, VersionState> {
  final AppConfigRepository repository;

  VersionBloc({required this.repository}) : super(VersionInitial()) {
    on<MonitorVersion>(_onMonitorVersion);
  }

  Future<void> _onMonitorVersion(MonitorVersion event, Emitter<VersionState> emit) async {
    emit(VersionLoading());
    
    final packageInfo = await PackageInfo.fromPlatform();
    final currentVersion = packageInfo.version;
    debugPrint('FORCE_UPDATE: Current version is $currentVersion');

    await emit.forEach<Either<Failure, AppConfigEntity>>(
      repository.streamAppConfig(),
      onData: (result) {
        return result.fold(
          (failure) {
            debugPrint('FORCE_UPDATE: Stream error: ${failure.message}');
            return VersionError(failure.message);
          },
          (config) {
            debugPrint('FORCE_UPDATE: Remote min version: ${config.minVersion}');
            final required = _isUpdateRequired(currentVersion, config.minVersion);
            debugPrint('FORCE_UPDATE: Update required? $required');
            if (required) {
              return UpdateRequired(
                minVersion: config.minVersion,
                currentVersion: currentVersion,
                updateUrl: config.forceUpdateUrl,
              );
            }
            return VersionUpToDate(currentVersion);
          },
        );
      },
      onError: (error, _) => VersionError(error.toString()),
    );
  }

  bool _isUpdateRequired(String current, String minimum) {
    try {
      final currentParts = current.split('.').map(int.parse).toList();
      final minParts = minimum.split('.').map(int.parse).toList();

      for (var i = 0; i < 3; i++) {
        final currentPart = i < currentParts.length ? currentParts[i] : 0;
        final minPart = i < minParts.length ? minParts[i] : 0;

        if (currentPart < minPart) return true;
        if (currentPart > minPart) return false;
      }
      return false;
    } catch (e) {
      // In case of parsing error, safer to not lock or handle as up-to-date
      return false;
    }
  }
}
