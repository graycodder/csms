import '../../domain/entities/staff_entity.dart';
import 'package:firebase_database/firebase_database.dart';

class StaffModel extends StaffEntity {
  const StaffModel({
    required super.staffId,
    required super.shopId,
    required super.ownerId,
    required super.name,
    required super.phone,
    required super.email,
    required super.role,
    required super.status,
    required super.createdAt,
  });

  factory StaffModel.fromJson(Map<dynamic, dynamic> json, String id) {
    return StaffModel(
      staffId: id,
      shopId: json['shopId'] ?? '',
      ownerId: json['ownerId'] ?? '',
      name: json['name'] ?? '',
      phone: json['mobile'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? '',
      status: json['status'] ?? 'active',
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] is int
              ? DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int)
              : (DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()))
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'shopId': shopId,
      'ownerId': ownerId,
      'name': name,
      'mobile': phone,
      'email': email,
      'role': role,
      'status': status,
      'createdAt': ServerValue.timestamp,
      'updatedAt': ServerValue.timestamp,
    };
  }
}
