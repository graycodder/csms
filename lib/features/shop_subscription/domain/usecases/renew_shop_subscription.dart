import 'package:dartz/dartz.dart';
import 'package:csms/core/error/failures.dart';
import '../repositories/shop_subscription_repository.dart';

class RenewShopSubscription {
  final ShopSubscriptionRepository repository;
  RenewShopSubscription(this.repository);

  Future<Either<Failure, void>> call({
    required String shopId,
    required String ownerId,
    required int validityValue,
    required String validityUnit,
    required double price,
    required String updatedById,
  }) async {
    return await repository.renewShopSubscription(
      shopId: shopId,
      ownerId: ownerId,
      validityValue: validityValue,
      validityUnit: validityUnit,
      price: price,
      updatedById: updatedById,
    );
  }
}
