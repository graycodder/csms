import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';

abstract class OnboardingRepository {
  Future<Either<Failure, void>> registerOwnerAndShop({
    required String ownerId,
    required String name,
    required String mobile,
    required String email,
    required String shopName,
    required String shopCategory,
    required String shopAddress,
    String? password,
  });
}
