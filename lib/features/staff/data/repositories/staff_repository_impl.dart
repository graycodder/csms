import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dartz/dartz.dart';
import 'package:csms/core/error/failures.dart';
import 'package:csms/features/staff/domain/entities/staff_entity.dart';
import 'package:csms/features/staff/domain/repositories/staff_repository.dart';
import '../models/staff_model.dart';

class StaffRepositoryImpl implements StaffRepository {
  final FirebaseDatabase _database;

  StaffRepositoryImpl({FirebaseDatabase? database})
      : _database = database ?? FirebaseDatabase.instance;


  DatabaseReference get _usersRef => _database.ref().child('users');

  @override
  Stream<Either<Failure, List<StaffEntity>>> getStaff(String shopId, String ownerId) {
    return _usersRef.orderByChild('ownerId').equalTo(ownerId).onValue.map((event) {
      try {
        final staff = <StaffEntity>[];
        if (event.snapshot.value != null) {
          final data = event.snapshot.value as Map<dynamic, dynamic>;
          data.forEach((key, value) {
            final map = Map<dynamic, dynamic>.from(value as Map);
            if (map['role'] != 'owner' && map['shopId'] == shopId) {
              staff.add(StaffModel.fromJson(map, key.toString()));
            }
          });
          staff.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        }
        return Right(staff);
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    });
  }

  @override
  Future<Either<Failure, void>> addStaff(String shopId, String ownerId, StaffEntity staff, {String? password}) async {
    try {
      // --- Pre-check Email Uniqueness ---
      final emailCheckSnapshot = await _usersRef.orderByChild('ownerId').equalTo(ownerId).get();
      if (emailCheckSnapshot.value != null) {
        final data = emailCheckSnapshot.value as Map<dynamic, dynamic>;
        bool emailExists = false;
        data.forEach((key, value) {
          final map = Map<dynamic, dynamic>.from(value as Map);
          if (map['email'] == staff.email) emailExists = true;
        });
        if (emailExists) {
          return const Left(DuplicateFailure("This email is already used by another account. Please use a different email."));
        }
      }

      // --- Pre-check Phone Uniqueness ---
      final phoneCheck = await _isPhoneDuplicate(shopId: shopId, phone: staff.phone, ownerId: ownerId);
      if (phoneCheck) {
        return const Left(DuplicateFailure("This number is already used by another staff member. Please try with another number."));
      }

      String? createdUserId;

      // --- Background Auth Creation ---
      if (password != null && password.isNotEmpty && staff.email.isNotEmpty) {
        try {
          FirebaseApp tempApp = await Firebase.initializeApp(
            name: 'TempStaffAuth_${DateTime.now().millisecondsSinceEpoch}',
            options: Firebase.app().options,
          );
          
          FirebaseAuth tempAuth = FirebaseAuth.instanceFor(app: tempApp);
          
          final cred = await tempAuth.createUserWithEmailAndPassword(
            email: staff.email,
            password: password,
          );
          
          createdUserId = cred.user?.uid;
          
          // Sign out and delete temp app INSTANTLY to avoid session conflicts natively
          await tempAuth.signOut();
          await tempApp.delete();
        } catch (authError) {
          return Left(ServerFailure("Failed to create authentication account: $authError"));
        }
      }

      // CRITICAL: Always use createdUserId as the key if it exists natively
      // This allows direct lookup by UID in getUserFullProfile without restricted queries.
      final staffIdToUse = createdUserId ?? _usersRef.push().key!;
      
      final model = StaffModel(
        staffId: staffIdToUse,
        shopId: shopId,
        ownerId: ownerId,
        name: staff.name,
        phone: staff.phone,
        email: staff.email,
        role: staff.role,
        status: staff.status,
        createdAt: staff.createdAt,
      );

      final data = model.toJson();
      // Explicitly set these to ensure they are never missing natively
      data['shopId'] = shopId;
      data['ownerId'] = ownerId;
      
      if (createdUserId != null) {
        data['userId'] = createdUserId;
      }
      
      await _usersRef.child(staffIdToUse).set(data);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateStaff(String shopId, String ownerId, StaffEntity staff) async {
    try {
      // --- Pre-check Email Uniqueness if changed ---
      final emailCheckSnapshot = await _usersRef.orderByChild('ownerId').equalTo(ownerId).get();
      if (emailCheckSnapshot.value != null) {
        final data = emailCheckSnapshot.value as Map<dynamic, dynamic>;
        bool usedByOther = false;
        data.forEach((key, value) {
          final map = Map<dynamic, dynamic>.from(value as Map);
          if (map['email'] == staff.email && key.toString() != staff.staffId) {
            usedByOther = true;
          }
        });
        if (usedByOther) {
          return const Left(DuplicateFailure("This email is already used by another account."));
        }
      }

      // --- Pre-check Phone Uniqueness if changed ---
      final phoneCheck = await _isPhoneDuplicate(
        shopId: shopId,
        phone: staff.phone,
        ownerId: ownerId,
        excludeStaffId: staff.staffId,
      );
      if (phoneCheck) {
        return const Left(DuplicateFailure("This number is already used by another member. Please try with another number."));
      }

      final model = StaffModel(
        staffId: staff.staffId,
        shopId: shopId,
        ownerId: ownerId,
        name: staff.name,
        phone: staff.phone,
        email: staff.email,
        role: staff.role,
        status: staff.status,
        createdAt: staff.createdAt,
      );
      final data = model.toJson();
      // Explicitly set these to ensure they are never missing natively
      data['shopId'] = shopId;
      data['ownerId'] = ownerId;
      
      // Ensure we merge update instead of flat replace so we don't accidentally wipe out 'userId' if it's there
      await _usersRef.child(staff.staffId).update(data);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  Future<bool> _isPhoneDuplicate({
    required String shopId,
    required String phone,
    required String ownerId,
    String? excludeStaffId,
  }) async {
    final snapshot = await _usersRef.orderByChild('ownerId').equalTo(ownerId).get();
    if (snapshot.value != null) {
      final data = snapshot.value as Map<dynamic, dynamic>;
      for (final entry in data.entries) {
        final map = Map<dynamic, dynamic>.from(entry.value as Map);
        if (map['shopId'] == shopId && map['phone'] == phone) {
          if (excludeStaffId == null || entry.key.toString() != excludeStaffId) {
            return true;
          }
        }
      }
    }
    return false;
  }

  @override
  Future<Either<Failure, void>> deleteStaff(String shopId, String ownerId, String staffId) async {
    try {
      await _usersRef.child(staffId).remove();
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
