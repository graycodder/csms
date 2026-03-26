import 'package:dartz/dartz.dart';
import 'package:csms/core/error/failures.dart';
import '../repositories/shop_subscription_repository.dart';
import '../entities/shop_subscription_log_entity.dart';

class GetShopSubscriptionHistory {
  final ShopSubscriptionRepository repository;
  GetShopSubscriptionHistory(this.repository);

  Future<Either<Failure, List<ShopSubscriptionLogEntity>>> call(String shopId, String ownerId) async {
    return await repository.getShopSubscriptionHistory(shopId, ownerId);
  }
}
