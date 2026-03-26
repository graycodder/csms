import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/subscription_entity.dart';
import '../entities/subscription_log_entity.dart';

abstract class SubscriptionRepository {
  Future<Either<Failure, void>> createSubscription({
    required String shopId,
    required String customerId,
    required String productId,
    required String ownerId,
    required String updatedById,
    required int validityValue,
    required String validityUnit,
    required double price,
    required String productName,
  });

  Future<Either<Failure, void>> renewSubscription({
    required String subscriptionId,
    required int validityValue,
    required String validityUnit,
    required String updatedById,
    required String productName,
    double? price,
  });

  Future<Either<Failure, void>> updateSubscription({
    required String subscriptionId,
    required DateTime endDate,
    required double price,
    required String updatedById,
  });

  Stream<Either<Failure, List<SubscriptionEntity>>> getSubscriptions(
    String customerId,
    String ownerId,
  );

  Future<Either<Failure, List<SubscriptionEntity>>> getExpiringSubscriptions({
    required String shopId,
    required String ownerId,
    required int notificationDaysBefore,
  });

  Future<Either<Failure, List<SubscriptionEntity>>> getActiveSubscriptions({
    required String shopId,
    required String ownerId,
  });

  Future<Either<Failure, void>> deleteSubscriptionsForCustomer(String customerId);

  Future<Either<Failure, List<SubscriptionLogEntity>>> getSubscriptionLogs({
    required String shopId,
    required String ownerId,
    String? customerId,
  });
}
