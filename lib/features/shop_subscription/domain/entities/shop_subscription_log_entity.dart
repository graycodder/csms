import 'package:equatable/equatable.dart';

class ShopSubscriptionLogEntity extends Equatable {
  final String logId;
  final String action;
  final String planId;
  final String planName;
  final String shopId;
  final DateTime timestamp;
  final double? price;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? status;

  const ShopSubscriptionLogEntity({
    required this.logId,
    required this.action,
    required this.planId,
    required this.planName,
    required this.shopId,
    required this.timestamp,
    this.price,
    this.startDate,
    this.endDate,
    this.status,
  });

  @override
  List<Object?> get props => [
        logId,
        action,
        planId,
        planName,
        shopId,
        timestamp,
        price,
        startDate,
        endDate,
        status,
      ];
}
