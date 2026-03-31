import 'package:equatable/equatable.dart';

class CustomerEntity extends Equatable {
  final String customerId;
  final String shopId;
  final String name;
  final String mobileNumber;
  final String email;
  final Map<String, bool> assignedProductIds;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String updatedById;
  final String ownerId;

  final String status; // 'active' or 'inactive'
  final String owner_createdAt; // composite key
  final double registrationFeeAmount;
  final String registrationFeeStatus;

  const CustomerEntity({
    required this.customerId,
    required this.shopId,
    required this.name,
    required this.mobileNumber,
    required this.email,
    required this.assignedProductIds,
    required this.createdAt,
    required this.updatedAt,
    required this.updatedById,
    required this.ownerId,
    this.status = 'active',
    this.owner_createdAt = '',
    this.registrationFeeAmount = 0.0,
    this.registrationFeeStatus = 'unpaid',
  });

  CustomerEntity copyWith({
    String? customerId,
    String? shopId,
    String? name,
    String? mobileNumber,
    String? email,
    Map<String, bool>? assignedProductIds,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? updatedById,
    String? ownerId,
    String? status,
    String? owner_createdAt,
    double? registrationFeeAmount,
    String? registrationFeeStatus,
  }) {
    return CustomerEntity(
      customerId: customerId ?? this.customerId,
      shopId: shopId ?? this.shopId,
      name: name ?? this.name,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      email: email ?? this.email,
      assignedProductIds: assignedProductIds ?? this.assignedProductIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedById: updatedById ?? this.updatedById,
      ownerId: ownerId ?? this.ownerId,
      status: status ?? this.status,
      owner_createdAt: owner_createdAt ?? this.owner_createdAt,
      registrationFeeAmount: registrationFeeAmount ?? this.registrationFeeAmount,
      registrationFeeStatus: registrationFeeStatus ?? this.registrationFeeStatus,
    );
  }

  @override
  List<Object?> get props => [
    customerId,
    shopId,
    name,
    mobileNumber,
    email,
    assignedProductIds,
    createdAt,
    updatedAt,
    updatedById,
    ownerId,
    status,
    owner_createdAt,
    registrationFeeAmount,
    registrationFeeStatus,
  ];
}
