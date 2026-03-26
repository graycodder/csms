import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String uid;
  final String fullName;
  final String email;
  final String role;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String updatedById;
  final String ownerId;

  const UserEntity({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.role,
    required this.createdAt,
    required this.updatedAt,
    required this.updatedById,
    required this.ownerId,
  });

  @override
  List<Object?> get props => [
    uid,
    fullName,
    email,
    role,
    createdAt,
    updatedAt,
    updatedById,
    ownerId,
  ];
}
```
