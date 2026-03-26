import 'package:csms/features/shop_subscription/domain/entities/shop_subscription_entity.dart';

class ShopSubscriptionModel extends ShopSubscriptionEntity {
  const ShopSubscriptionModel({
    required super.shopId,
    required super.shopName,
    super.activePlan,
    super.queuedPlans = const [],
  });

  factory ShopSubscriptionModel.fromJson(Map<dynamic, dynamic> json, String id) {
    return ShopSubscriptionModel(
      shopId: id,
      shopName: json['shopName'] ?? '',
      activePlan: json['active'] != null
          ? ActivePlanModel.fromJson(Map<String, dynamic>.from(json['active'] as Map))
          : null,
      queuedPlans: json['queued'] != null
          ? (json['queued'] as Map<dynamic, dynamic>).entries.map((e) {
              return QueuedPlanModel.fromJson(Map<String, dynamic>.from(e.value as Map), e.key.toString());
            }).toList()
          : [],
    );
  }
}

class ActivePlanModel extends ActivePlanEntity {
  const ActivePlanModel({
    required super.planId,
    required super.planName,
    required super.startDate,
    required super.endDate,
    required super.status,
    required super.price,
  });

  factory ActivePlanModel.fromJson(Map<String, dynamic> json) {
    return ActivePlanModel(
      planId: json['planId'] ?? '',
      planName: json['planName'] ?? '',
      startDate: DateTime.fromMillisecondsSinceEpoch(json['startDate'] ?? 0),
      endDate: DateTime.fromMillisecondsSinceEpoch(json['endDate'] ?? 0),
      status: json['status'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
    );
  }
}

class QueuedPlanModel extends QueuedPlanEntity {
  const QueuedPlanModel({
    required super.queueId,
    required super.planId,
    required super.planName,
    required super.durationInDays,
  });

  factory QueuedPlanModel.fromJson(Map<String, dynamic> json, String id) {
    return QueuedPlanModel(
      queueId: id,
      planId: json['planId'] ?? '',
      planName: json['planName'] ?? '',
      durationInDays: json['durationInDays'] ?? 0,
    );
  }
}
