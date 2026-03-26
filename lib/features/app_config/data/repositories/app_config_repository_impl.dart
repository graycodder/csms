import 'package:firebase_database/firebase_database.dart';
import 'package:dartz/dartz.dart';
import 'package:csms/core/error/failures.dart';
import '../../domain/repositories/app_config_repository.dart';
import '../../domain/entities/app_config_entity.dart';
import '../models/app_config_model.dart';

class AppConfigRepositoryImpl implements AppConfigRepository {
  final FirebaseDatabase _database;

  AppConfigRepositoryImpl({FirebaseDatabase? database})
      : _database = database ?? FirebaseDatabase.instance;

  @override
  Stream<Either<Failure, AppConfigEntity>> streamAppConfig() {
    return _database.ref().child('app_config').onValue.asyncMap((event) async {
      try {
        final data = event.snapshot.value;
        if (data == null) {
          return Left(ServerFailure('App config not found'));
        }
        final mapData = Map<dynamic, dynamic>.from(data as Map);
        return Right(AppConfigModel.fromJson(mapData));
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    });
  }
}
