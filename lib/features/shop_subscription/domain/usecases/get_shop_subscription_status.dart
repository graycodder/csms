import 'package:dartz/dartz.dart';
import 'package:csms/core/error/failures.dart';
import '../entities/shop_subscription_entity.dart';
import '../repositories/shop_subscription_repository.dart';

class GetShopSubscriptionStatus {
  final ShopSubscriptionRepository repository;
  GetShopSubscriptionStatus(this.repository);

  Future<Either<Failure, ShopSubscriptionEntity>> call(String shopId) async {
    return await repository.getShopSubscriptionStatus(shopId);
  }
}
