import 'package:equatable/equatable.dart';

class SubscriptionLogEntity extends Equatable {
  final String logId;
  final String shopId;
  final String customerId;
  final String action;
  final String description;
  final DateTime createdAt;
  final String createdById;
  final DateTime? startDate;
  final DateTime? endDate;
  final double? price;
  final String? productName;
  final String? productId;
  final String? status;

  const SubscriptionLogEntity({
    required this.logId,
    required this.shopId,
    required this.customerId,
    required this.action,
    required this.description,
    required this.createdAt,
    required this.createdById,
    this.startDate,
    this.endDate,
    this.price,
    this.productName,
    this.productId,
    this.status,
  });

  @override
  List<Object?> get props => [
    logId,
    shopId,
    customerId,
    action,
    description,
    createdAt,
    createdById,
    startDate,
    endDate,
    price,
    productName,
    productId,
    status,
  ];
}
