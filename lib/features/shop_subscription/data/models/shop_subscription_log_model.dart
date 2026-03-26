import 'package:csms/features/shop_subscription/domain/entities/shop_subscription_log_entity.dart';

class ShopSubscriptionLogModel extends ShopSubscriptionLogEntity {
  const ShopSubscriptionLogModel({
    required super.logId,
    required super.action,
    required super.planId,
    required super.planName,
    required super.shopId,
    required super.timestamp,
    super.price,
    super.startDate,
    super.endDate,
    super.status,
  });

  factory ShopSubscriptionLogModel.fromJson(Map<String, dynamic> json, String id) {
    return ShopSubscriptionLogModel(
      logId: id,
      action: json['action'] ?? '',
      planId: json['planId'] ?? '',
      planName: json['planName'] ?? '',
      shopId: json['shopId'] ?? '',
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp'] ?? 0),
      price: (json['price'] as num?)?.toDouble(),
      startDate: json['startDate'] != null ? DateTime.fromMillisecondsSinceEpoch(json['startDate']) : null,
      endDate: json['endDate'] != null ? DateTime.fromMillisecondsSinceEpoch(json['endDate']) : null,
      status: json['status'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'action': action,
      'planId': planId,
      'planName': planName,
      'shopId': shopId,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'price': price,
      'startDate': startDate?.millisecondsSinceEpoch,
      'endDate': endDate?.millisecondsSinceEpoch,
      'status': status,
    };
  }
}
