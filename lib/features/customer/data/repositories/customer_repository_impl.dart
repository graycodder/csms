import 'package:firebase_database/firebase_database.dart';
import 'package:dartz/dartz.dart';
import 'package:csms/core/error/failures.dart';
import 'package:csms/features/customer/domain/entities/customer_entity.dart';
import 'package:csms/features/customer/domain/repositories/customer_repository.dart';
import 'package:csms/features/customer/data/models/customer_model.dart';

class CustomerRepositoryImpl implements CustomerRepository {
  final FirebaseDatabase _database;

  CustomerRepositoryImpl({FirebaseDatabase? database})
    : _database = database ?? FirebaseDatabase.instance;


  @override
  Stream<Either<Failure, List<CustomerEntity>>> getCustomers({
    required String shopId,
    required String ownerId,
    int limit = 5000,
    dynamic lastDoc,
  }) {
    Query query = _database
        .ref()
        .child('customers')
        .orderByChild('owner_createdAt');

    if (lastDoc != null && lastDoc.toString().isNotEmpty) {
      query = query.endAt(lastDoc).limitToLast(limit + 1);
    } else {
      query = query.startAt(ownerId).endAt('${ownerId}_\uf8ff').limitToLast(limit);
    }

    return query.onValue.map((event) {
      try {
        final customers = <CustomerEntity>[];
        if (event.snapshot.value != null) {
          final data = event.snapshot.value as Map<dynamic, dynamic>;
          final List<MapEntry<dynamic, dynamic>> entries = data.entries.toList();
          
          entries.sort((a, b) {
            final valA = (a.value as Map)['owner_createdAt']?.toString() ?? '';
            final valB = (b.value as Map)['owner_createdAt']?.toString() ?? '';
            return valB.compareTo(valA);
          });

          for (final entry in entries) {
            final customerData = Map<String, dynamic>.from(entry.value as Map);
            if (customerData['shopId'] == shopId) {
              final model = CustomerModel.fromJson(customerData, entry.key.toString());
              if (lastDoc != null && model.owner_createdAt == lastDoc) continue;
              customers.add(model);
            }
          }
        }
        return Right(customers);
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    });
  }

  @override
  Future<Either<Failure, String>> addCustomer(CustomerEntity customer) async {
    try {
      final duplicateCheck = await _isMobileNumberDuplicate(
        shopId: customer.shopId,
        mobileNumber: customer.mobileNumber,
        ownerId: customer.ownerId,
      );
      if (duplicateCheck) {
        return const Left(DuplicateFailure('This number is already used by another customer. Please try with another number.'));
      }

      final docRef = _database.ref().child('customers').push();
      final model = CustomerModel(
        customerId: docRef.key!,
        shopId: customer.shopId,
        name: customer.name,
        mobileNumber: customer.mobileNumber,
        email: customer.email,
        assignedProductIds: customer.assignedProductIds,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        updatedById: customer.updatedById,
        ownerId: customer.ownerId,
        registrationFeeAmount: customer.registrationFeeAmount,
        registrationFeePaidAmount: customer.registrationFeePaidAmount,
        registrationFeeStatus: customer.registrationFeeStatus,
        registrationFeePaymentMode: customer.registrationFeePaymentMode,
      );

      await docRef.set(model.toJson());
      return Right(docRef.key!);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateCustomer(
    CustomerEntity customer, {
    String? paymentMode,
  }) async {
    try {
      final duplicateCheck = await _isMobileNumberDuplicate(
        shopId: customer.shopId,
        mobileNumber: customer.mobileNumber,
        ownerId: customer.ownerId,
        excludeCustomerId: customer.customerId,
      );
      if (duplicateCheck) {
        return const Left(DuplicateFailure('This number is already used by another customer. Please try with another number.'));
      }

      final ref = _database.ref().child('customers').child(customer.customerId);
      final snapshot = await ref.get();
      double oldRegPaid = 0.0;
      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        oldRegPaid = (data['registrationFeePaidAmount'] ?? 0.0).toDouble();
      }

      final double newRegPaid = customer.registrationFeePaidAmount;
      final double diff = newRegPaid - oldRegPaid;

      if (diff != 0) {
        final logRef = _database.ref().child('subscription_logs').child(customer.shopId).push();
        await logRef.set({
          'shopId': customer.shopId,
          'customerId': customer.customerId,
          'action': 'payment',
          'description': diff > 0 
            ? 'Registration fee balance collected via edit' 
            : 'Registration fee corrected (Reduced)',
          'createdAt': ServerValue.timestamp,
          'createdById': customer.updatedById,
          'registrationFeePaid': diff,
          'paidAmount': 0.0,
          'status': 'active',
          'paymentMode': customer.registrationFeePaymentMode,
        });
      }

      await ref.update({
            'name': customer.name,
            'mobileNumber': customer.mobileNumber,
            'email': customer.email,
            'status': customer.status,
            'registrationFeeAmount': customer.registrationFeeAmount,
            'registrationFeePaidAmount': customer.registrationFeePaidAmount,
            'registrationFeeStatus': customer.registrationFeeStatus,
            'registrationFeePaymentMode': customer.registrationFeePaymentMode,
            'updatedAt': ServerValue.timestamp,
            'updatedById': customer.updatedById,
          });
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  Future<bool> _isMobileNumberDuplicate({
    required String shopId,
    required String mobileNumber,
    required String ownerId,
    String? excludeCustomerId,
  }) async {
    final snapshot = await _database
        .ref()
        .child('customers')
        .orderByChild('ownerId')
        .equalTo(ownerId)
        .get();

    if (snapshot.value != null) {
      final data = snapshot.value as Map<dynamic, dynamic>;
      for (final entry in data.entries) {
        final customerData = Map<String, dynamic>.from(entry.value as Map);
        if (customerData['shopId'] == shopId && customerData['mobileNumber'] == mobileNumber) {
          if (excludeCustomerId == null || entry.key.toString() != excludeCustomerId) {
            return true;
          }
        }
      }
    }
    return false;
  }

  @override
  Future<Either<Failure, void>> deleteCustomer(String customerId) async {
    try {
      await _database.ref().child('customers/$customerId').remove();
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
