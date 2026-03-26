import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';

abstract class AuthRepository {
  Future<Either<Failure, void>> verifyPhoneNumber({
    required String phoneNumber,
    required Function(String verificationId) onCodeSent,
    required Function(String error) onVerificationFailed,
  });

  Future<Either<Failure, String>> signIn({
    required String email,
    required String password,
  });

  Future<Either<Failure, void>> resetPassword({
    required String email,
  });

  Future<Either<Failure, String>> signUp({
    required String email,
    required String password,
  });

  Future<void> signOut();

  Future<void> saveUser(String userId);
  Future<String?> getSavedUser();
  Future<void> clearUser();
  Future<Map<String, dynamic>?> getUserFullProfile(String userId);
  Future<void> saveUserFcmToken(String userId, String token);

  Stream<String?> get onAuthStateChanged;
}
