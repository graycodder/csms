import '../../domain/entities/subscription_entity.dart';
import 'subscription_log_model.dart';

class SubscriptionModel extends SubscriptionEntity {
  const SubscriptionModel({
    required super.subscriptionId,
    required super.shopId,
    required super.customerId,
    required super.productId,
    required super.startDate,
    required super.endDate,
    required super.status,
    required super.logs,
    required super.createdAt,
    required super.updatedAt,
    required super.price,
    super.registrationFeeAmount = 0.0,
    super.registrationFeePaid = 0.0,
    super.paidAmount = 0.0,
    super.balanceAmount = 0.0,
    super.paymentStatus = 'paid',
    required super.updatedById,
    required super.ownerId,
  });

  factory SubscriptionModel.fromJson(Map<dynamic, dynamic> json, String id) {
    var logsList = <SubscriptionLogModel>[];
    if (json['logs'] != null) {
      final logsMap = json['logs'] as Map<dynamic, dynamic>;
      logsMap.forEach((key, value) {
        logsList.add(SubscriptionLogModel.fromJson(value, key.toString()));
      });
    }

    return SubscriptionModel(
      subscriptionId: id,
      shopId: json['shopId'] ?? '',
      customerId: json['customerId'] ?? '',
      productId: json['productId'] ?? '',
      startDate: _parseDate(json['startDate']),
      endDate: _parseDate(json['endDate']),
      status: json['status'] ?? 'active',
      logs: logsList,
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
      price: (json['price'] as num? ?? 0.0).toDouble(),
      registrationFeeAmount: (json['registrationFeeAmount'] ?? 0.0).toDouble(),
      registrationFeePaid: (json['registrationFeePaid'] ?? 0.0).toDouble(),
      paidAmount: (json['paidAmount'] ?? (json['price'] ?? 0.0)).toDouble(), // Default to price for legacy
      balanceAmount: (json['balanceAmount'] ?? 0.0).toDouble(),
      paymentStatus: json['paymentStatus'] ?? 'paid',
      updatedById: json['updatedById'] ?? '',
      ownerId: json['ownerId'] ?? '',
    );
  }

  static DateTime _parseDate(dynamic date) {
    if (date is int) return DateTime.fromMillisecondsSinceEpoch(date);
    if (date is String) return DateTime.tryParse(date) ?? DateTime.now();
    return DateTime.now();
  }

  Map<String, dynamic> toJson() {
    final logsMap = {
      for (var log in logs)
        (log as SubscriptionLogModel).logId: (log as SubscriptionLogModel)
            .toJson(),
    };
    return {
      'shopId': shopId,
      'customerId': customerId,
      'productId': productId,
      'startDate': startDate.millisecondsSinceEpoch,
      'endDate': endDate.millisecondsSinceEpoch,
      'status': status,
      'logs': logsMap,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'price': price,
      'registrationFeeAmount': registrationFeeAmount,
      'registrationFeePaid': registrationFeePaid,
      'paidAmount': paidAmount,
      'balanceAmount': balanceAmount,
      'paymentStatus': paymentStatus,
      'updatedById': updatedById,
      'ownerId': ownerId,
    };
  }
}
