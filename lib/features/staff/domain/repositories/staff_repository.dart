import 'package:dartz/dartz.dart';
import 'package:csms/core/error/failures.dart';
import '../entities/staff_entity.dart';

abstract class StaffRepository {
  Stream<Either<Failure, List<StaffEntity>>> getStaff(String shopId, String ownerId);
  Future<Either<Failure, void>> addStaff(String shopId, String ownerId, StaffEntity staff, {String? password});
  Future<Either<Failure, void>> updateStaff(String shopId, String ownerId, StaffEntity staff);
  Future<Either<Failure, void>> deleteStaff(String shopId, String ownerId, String staffId);
}
