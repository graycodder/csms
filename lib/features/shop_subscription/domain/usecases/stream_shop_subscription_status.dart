import 'package:dartz/dartz.dart';
import 'package:csms/core/error/failures.dart';
import '../entities/shop_subscription_entity.dart';
import '../repositories/shop_subscription_repository.dart';

class StreamShopSubscriptionStatus {
  final ShopSubscriptionRepository repository;
  StreamShopSubscriptionStatus(this.repository);

  Stream<Either<Failure, ShopSubscriptionEntity>> call(String shopId) {
    return repository.getShopSubscriptionStatusStream(shopId);
  }
}
