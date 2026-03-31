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
    required super.price,
    required super.registrationFeeAmount,
    required super.paidAmount,
    super.balanceAmount,
    super.paymentMode,
    super.productName,
    super.productId,
    super.status,
  });

  factory SubscriptionLogModel.fromJson(Map<dynamic, dynamic> json, String id) {
    // Handle both naming conventions for backward compatibility
    final double? paidAmt = json['paidAmount'] != null 
        ? (json['paidAmount'] is int ? (json['paidAmount'] as int).toDouble() : json['paidAmount'])
        : (json['amountPaid'] != null 
            ? (json['amountPaid'] is int ? (json['amountPaid'] as int).toDouble() : json['amountPaid'])
            : null);

    return SubscriptionLogModel(
      logId: id,
      shopId: json['shopId'] ?? '',
      customerId: json['customerId'] ?? '',
      action: json['action'] ?? '',
      description: json['description'] ?? '',
      createdAt: _parseDate(json['createdAt']),
      createdById: json['createdById'] ?? '',
      startDate: json['startDate'] != null ? _parseDate(json['startDate']) : null,
      endDate: json['endDate'] != null ? DateTime.fromMillisecondsSinceEpoch(json['endDate']) : null,
      price: json['price'] != null ? (json['price'] is int ? (json['price'] as int).toDouble() : json['price']) : null,
      registrationFeeAmount: json['registrationFeeAmount'] != null ? (json['registrationFeeAmount'] is int ? (json['registrationFeeAmount'] as int).toDouble() : json['registrationFeeAmount']) : null,
      paidAmount: paidAmt,
      balanceAmount: json['balanceAmount'] != null ? (json['balanceAmount'] is int ? (json['balanceAmount'] as int).toDouble() : json['balanceAmount']) : null,
      paymentMode: json['paymentMode'] as String?,
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
      if (registrationFeeAmount != null) 'registrationFeeAmount': registrationFeeAmount,
      if (paidAmount != null) 'paidAmount': paidAmount,
      if (balanceAmount != null) 'balanceAmount': balanceAmount,
      if (paymentMode != null) 'paymentMode': paymentMode,
      if (productName != null) 'productName': productName,
      if (status != null) 'status': status,
    };
  }
}
