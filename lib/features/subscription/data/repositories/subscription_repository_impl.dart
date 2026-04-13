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
    bool isNewCustomer = false,
    String? notes,
  }) async {
    try {
      final startDate = DateTime.now();
      final endDate = _calculateEndDate(startDate, validityValue, validityUnit);

      final subRef = _database.ref().child('subscriptions').push();
      final subId = subRef.key!;

      final Map<String, dynamic> updates = {};

      final logId = _database.ref().push().key ?? 'initial';

      final customerSnapshot = await _database
          .ref()
          .child('customers/$customerId')
          .get();
      double totalRegAmount = registrationFeeAmount;
      double previousRegPaid = 0.0;

      if (customerSnapshot.exists) {
        final custData = customerSnapshot.value as Map;
        totalRegAmount =
            (custData['registrationFeeAmount'] ?? registrationFeeAmount)
                .toDouble();
        previousRegPaid = (custData['registrationFeePaidAmount'] ?? 0.0)
            .toDouble();
      }

      final double remainingReg = (totalRegAmount - previousRegPaid).clamp(
        0,
        double.infinity,
      );
      final double totalPaid = (paidAmount ?? 0.0).toDouble();

      // Prioritize registration fee
      final double regPaidInThisSub = totalPaid >= remainingReg
          ? remainingReg
          : totalPaid;
      final double subPaid = totalPaid - regPaidInThisSub;

      final double subPrice = price.toDouble();
      final double subBalance = subPrice - subPaid;
      final String subPaymentStatus = subBalance <= 0
          ? 'paid'
          : (subPaid <= 0 ? 'unpaid' : 'partial');

      final double newTotalRegPaid = previousRegPaid + regPaidInThisSub;
      final String newRegStatus = totalRegAmount <= 0
          ? 'paid'
          : (newTotalRegPaid >= totalRegAmount
                ? 'paid'
                : (newTotalRegPaid > 0 ? 'partial' : 'unpaid'));

      updates['subscriptions/$subId'] = {
        'subscriptionId': subId,
        'shopId': shopId,
        'customerId': customerId,
        'productId': productId,
        'startDate': startDate.millisecondsSinceEpoch,
        'endDate': endDate.millisecondsSinceEpoch,
        'status': 'active',
        'createdAt': ServerValue.timestamp,
        'updatedAt': ServerValue.timestamp,
        'price': subPrice,
        'paidAmount': subPaid,
        'balanceAmount': subBalance,
        'paymentStatus': subPaymentStatus,
        'registrationFeeAmount': totalRegAmount,
        'registrationFeePaid': regPaidInThisSub,
        'paymentMode': paymentMode ?? 'Cash',
        'updatedById': updatedById,
        'ownerId': ownerId,
        'notes': notes,
      };

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
        'price': subPrice,
        'paidAmount': subPaid,
        'registrationFeePaid': regPaidInThisSub,
        'balanceAmount': subBalance,
        'paymentMode': paymentMode ?? 'Cash',
        'createdAt': ServerValue.timestamp,
        'createdById': updatedById,
        'updatedById': updatedById,
        'description': 'Subscription created.',
        'subscriptionId': subId,
        'customerId': customerId,
        'shopId': shopId,
        'ownerId': ownerId,
      };

      // Update customer's assigned products and registration fee state
      updates['customers/$customerId/assignedProductIds/$productId'] = true;
      updates['customers/$customerId/ownerId'] = ownerId;
      updates['customers/$customerId/updatedById'] = updatedById;

      // Always sync registration fee state to customer
      updates['customers/$customerId/registrationFeeAmount'] = totalRegAmount;
      updates['customers/$customerId/registrationFeePaidAmount'] =
          newTotalRegPaid;
      updates['customers/$customerId/registrationFeeStatus'] = newRegStatus;

      await _database.ref().update(updates);

      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteSubscriptionsForCustomer(
    String customerId,
  ) async {
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
    String? notes,
  }) async {
    try {
      // 1. Get current subscription to find current endDate and other details
      final snapshot = await _database
          .ref()
          .child('subscriptions')
          .child(subscriptionId)
          .get();
      if (!snapshot.exists)
        return Left(ServerFailure("Subscription not found"));

      final currentData = Map<String, dynamic>.from(snapshot.value as Map);
      final currentEndDate = DateTime.fromMillisecondsSinceEpoch(
        currentData['endDate'] as int,
      );

      // 2. Calculate new dates (Queuing logic)
      final newStartDate = currentEndDate;
      final newEndDate = _calculateEndDate(
        newStartDate,
        validityValue,
        validityUnit,
      );

      // 3. Create NEW subscription record
      final newSubRef = _database.ref().child('subscriptions').push();
      final newSubId = newSubRef.key!;

      final logId =
          _database.ref().push().key ??
          DateTime.now().millisecondsSinceEpoch.toString();
      final Map<String, dynamic> updates = {};

      final shopId = currentData['shopId'] ?? '';
      final customerId = currentData['customerId'] ?? '';
      final productId = currentData['productId'] ?? '';
      final ownerId = currentData['ownerId'] ?? '';

      final currentPrice =
          price ?? (currentData['price'] as num? ?? 0.0).toDouble();
      final previousBalance = (currentData['balanceAmount'] as num? ?? 0.0)
          .toDouble();
      final totalAmount = currentPrice + previousBalance;
      final actualPaid = paidAmount ?? currentPrice;
      final balance = totalAmount - actualPaid;
      final paymentStatus = balance <= 0
          ? 'paid'
          : (actualPaid <= 0 ? 'unpaid' : 'partial');

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
        'paymentMode': paymentMode ?? 'Cash',
        'createdAt': ServerValue.timestamp,
        'updatedAt': ServerValue.timestamp,
        'updatedById': updatedById,
        'ownerId': ownerId,
        'notes': notes,
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
        'paidAmount': actualPaid,
        'balanceAmount': balance,
        'paymentMode': paymentMode ?? 'Cash',
        'createdAt': ServerValue.timestamp,
        'createdById': updatedById,
        'updatedById': updatedById,
        'description':
            'Subscription renewed for $validityValue $validityUnit (Queued).',
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

            final expiringSubs = <SubscriptionEntity>[];
            if (event.snapshot.value != null) {
              final data = event.snapshot.value as Map<dynamic, dynamic>;
              data.forEach((key, value) {
                final subData = Map<String, dynamic>.from(value as Map);
                final status = subData['status'] ?? '';
                final endDateInt = subData['endDate'] as int? ?? 0;
                final sId = subData['shopId'] ?? '';

                if (status == 'active' && sId == shopId) {
                  final eDate = DateTime.fromMillisecondsSinceEpoch(
                    endDateInt,
                    isUtc: true,
                  ).toLocal();

                  // EXACT same logic as report_repository_impl.dart:
                  // 1. Must pass activeSubsAtEnd filter: !s.endDate.toLocal().isBefore(statusRefPoint)
                  if (!eDate.isBefore(now)) {
                    // 2. Must pass expiringSoonSubs filter: days >= 0 && days <= threshold
                    final days = eDate.difference(now).inDays;
                    if (days >= 0 && days <= notificationDaysBefore) {
                      expiringSubs.add(
                        SubscriptionModel.fromJson(subData, key.toString()),
                      );
                    }
                  }
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
    double? registrationFeePaid,
    double? paidAmount,
    String? paymentMode,
    required String updatedById,
    String? status,
    String? notes,
  }) async {
    try {
      final subRef = _database
          .ref()
          .child('subscriptions')
          .child(subscriptionId);
      final snapshot = await subRef.get();
      if (!snapshot.exists) {
        return Left(ServerFailure("Subscription not found"));
      }

      final data = Map<String, dynamic>.from(snapshot.value as Map);

      // 1. Subscription Payment Diff
      final double oldPaid = (data['paidAmount'] ?? 0.0).toDouble();
      final double subPaid = paidAmount ?? oldPaid;
      final double paymentDifference = subPaid - oldPaid;

      // 2. Registration Fee Payment Diff
      final double oldRegPaid = (data['registrationFeePaid'] ?? 0.0).toDouble();
      final double newRegPaid = registrationFeePaid ?? oldRegPaid;
      final double regPaymentDifference = newRegPaid - oldRegPaid;

      // 3. Status/Price detection
      final bool isPayment =
          (paymentDifference != 0 || regPaymentDifference != 0) &&
          price == (data['price'] as num? ?? 0.0).toDouble();

      final double subPrice = price;
      final double balance = subPrice - subPaid;
      final String paymentStatus = balance <= 0
          ? 'paid'
          : (subPaid <= 0 ? 'unpaid' : 'partial');

      final double currentRegAmount =
          registrationFeeAmount ??
          (data['registrationFeeAmount'] ?? 0.0).toDouble();

      final Map<String, dynamic> updates = {};

      updates['subscriptions/$subscriptionId'] = {
        ...data,
        'endDate': endDate.millisecondsSinceEpoch,
        'price': subPrice,
        'paidAmount': subPaid,
        'balanceAmount': balance,
        'paymentStatus': paymentStatus,
        'registrationFeeAmount': currentRegAmount,
        'registrationFeePaid': newRegPaid,
        'paymentMode': paymentMode ?? data['paymentMode'] ?? 'Cash',
        'status': status ?? data['status'],
        'updatedAt': ServerValue.timestamp,
        'updatedById': updatedById,
        'notes': notes ?? data['notes'],
      };

      final shopId = data['shopId'] ?? '';
      final customerId = data['customerId'] ?? '';
      final productId = data['productId'] ?? '';
      final logId =
          _database.ref().push().key ??
          DateTime.now().millisecondsSinceEpoch.toString();

      final Map<String, dynamic> extraUpdates = {};

      // 4. Update customer record (Sync)
      if (customerId.isNotEmpty) {
        if (status != null && productId.isNotEmpty) {
          extraUpdates['customers/$customerId/assignedProductIds/$productId'] =
              status;
        }

        // // Sync Registration Fee to Customer
        // extraUpdates['customers/$customerId/registrationFeeAmount'] = currentRegAmount;
        // extraUpdates['customers/$customerId/registrationFeePaidAmount'] = newRegPaid;
        // extraUpdates['customers/$customerId/registrationFeeStatus'] =
        //     currentRegAmount <= 0 ? 'paid' : (newRegPaid >= currentRegAmount ? 'paid' : (newRegPaid > 0 ? 'partial' : 'unpaid'));

        extraUpdates['customers/$customerId/updatedAt'] = ServerValue.timestamp;
        extraUpdates['customers/$customerId/updatedById'] = updatedById;
      }

      // 5. Create History Log(s)
      final String oldMode = data['paymentMode'] ?? 'Cash';
      final String newMode = paymentMode ?? oldMode;

      // Logic: If we are adding NEW money (balance collection), just log the ADDED amount in the NEW mode.
      // If we are NOT adding money (zero difference) but the mode changed, then it's a correction of the whole history.
      final bool isBalanceCollection = paymentDifference > 0 || regPaymentDifference > 0;
      final bool isPureModeCorrection = !isBalanceCollection && (newMode != oldMode) && oldPaid > 0;

      if (isPureModeCorrection) {
        // Reversal Log for Old Mode
        final reversalLogId = "${logId}_rev";
        extraUpdates['subscription_logs/$shopId/$reversalLogId'] = {
          'logId': reversalLogId,
          'subscriptionId': subscriptionId,
          'customerId': customerId,
          'shopId': shopId,
          'action': 'payment',
          'status': status ?? data['status'],
          'endDate': endDate.millisecondsSinceEpoch,
          'price': price,
          'paidAmount': -oldPaid, // Reverse the old payment
          'balanceAmount': balance,
          'paymentMode': oldMode,
          'createdAt': ServerValue.timestamp,
          'createdById': updatedById,
          'updatedById': updatedById,
          'description': 'Payment Mode Correction (Reversal of $oldMode)',
          'ownerId': data['ownerId'] ?? '',
          'productId': productId,
        };

        // Addition Log for New Mode (The full amount including any difference)
        extraUpdates['subscription_logs/$shopId/$logId'] = {
          'logId': logId,
          'subscriptionId': subscriptionId,
          'customerId': customerId,
          'shopId': shopId,
          'action': 'payment',
          'status': status ?? data['status'],
          'endDate': endDate.millisecondsSinceEpoch,
          'price': price,
          'paidAmount': subPaid, // The full corrected amount in the new mode
          'balanceAmount': balance,
          'paymentMode': newMode,
          'createdAt': ServerValue.timestamp,
          'createdById': updatedById,
          'updatedById': updatedById,
          'description': 'Payment Mode Correction (Correction to $newMode)',
          'ownerId': data['ownerId'] ?? '',
          'productId': productId,
        };
      } else {
        // Regular Payment/Edit Log
        // If it's a balance collection, we ONLY log the difference.
        // This ensures old payments stay in their original modes in logs.
        extraUpdates['subscription_logs/$shopId/$logId'] = {
          'logId': logId,
          'subscriptionId': subscriptionId,
          'customerId': customerId,
          'shopId': shopId,
          'action': isPayment ? 'payment' : 'edit',
          'status': status ?? data['status'],
          'endDate': endDate.millisecondsSinceEpoch,
          'price': price,
          'paidAmount': paymentDifference != 0 ? paymentDifference : null,
          'registrationFeePaid': regPaymentDifference != 0
              ? regPaymentDifference
              : null,
          'balanceAmount': balance,
          'paymentMode': newMode, // The mode of THIS specific payment event
          'createdAt': ServerValue.timestamp,
          'createdById': updatedById,
          'updatedById': updatedById,
          'description': (regPaymentDifference < 0 || paymentDifference < 0)
              ? 'Payment Correction (Reduced)'
              : (isPayment ? 'Balance/Fee collected.' : 'Details corrected.'),
          'ownerId': data['ownerId'] ?? '',
          'productId': productId,
        };
      }

      if (extraUpdates.isNotEmpty) {
        updates.addAll(
          extraUpdates,
        ); // Add to the main update call if possible?
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

      final tmp = DateTime(
        destYear,
        destMonth,
        start.day,
        start.hour,
        start.minute,
        start.second,
      );
      if (tmp.month != destMonth) {
        // Rolled over (e.g., Jan 31 -> March 2). Return last day of destMonth.
        return DateTime(
          destYear,
          destMonth + 1,
          0,
          start.hour,
          start.minute,
          start.second,
        );
      }
      return tmp;
    } else if (unit.toLowerCase().contains('year')) {
      // Add calendar years accurately (handles Feb 29 rollover)
      final tmp = DateTime(
        start.year + value,
        start.month,
        start.day,
        start.hour,
        start.minute,
        start.second,
      );
      if (tmp.month != start.month) {
        // Rolled over (Feb 29 -> March 1). Return Feb 28.
        return DateTime(
          start.year + value,
          start.month + 1,
          0,
          start.hour,
          start.minute,
          start.second,
        );
      }
      return tmp;
    } else {
      // Default to days
      return start.add(Duration(days: value));
    }
  }
}
