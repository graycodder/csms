import 'package:equatable/equatable.dart';
import 'shop_subscription_log_entity.dart';


class ShopSubscriptionEntity extends Equatable {
  final String shopId;
  final String shopName;
  final ActivePlanEntity? activePlan;
  final List<QueuedPlanEntity> queuedPlans;
  final List<ShopSubscriptionLogEntity> history;

  const ShopSubscriptionEntity({
    required this.shopId,
    required this.shopName,
    this.activePlan,
    this.queuedPlans = const [],
    this.history = const [],
  });

  @override
  List<Object?> get props => [shopId, shopName, activePlan, queuedPlans, history];
}

class ActivePlanEntity extends Equatable {
  final String planId;
  final String planName;
  final DateTime startDate;
  final DateTime endDate;
  final String status;
  final double price;

  const ActivePlanEntity({
    required this.planId,
    required this.planName,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.price,
  });

  @override
  List<Object?> get props => [
    planId,
    planName,
    startDate,
    endDate,
    status,
    price,
  ];
}

class QueuedPlanEntity extends Equatable {
  final String queueId;
  final String planId;
  final String planName;
  final int durationInDays;

  const QueuedPlanEntity({
    required this.queueId,
    required this.planId,
    required this.planName,
    required this.durationInDays,
  });

  @override
  List<Object?> get props => [queueId, planId, planName, durationInDays];
}
