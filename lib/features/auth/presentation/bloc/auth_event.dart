import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class CheckAuthStatus extends AuthEvent {}

class VerifyPhoneRequested extends AuthEvent {
  final String phoneNumber;
  const VerifyPhoneRequested(this.phoneNumber);

  @override
  List<Object?> get props => [phoneNumber];
}

class LoginRequested extends AuthEvent {
  final String email;
  final String password;
  const LoginRequested({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];
}

class SignUpRequested extends AuthEvent {
  final String email;
  final String password;
  const SignUpRequested({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];
}

class SubmitOtpRequested extends AuthEvent {
  final String verificationId;
  final String smsCode;
  const SubmitOtpRequested({
    required this.verificationId,
    required this.smsCode,
  });

  @override
  List<Object?> get props => [verificationId, smsCode];
}

class OnboardingRequested extends AuthEvent {
  final String ownerId;
  final String name;
  final String mobile;
  final String email;
  final String shopName;
  final String shopCategory;
  final String shopAddress;

  final String password;

  const OnboardingRequested({
    required this.ownerId,
    required this.name,
    required this.mobile,
    required this.email,
    required this.shopName,
    required this.shopCategory,
    required this.shopAddress,
    required this.password,
  });

  @override
  List<Object?> get props => [
    ownerId,
    name,
    mobile,
    email,
    shopName,
    shopCategory,
    shopAddress,
    password,
  ];
}

class ResetPasswordRequested extends AuthEvent {
  final String email;
  const ResetPasswordRequested(this.email);

  @override
  List<Object?> get props => [email];
}

class SignOutRequested extends AuthEvent {}
