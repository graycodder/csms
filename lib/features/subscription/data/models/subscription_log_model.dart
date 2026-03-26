import '../../domain/entities/subscription_log_entity.dart';

class SubscriptionLogModel extends SubscriptionLogEntity {
  const SubscriptionLogModel({
    required super.logId,
    required super.shopId,
    required super.customerId,
    required super.action,
    required super.description,
    required super.createdAt,
    required super.createdById,
    super.startDate,
    super.endDate,
    super.price,
    super.productName,
    super.productId,
    super.status,
  });

  factory SubscriptionLogModel.fromJson(Map<dynamic, dynamic> json, String id) {
    return SubscriptionLogModel(
      logId: id,
      shopId: json['shopId'] ?? '',
      customerId: json['customerId'] ?? '',
      action: json['action'] ?? '',
      description: json['description'] ?? '',
      createdAt: _parseDate(json['createdAt']),
      createdById: json['createdById'] ?? '',
      startDate: json['startDate'] != null ? _parseDate(json['startDate']) : null,
      endDate: json['endDate'] != null ? _parseDate(json['endDate']) : null,
      price: (json['price'] as num? ?? 0.0).toDouble(),
      productName: json['productName'] as String?,
      productId: json['productId'] as String?,
      status: json['status'] as String?,
    );
  }

  static DateTime _parseDate(dynamic date) {
    if (date is int) return DateTime.fromMillisecondsSinceEpoch(date);
    if (date is String) return DateTime.tryParse(date) ?? DateTime.now();
    return DateTime.now();
  }

  Map<String, dynamic> toJson() {
    return {
      'shopId': shopId,
      'customerId': customerId,
      'action': action,
      'description': description,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'createdById': createdById,
      'productId': productId,
      if (startDate != null) 'startDate': startDate!.millisecondsSinceEpoch,
      if (endDate != null) 'endDate': endDate!.millisecondsSinceEpoch,
      if (price != null) 'price': price,
      if (productName != null) 'productName': productName,
      if (status != null) 'status': status,
    };
  }
}
