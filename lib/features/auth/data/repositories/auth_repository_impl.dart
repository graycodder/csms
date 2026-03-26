import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:dartz/dartz.dart';
import 'package:csms/core/error/failures.dart';
import 'package:csms/features/auth/domain/repositories/auth_repository.dart';
import 'package:csms/features/auth/data/datasources/auth_local_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuth _firebaseAuth;
  final AuthLocalDataSource localDataSource;

  AuthRepositoryImpl({FirebaseAuth? firebaseAuth, required this.localDataSource})
    : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  @override
  Stream<String?> get onAuthStateChanged =>
      _firebaseAuth.authStateChanges().map((user) => user?.uid);

  @override
  Future<Either<Failure, String>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = userCredential.user;
      if (user != null) {
        // --- NEW: Profile & Role Verification ---
        final profile = await getUserFullProfile(user.uid);
        if (profile == null) {
          await _firebaseAuth.signOut();
          return const Left(ServerFailure("Access restricted to registered users only."));
        }
        
        final role = profile['role']?.toString().toLowerCase() ?? '';
        final status = profile['status']?.toString().toLowerCase() ?? 'active';
        
        if (status == 'inactive') {
           await _firebaseAuth.signOut();
           return const Left(ServerFailure("Your account has been deactivated. Please contact your manager."));
        }

        final ownerId = role == 'owner' ? user.uid : (profile['ownerId'] ?? '');
        
        if (ownerId == '') {
           await _firebaseAuth.signOut();
           return const Left(ServerFailure("Profile incomplete (No owner assigned for this staff account)."));
        }
        // --- END: Profile Verification ---

        await localDataSource.saveUserSession(user.uid);
        return Right(user.uid);
      } else {
        return const Left(ServerFailure("User not found after sign in."));
      }
    } on FirebaseAuthException catch (e) {
      return Left(ServerFailure(_mapFirebaseError(e)));
    } catch (e) {
      return const Left(ServerFailure("An unexpected error occurred."));
    }
  }

  @override
  Future<Either<Failure, void>> resetPassword({
    required String email,
  }) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
      return const Right(null);
    } on FirebaseAuthException catch (e) {
      return Left(ServerFailure(_mapFirebaseError(e)));
    } catch (e) {
      return const Left(ServerFailure("An unexpected error occurred."));
    }
  }

  @override
  Future<Either<Failure, String>> signUp({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = userCredential.user;
      if (user != null) {
        await localDataSource.saveUserSession(user.uid);
        return Right(user.uid);
      } else {
        return const Left(ServerFailure("User not found after sign up."));
      }
    } on FirebaseAuthException catch (e) {
      return Left(ServerFailure(_mapFirebaseError(e)));
    } catch (e) {
      return const Left(ServerFailure("An unexpected error occurred."));
    }
  }

  @override
  Future<Either<Failure, void>> verifyPhoneNumber({
    required String phoneNumber,
    required Function(String verificationId) onCodeSent,
    required Function(String error) onVerificationFailed,
  }) async {
    try {
      await _firebaseAuth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          await _firebaseAuth.signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          onVerificationFailed(_mapFirebaseError(e));
        },
        codeSent: (String verificationId, int? resendToken) {
          onCodeSent(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
      );
      return const Right(null);
    } on FirebaseAuthException catch (e) {
      return Left(ServerFailure(_mapFirebaseError(e)));
    } catch (e) {
      return const Left(ServerFailure("An unexpected error occurred."));
    }
  }

  @override
  Future<void> signOut() async {
    await localDataSource.clearUserSession();
    await _firebaseAuth.signOut();
  }

  @override
  Future<void> saveUser(String userId) async {
    await localDataSource.saveUserSession(userId);
  }

  @override
  Future<String?> getSavedUser() async {
    return await localDataSource.getUserSession();
  }

  @override
  Future<void> clearUser() async {
    await localDataSource.clearUserSession();
  }

  @override
  Future<void> saveUserFcmToken(String userId, String token) async {
    try {
      await FirebaseDatabase.instance
          .ref()
          .child('users')
          .child(userId)
          .child('fcmTokens')
          .child(token)
          .set(true);
    } catch (e) {
      // Background fail safe
    }
  }

  @override
  Future<Map<String, dynamic>?> getUserFullProfile(String userId) async {
    try {
      // 1. Try direct lookup by UID (fastest and secure) natively
      final snapshot = await FirebaseDatabase.instance
          .ref()
          .child('users')
          .child(userId)
          .get();
          
      if (snapshot.value != null) {
        return Map<String, dynamic>.from(snapshot.value as Map);
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  String _mapFirebaseError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'The email address is invalid.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'user-not-found':
        return 'No user found for that email.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Invalid email or password.';
      case 'email-already-in-use':
        return 'The email address is already in use by another account.';
      case 'operation-not-allowed':
        return 'This login method is not enabled.';
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      case 'too-many-requests':
        return 'Too many login attempts. Please try again later.';
      default:
        return e.message ?? 'An unexpected authentication error occurred.';
    }
  }
}
