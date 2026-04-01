import '../../domain/entities/customer_entity.dart';

class CustomerModel extends CustomerEntity {
  const CustomerModel({
    required super.customerId,
    required super.shopId,
    required super.name,
    required super.mobileNumber,
    required super.email,
    required super.assignedProductIds,
    required super.createdAt,
    required super.updatedAt,
    required super.updatedById,
    required super.ownerId,
    super.status = 'active',
    super.owner_createdAt = '',
    super.registrationFeeAmount = 0.0,
    super.registrationFeeStatus = 'unpaid',
  });

  factory CustomerModel.fromJson(Map<dynamic, dynamic> json, String id) {
    Map<String, bool> productsMap = {};
    if (json['assignedProductIds'] != null) {
      final mapData = json['assignedProductIds'] as Map<dynamic, dynamic>;
      mapData.forEach((key, value) {
        // Support both boolean and status string ("active"/"inactive")
        productsMap[key.toString()] = (value == true || value == 'active');
      });
    }

    return CustomerModel(
      customerId: id,
      shopId: json['shopId'] ?? '',
      name: json['name'] ?? '',
      mobileNumber: json['mobileNumber'] ?? '',
      email: json['email'] ?? '',
      assignedProductIds: productsMap,
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
      updatedById: json['updatedById'] ?? '',
      ownerId: json['ownerId'] ?? '',
      status: json['status'] ?? 'active',
      owner_createdAt: json['owner_createdAt'] ?? '',
      registrationFeeAmount: (json['registrationFeeAmount'] ?? 0.0).toDouble(),
      registrationFeeStatus: json['registrationFeeStatus'] ?? 'unpaid',
    );
  }

  static DateTime _parseDate(dynamic date) {
    if (date is int) return DateTime.fromMillisecondsSinceEpoch(date, isUtc: true);
    if (date is String) {
      final parsedInt = int.tryParse(date);
      if (parsedInt != null) return DateTime.fromMillisecondsSinceEpoch(parsedInt, isUtc: true);
      return DateTime.tryParse(date)?.toUtc() ?? DateTime.fromMillisecondsSinceEpoch(0).toUtc();
    }
    return DateTime.fromMillisecondsSinceEpoch(0).toUtc();
  }

  Map<String, dynamic> toJson() {
    return {
      'shopId': shopId,
      'name': name,
      'mobileNumber': mobileNumber,
      'email': email,
      'assignedProductIds': assignedProductIds,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'updatedById': updatedById,
      'ownerId': ownerId,
      'status': status,
      'owner_createdAt': owner_createdAt.isNotEmpty ? owner_createdAt : '${ownerId}_${createdAt.millisecondsSinceEpoch}',
      'registrationFeeAmount': registrationFeeAmount,
      'registrationFeeStatus': registrationFeeStatus,
    };
  }
}
