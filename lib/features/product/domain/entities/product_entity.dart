import 'package:equatable/equatable.dart';

class ProductEntity extends Equatable {
  final String productId;
  final String shopId;
  final String name;
  final double price;
  final int validityValue;
  final String validityUnit; // 'days' or 'months'
  final int validityDays; // Kept for backward compatibility
  final DateTime createdAt;
  final DateTime updatedAt;
  final String updatedById;
  final String ownerId;
  final String status; // 'active' or 'inactive'
  final String priceType; // 'fixed' or 'flexible'
  final String validityType; // 'fixed' or 'flexible'

  const ProductEntity({
    required this.productId,
    required this.shopId,
    required this.name,
    required this.price,
    required this.validityValue,
    required this.validityUnit,
    required this.validityDays,
    required this.createdAt,
    required this.updatedAt,
    required this.updatedById,
    required this.ownerId,
    this.status = 'active',
    this.priceType = 'fixed',
    this.validityType = 'fixed',
  });

  ProductEntity copyWith({
    String? name,
    double? price,
    int? validityValue,
    String? validityUnit,
    int? validityDays,
    DateTime? updatedAt,
    String? updatedById,
    String? status,
    String? priceType,
    String? validityType,
  }) {
    return ProductEntity(
      productId: productId,
      shopId: shopId,
      name: name ?? this.name,
      price: price ?? this.price,
      validityValue: validityValue ?? this.validityValue,
      validityUnit: validityUnit ?? this.validityUnit,
      validityDays: validityDays ?? this.validityDays,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedById: updatedById ?? this.updatedById,
      ownerId: ownerId,
      status: status ?? this.status,
      priceType: priceType ?? this.priceType,
      validityType: validityType ?? this.validityType,
    );
  }

  @override
  List<Object?> get props => [
    productId,
    shopId,
    name,
    price,
    validityValue,
    validityUnit,
    validityDays,
    createdAt,
    updatedAt,
    updatedById,
    ownerId,
    status,
    priceType,
    validityType,
  ];
}
