import 'package:equatable/equatable.dart';
import 'subscription_log_entity.dart';

class SubscriptionEntity extends Equatable {
  final String subscriptionId;
  final String shopId;
  final String customerId;
  final String productId;
  final DateTime startDate;
  final DateTime endDate;
  final String status;
  final List<SubscriptionLogEntity> logs;
  final DateTime createdAt;
  final DateTime updatedAt;
  final double price;
  final String updatedById;
  final String ownerId;

  const SubscriptionEntity({
    required this.subscriptionId,
    required this.shopId,
    required this.customerId,
    required this.productId,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.logs,
    required this.createdAt,
    required this.updatedAt,
    required this.price,
    required this.updatedById,
    required this.ownerId,
  });

  @override
  List<Object?> get props => [
    subscriptionId,
    shopId,
    customerId,
    productId,
    startDate,
    endDate,
    status,
    logs,
    createdAt,
    updatedAt,
    price,
    updatedById,
    ownerId,
  ];
}
