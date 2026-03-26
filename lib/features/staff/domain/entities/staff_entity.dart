import 'package:equatable/equatable.dart';

class StaffEntity extends Equatable {
  final String staffId;
  final String shopId;
  final String ownerId;
  final String name;
  final String phone;
  final String email;
  final String role;
  final String status;
  final DateTime createdAt;

  const StaffEntity({
    required this.staffId,
    required this.shopId,
    required this.ownerId,
    required this.name,
    required this.phone,
    required this.email,
    required this.role,
    this.status = 'active',
    required this.createdAt,
  });

  @override
  List<Object?> get props => [staffId, shopId, ownerId, name, phone, email, role, status, createdAt];
}
