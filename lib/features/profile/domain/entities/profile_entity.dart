import 'package:equatable/equatable.dart';

class ProfileEntity extends Equatable {
  final String uid;
  final String fullName;
  final String email;
  final String phone;
  final String role;
  final String? profileImageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ProfileEntity({
    required this.uid,
    required this.fullName,
    required this.email,
    this.phone = '',
    required this.role,
    this.profileImageUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
        uid,
        fullName,
        email,
        phone,
        role,
        profileImageUrl,
        createdAt,
        updatedAt,
      ];

  ProfileEntity copyWith({
    String? fullName,
    String? phone,
    String? profileImageUrl,
    DateTime? updatedAt,
  }) {
    return ProfileEntity(
      uid: uid,
      fullName: fullName ?? this.fullName,
      email: email,
      phone: phone ?? this.phone,
      role: role,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
