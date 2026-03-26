import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/app_config_entity.dart';

abstract class AppConfigRepository {
  Stream<Either<Failure, AppConfigEntity>> streamAppConfig();
}
