import 'package:firebase_database/firebase_database.dart';
import 'package:dartz/dartz.dart';
import 'package:csms/core/error/failures.dart';
import '../../domain/entities/subscription_entity.dart';
import '../../domain/entities/subscription_log_entity.dart';
import '../../domain/repositories/subscription_repository.dart';
import '../models/subscription_model.dart';
import '../models/subscription_log_model.dart';

class SubscriptionRepositoryImpl implements SubscriptionRepository {
  final FirebaseDatabase _database;

  SubscriptionRepositoryImpl({FirebaseDatabase? database})
    : _database = database ?? FirebaseDatabase.instance;


  @override
  Future<Either<Failure, void>> createSubscription({
    required String shopId,
    required String customerId,
    required String productId,
    required String ownerId,
    required String updatedById,
    required int validityValue,
    required String validityUnit,
    required double price,
    double registrationFeeAmount = 0.0,
    double? paidAmount,
    String? paymentMode,
    required String productName,
  }) async {
    try {
      final startDate = DateTime.now();
      final endDate = _calculateEndDate(startDate, validityValue, validityUnit);

      final subRef = _database.ref().child('subscriptions').push();
      final subId = subRef.key!;

      final Map<String, dynamic> updates = {};

      final logId = _database.ref().push().key ?? 'initial';
      
        final totalAmount = price + registrationFeeAmount;
        final actualPaid = paidAmount ?? totalAmount;
        final balance = totalAmount - actualPaid;
        final paymentStatus = balance <= 0 ? 'paid' : (actualPaid <= 0 ? 'unpaid' : 'partial');

      final subData = {
        'subscriptionId': subId,
        'shopId': shopId,
        'customerId': customerId,
        'productId': productId,
        'startDate': startDate.millisecondsSinceEpoch,
        'endDate': endDate.millisecondsSinceEpoch,
        'price': price,
        'registrationFeeAmount': registrationFeeAmount,
        'paidAmount': actualPaid,
        'balanceAmount': balance,
        'paymentStatus': paymentStatus,
        'status': 'active',
        'createdAt': ServerValue.timestamp,
        'updatedAt': ServerValue.timestamp,
        'updatedById': updatedById,
        'ownerId': ownerId,
      };

      updates['subscriptions/$subId'] = subData;
      
      // Mirror to top-level logs only for global auditing natively
      updates['subscription_logs/$shopId/$logId'] = {
        'logId': logId,
        'action': 'create',
        'status': 'active',
        'productName': productName,
        'productId': productId,
        'startDate': startDate.millisecondsSinceEpoch,
        'endDate': endDate.millisecondsSinceEpoch,
        'validityValue': validityValue,
        'validityUnit': validityUnit,
        'price': price,
        'registrationFeeAmount': registrationFeeAmount,
        'amountPaid': actualPaid,
        'paymentMode': paymentMode ?? 'Cash',
        'createdAt': ServerValue.timestamp,
        'createdById': updatedById,
        'updatedById': updatedById, // Redundant but safe for security rules
        'description': 'Subscription created for $validityValue $validityUnit.',
        'subscriptionId': subId,
        'customerId': customerId,
        'shopId': shopId,
        'ownerId': ownerId,
      };

      // Update customer's assigned products and registration fee
      updates['customers/$customerId/assignedProductIds/$productId'] = true;
      updates['customers/$customerId/ownerId'] = ownerId; 
      updates['customers/$customerId/updatedById'] = updatedById;
      updates['customers/$customerId/registrationFeeAmount'] = registrationFeeAmount;
      updates['customers/$customerId/registrationFeeStatus'] = actualPaid >= totalAmount ? 'paid' : (actualPaid > price ? 'partial' : 'unpaid');

      await _database.ref().update(updates);

      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteSubscriptionsForCustomer(String customerId) async {
    try {
      final snapshot = await _database
          .ref()
          .child('subscriptions')
          .orderByChild('customerId')
          .equalTo(customerId)
          .get();
      
      if (snapshot.value != null) {
        final subs = Map<String, dynamic>.from(snapshot.value as Map);
        for (String key in subs.keys) {
          await _database.ref().child('subscriptions/$key').remove();
        }
      }
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> renewSubscription({
    required String subscriptionId,
    required int validityValue,
    required String validityUnit,
    required String updatedById,
    required String productName,
    double? price,
    double? paidAmount,
    String? paymentMode,
  }) async {
    try {
      // 1. Get current subscription to find current endDate and other details
      final snapshot = await _database.ref().child('subscriptions').child(subscriptionId).get();
      if (!snapshot.exists) return Left(ServerFailure("Subscription not found"));
      
      final currentData = Map<String, dynamic>.from(snapshot.value as Map);
      final currentEndDate = DateTime.fromMillisecondsSinceEpoch(currentData['endDate'] as int);
      
      // 2. Calculate new dates (Queuing logic)
      final newStartDate = currentEndDate;
      final newEndDate = _calculateEndDate(newStartDate, validityValue, validityUnit);
      
      // 3. Create NEW subscription record
      final newSubRef = _database.ref().child('subscriptions').push();
      final newSubId = newSubRef.key!;
      
      final logId = _database.ref().push().key ?? DateTime.now().millisecondsSinceEpoch.toString();
      final Map<String, dynamic> updates = {};
      
      final shopId = currentData['shopId'] ?? '';
      final customerId = currentData['customerId'] ?? '';
      final productId = currentData['productId'] ?? '';
      final ownerId = currentData['ownerId'] ?? '';

      final currentPrice = price ?? (currentData['price'] as num? ?? 0.0).toDouble();
      final previousBalance = (currentData['balanceAmount'] as num? ?? 0.0).toDouble();
      final totalAmount = currentPrice + previousBalance;
      final actualPaid = paidAmount ?? currentPrice;
      final balance = totalAmount - actualPaid;
      final paymentStatus = balance <= 0 ? 'paid' : (actualPaid <= 0 ? 'unpaid' : 'partial');

      updates['subscriptions/$newSubId'] = {
        'subscriptionId': newSubId,
        'shopId': shopId,
        'customerId': customerId,
        'productId': productId,
        'startDate': newStartDate.millisecondsSinceEpoch,
        'endDate': newEndDate.millisecondsSinceEpoch,
        'price': currentPrice,
        'paidAmount': actualPaid,
        'balanceAmount': balance,
        'paymentStatus': paymentStatus,
        'status': 'active', // Mark as active so it shows in current plans
        'createdAt': ServerValue.timestamp,
        'updatedAt': ServerValue.timestamp,
        'updatedById': updatedById,
        'ownerId': ownerId,
      };
      
      updates['subscription_logs/$shopId/$logId'] = {
        'logId': logId,
        'subscriptionId': newSubId,
        'customerId': customerId,
        'shopId': shopId,
        'action': 'renew',
        'status': 'active',
        'productName': productName,
        'productId': productId,
        'startDate': newStartDate.millisecondsSinceEpoch,
        'endDate': newEndDate.millisecondsSinceEpoch,
        'validityValue': validityValue,
        'validityUnit': validityUnit,
        'price': currentPrice,
        'registrationFeeAmount': 0.0,
        'amountPaid': actualPaid,
        'paymentMode': paymentMode ?? 'Cash',
        'createdAt': ServerValue.timestamp,
        'createdById': updatedById,
        'updatedById': updatedById,
        'description': 'Subscription renewed for $validityValue $validityUnit (Queued).',
        'ownerId': ownerId,
      };

      // 4. Update Customer metadata to trigger refresh in listeners
      updates['customers/$customerId/updatedAt'] = ServerValue.timestamp;
      updates['customers/$customerId/updatedById'] = updatedById;
      
      await _database.ref().update(updates);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Stream<Either<Failure, List<SubscriptionEntity>>> getSubscriptions(
    String customerId,
    String ownerId,
  ) {
    return _database
        .ref()
        .child('subscriptions')
        .orderByChild('ownerId')
        .equalTo(ownerId)
        .onValue
        .map((event) {
          try {
            final subs = <SubscriptionEntity>[];
            if (event.snapshot.value != null) {
              final data = event.snapshot.value as Map<dynamic, dynamic>;
              data.forEach((key, value) {
                final subData = Map<String, dynamic>.from(value as Map);
                // Filter by customerId locally
                if (subData['customerId'] == customerId) {
                  subs.add(SubscriptionModel.fromJson(subData, key.toString()));
                }
              });
            }
            return Right<Failure, List<SubscriptionEntity>>(subs);
          } catch (e) {
            return Left(ServerFailure(e.toString()));
          }
        });
  }

  @override
  Stream<Either<Failure, List<SubscriptionEntity>>> getExpiringSubscriptions({
    required String shopId,
    required String ownerId,
    required int notificationDaysBefore,
  }) {
    return _database
        .ref()
        .child('subscriptions')
        .orderByChild('ownerId')
        .equalTo(ownerId)
        .onValue
        .map((event) {
          try {
            final now = DateTime.now();
            final threshold = now
                .add(Duration(days: notificationDaysBefore))
                .millisecondsSinceEpoch;

            final expiringSubs = <SubscriptionEntity>[];
            if (event.snapshot.value != null) {
              final data = event.snapshot.value as Map<dynamic, dynamic>;
              data.forEach((key, value) {
                final subData = Map<String, dynamic>.from(value as Map);
                final status = subData['status'] ?? '';
                final endDate = subData['endDate'] as int? ?? 0;
                final sId = subData['shopId'] ?? '';

                if (status == 'active' && endDate <= threshold && sId == shopId) {
                  expiringSubs.add(
                    SubscriptionModel.fromJson(subData, key.toString()),
                  );
                }
              });
            }

            return Right<Failure, List<SubscriptionEntity>>(expiringSubs);
          } catch (e) {
            return Left(ServerFailure(e.toString()));
          }
        });
  }

  @override
  Stream<Either<Failure, List<SubscriptionEntity>>> getActiveSubscriptions({
    required String shopId,
    required String ownerId,
  }) {
    return _database
        .ref()
        .child('subscriptions')
        .orderByChild('ownerId')
        .equalTo(ownerId)
        .onValue
        .map((event) {
          try {
            final activeSubs = <SubscriptionEntity>[];
            if (event.snapshot.value != null) {
              final data = event.snapshot.value as Map<dynamic, dynamic>;
              data.forEach((key, value) {
                final subData = Map<String, dynamic>.from(value as Map);
                final status = subData['status'] ?? '';
                final sId = subData['shopId'] ?? '';

                if (status == 'active' && sId == shopId) {
                  activeSubs.add(
                    SubscriptionModel.fromJson(subData, key.toString()),
                  );
                }
              });
            }

            return Right<Failure, List<SubscriptionEntity>>(activeSubs);
          } catch (e) {
            return Left(ServerFailure(e.toString()));
          }
        });
  }

  @override
  Future<Either<Failure, List<SubscriptionLogEntity>>> getSubscriptionLogs({
    required String shopId,
    required String ownerId,
    String? customerId,
  }) async {
    try {
      final snapshot = await _database
          .ref()
          .child('subscription_logs')
          .child(shopId)
          .get();

      final logs = <SubscriptionLogEntity>[];
      if (snapshot.value != null) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        data.forEach((key, value) {
          final logData = Map<String, dynamic>.from(value as Map);
          final log = SubscriptionLogModel.fromJson(logData, key.toString());
          
          if (customerId == null || log.customerId == customerId) {
             logs.add(log);
          }
        });
      }

      // Sort by creation date (newest first)
      logs.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return Right<Failure, List<SubscriptionLogEntity>>(logs);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
  @override
  Future<Either<Failure, void>> updateSubscription({
    required String subscriptionId,
    required DateTime endDate,
    required double price,
    double? registrationFeeAmount,
    double? paidAmount,
    String? paymentMode,
    required String updatedById,
    String? status,
  }) async {
    try {
      final subRef = _database.ref().child('subscriptions').child(subscriptionId);
      final snapshot = await subRef.get();
      if (!snapshot.exists) return Left(ServerFailure("Subscription not found"));
      
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      
      final newRegFee = registrationFeeAmount ?? (data['registrationFeeAmount'] ?? 0.0).toDouble();
      final newTotal = price + newRegFee;
      final newPaid = paidAmount ?? (data['paidAmount'] ?? data['price'] ?? 0.0).toDouble();
      final newBalance = newTotal - newPaid;
      final newPaymentStatus = newBalance <= 0 ? 'paid' : (newPaid <= 0 ? 'unpaid' : 'partial');

      final Map<String, dynamic> updates = {};
      
      updates['subscriptions/$subscriptionId'] = {
        ...data,
        'endDate': endDate.millisecondsSinceEpoch,
        'price': price,
        'registrationFeeAmount': newRegFee,
        'paidAmount': newPaid,
        'balanceAmount': newBalance,
        'paymentStatus': newPaymentStatus,
        'status': status ?? data['status'],
        'updatedAt': ServerValue.timestamp,
        'updatedById': updatedById,
      };

      final shopId = data['shopId'] ?? '';
      final customerId = data['customerId'] ?? '';
      final productId = data['productId'] ?? '';
      final logId = _database.ref().push().key ?? DateTime.now().millisecondsSinceEpoch.toString();

      final Map<String, dynamic> extraUpdates = {};

      // Update customer record if status or registration fee was provided
      if (customerId.isNotEmpty) {
        if (status != null && productId.isNotEmpty) {
          extraUpdates['customers/$customerId/assignedProductIds/$productId'] = status;
        }
        if (registrationFeeAmount != null) {
          extraUpdates['customers/$customerId/registrationFeeAmount'] = registrationFeeAmount;
          extraUpdates['customers/$customerId/registrationFeeStatus'] = newPaymentStatus; // Use calculated status
        }
        if (extraUpdates.isNotEmpty) {
          extraUpdates['customers/$customerId/updatedAt'] = ServerValue.timestamp;
          extraUpdates['customers/$customerId/updatedById'] = updatedById;
        }
      }

      extraUpdates['subscription_logs/$shopId/$logId'] = {
        'logId': logId,
        'subscriptionId': subscriptionId,
        'customerId': customerId,
        'shopId': shopId,
        'action': 'edit',
        'status': status ?? data['status'],
        'endDate': endDate.millisecondsSinceEpoch,
        'price': price,
        'registrationFeeAmount': newRegFee,
        'amountPaid': paidAmount, // Only if explicitly passed in edit
        'paymentMode': paymentMode,
        'createdAt': ServerValue.timestamp,
        'createdById': updatedById,
        'updatedById': updatedById,
        'description': 'Subscription details corrected.',
        'ownerId': data['ownerId'] ?? '',
        'productId': productId,
      };

      if (extraUpdates.isNotEmpty) {
        updates.addAll(extraUpdates); // Add to the main update call if possible?
      }

      await _database.ref().update(updates);

      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  DateTime _calculateEndDate(DateTime start, int value, String unit) {
    if (unit.toLowerCase().contains('month')) {
      // Add calendar months accurately
      final destMonth = (start.month + value - 1) % 12 + 1;
      final destYear = start.year + (start.month + value - 1) ~/ 12;
      
      final tmp = DateTime(destYear, destMonth, start.day, start.hour, start.minute, start.second);
      if (tmp.month != destMonth) {
        // Rolled over (e.g., Jan 31 -> March 2). Return last day of destMonth.
        return DateTime(destYear, destMonth + 1, 0, start.hour, start.minute, start.second);
      }
      return tmp;
    } else if (unit.toLowerCase().contains('year')) {
       // Add calendar years accurately (handles Feb 29 rollover)
       final tmp = DateTime(start.year + value, start.month, start.day, start.hour, start.minute, start.second);
       if (tmp.month != start.month) {
         // Rolled over (Feb 29 -> March 1). Return Feb 28.
         return DateTime(start.year + value, start.month + 1, 0, start.hour, start.minute, start.second);
       }
       return tmp;
    } else {
      // Default to days
      return start.add(Duration(days: value));
    }
  }
}
