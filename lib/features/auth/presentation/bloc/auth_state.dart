import 'package:equatable/equatable.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthUnauthenticated extends AuthState {}

class AuthLoading extends AuthState {}

class AuthOtpSent extends AuthState {
  final String verificationId;
  const AuthOtpSent(this.verificationId);

  @override
  List<Object?> get props => [verificationId];
}

class AuthAuthenticated extends AuthState {
  final String userId;
  final String ownerId;
  final String name;
  final String role;
  final String shopId;

  const AuthAuthenticated(
    this.userId, {
    this.ownerId = '',
    this.name = 'User',
    this.role = 'staff',
    this.shopId = '',
  });

  @override
  List<Object?> get props => [userId, ownerId, name, role, shopId];
}

class AuthNeedsOnboarding extends AuthState {
  final String userId;
  const AuthNeedsOnboarding(this.userId);

  @override
  List<Object?> get props => [userId];
}

class AuthPasswordResetSent extends AuthState {}

class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}
