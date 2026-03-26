import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/shop_subscription_entity.dart';
import '../entities/shop_subscription_log_entity.dart';

abstract class ShopSubscriptionRepository {
  Future<Either<Failure, ShopSubscriptionEntity>> getShopSubscriptionStatus(String shopId);
  Stream<Either<Failure, ShopSubscriptionEntity>> getShopSubscriptionStatusStream(String shopId);
  Future<Either<Failure, List<ShopSubscriptionLogEntity>>> getShopSubscriptionHistory(String shopId, String ownerId);
  Future<Either<Failure, void>> renewShopSubscription({
    required String shopId,
    required String ownerId,
    required int validityValue,
    required String validityUnit,
    required double price,
    required String updatedById,
  });
}
