import 'package:firebase_database/firebase_database.dart';
import 'package:dartz/dartz.dart';
import 'package:csms/core/error/failures.dart';
import 'package:csms/features/auth/domain/repositories/onboarding_repository.dart';

class OnboardingRepositoryImpl implements OnboardingRepository {
  final FirebaseDatabase _database;

  OnboardingRepositoryImpl({FirebaseDatabase? database})
    : _database = database ?? FirebaseDatabase.instance;

  @override
  Future<Either<Failure, void>> registerOwnerAndShop({
    required String ownerId,
    required String name,
    required String mobile,
    required String email,
    required String shopName,
    required String shopCategory,
    required String shopAddress,
    String? password, // Added to match interface change in previous step
  }) async {
    try {
      final Map<String, dynamic> updates = {};
      
      // Check if user already exists to avoid overwriting createdAt
      final userSnapshot = await _database.ref().child('users').child(ownerId).get();
      final bool userExists = userSnapshot.exists;

      if (!userExists) {
        // Only create user profile if it doesn't exist
        updates['users/$ownerId'] = {
          'userId': ownerId,
          'name': name,
          'mobile': mobile,
          'email': email,
          'role': 'owner',
          'ownerId': ownerId,
          'createdAt': ServerValue.timestamp,
          'updatedAt': ServerValue.timestamp,
        };
      } else {
        // If user exists, just update their updatedAt and potentially sync name/mobile
        updates['users/$ownerId/updatedAt'] = ServerValue.timestamp;
        // Optionally sync name/mobile if you want the latest from onboarding
        updates['users/$ownerId/name'] = name;
        updates['users/$ownerId/mobile'] = mobile;
      }

      // Shop data (always generate a unique key for a new shop)
      final shopRef = _database.ref().child('shops').push();
      final shopId = shopRef.key!;

      updates['shops/$shopId'] = {
        'shopId': shopId,
        'ownerId': ownerId,
        'shopName': shopName,
        'category': shopCategory,
        'shopAddress': shopAddress,
        'phone': mobile,
        'settings': {
          'notificationDaysBefore': 2,
          'showProductFilters': false,
          'autoArchiveExpired': true,
        },
        'createdAt': ServerValue.timestamp,
        'updatedAt': ServerValue.timestamp,
        'updatedById': ownerId,
      };

      await _database.ref().update(updates);

      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
