import '../../domain/entities/product_entity.dart';

class ProductModel extends ProductEntity {
  const ProductModel({
    required super.productId,
    required super.shopId,
    required super.name,
    required super.price,
    required super.validityValue,
    required super.validityUnit,
    required super.validityDays,
    required super.createdAt,
    required super.updatedAt,
    required super.updatedById,
    required super.ownerId,
    super.status = 'active',
    super.priceType = 'fixed',
    super.validityType = 'fixed',
  });

  factory ProductModel.fromJson(Map<dynamic, dynamic> json, String id) {
    return ProductModel(
      productId: id,
      shopId: json['shopId'] ?? '',
      name: json['name'] ?? '',
      price: (json['price'] ?? 0.0).toDouble(),
      validityValue: json['validityValue'] ?? json['validityDays'] ?? 30,
      validityUnit: json['validityUnit'] ?? 'days',
      validityDays: json['validityDays'] ?? 30,
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
      updatedById: json['updatedById'] ?? '',
      ownerId: json['ownerId'] ?? '',
      status: json['status'] ?? 'active',
      priceType: json['priceType'] ?? 'fixed',
      validityType: json['validityType'] ?? 'fixed',
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
      'name': name,
      'price': price,
      'validityValue': validityValue,
      'validityUnit': validityUnit,
      'validityDays': validityDays,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'updatedById': updatedById,
      'ownerId': ownerId,
      'status': status,
      'priceType': priceType,
      'validityType': validityType,
    };
  }
}
