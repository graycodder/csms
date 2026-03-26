import 'package:firebase_database/firebase_database.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/profile_entity.dart';
import '../../domain/repositories/profile_repository.dart';
import '../models/profile_model.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final FirebaseDatabase _database;

  ProfileRepositoryImpl({FirebaseDatabase? database})
      : _database = database ?? FirebaseDatabase.instance;

  @override
  Future<Either<Failure, ProfileEntity>> getProfile(String userId) async {
    try {
      final snapshot = await _database.ref().child('users').child(userId).get();
      if (snapshot.value != null) {
        final profile = ProfileModel.fromJson(
          Map<dynamic, dynamic>.from(snapshot.value as Map),
          userId,
        );
        return Right(profile);
      }
      return const Left(ServerFailure('Profile not found'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateProfile(ProfileEntity profile) async {
    try {
      final model = ProfileModel(
        uid: profile.uid,
        fullName: profile.fullName,
        email: profile.email,
        phone: profile.phone,
        role: profile.role,
        profileImageUrl: profile.profileImageUrl,
        createdAt: profile.createdAt,
        updatedAt: DateTime.now(),
      );
      
      await _database.ref().child('users').child(profile.uid).update(model.toJson());
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
