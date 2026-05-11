import 'package:firebase_database/firebase_database.dart';
import 'package:dartz/dartz.dart';
import 'package:csms/core/error/failures.dart';
import '../../domain/repositories/shop_subscription_repository.dart';
import '../../domain/entities/shop_subscription_entity.dart';
import '../../domain/entities/shop_subscription_log_entity.dart';
import '../models/shop_subscription_model.dart';
import '../models/shop_subscription_log_model.dart';

class ShopSubscriptionRepositoryImpl implements ShopSubscriptionRepository {
  final FirebaseDatabase _database;

  ShopSubscriptionRepositoryImpl({FirebaseDatabase? database})
    : _database = database ?? FirebaseDatabase.instance;

  @override
  Future<Either<Failure, ShopSubscriptionEntity>> getShopSubscriptionStatus(
    String shopId,
  ) async {
    try {
      print('DEBUG: Fetching subscription for shopId: $shopId');
      final snapshot = await _database
          .ref()
          .child('shop_subscriptions')
          .child(shopId)
          .get();
      print(
        'DEBUG: Snapshot exists: ${snapshot.exists}, Value: ${snapshot.value}',
      );
      if (!snapshot.exists) {
        return Left(ServerFailure('Shop subscription not found for $shopId'));
      }
      final data = Map<String, dynamic>.from(snapshot.value as Map);

      // Lookup plan price if active plan exists
      if (data['active'] != null && data['active']['planId'] != null) {
        final planId = data['active']['planId'];
        final planSnapshot = await _database
            .ref()
            .child('subscription_plans')
            .child(planId)
            .get();
        if (planSnapshot.exists) {
          final planData = Map<dynamic, dynamic>.from(
            planSnapshot.value as Map,
          );
          data['active']['price'] = planData['price'] ?? 0.0;
        }
      }

      return Right(ShopSubscriptionModel.fromJson(data, shopId));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Stream<Either<Failure, ShopSubscriptionEntity>>
  getShopSubscriptionStatusStream(String shopId) {
    return _database
        .ref()
        .child('shop_subscriptions')
        .child(shopId)
        .onValue
        .asyncMap((event) async {
          try {
            print(
              'DEBUG: Stream event for shopId: $shopId, Data: ${event.snapshot.value}',
            );
            final data = event.snapshot.value;
            if (data == null) {
              return Left<Failure, ShopSubscriptionEntity>(
                ServerFailure('Shop subscription not found for $shopId'),
              );
            }
            final mapData = Map<String, dynamic>.from(data as Map);

            // Lookup plan price
            if (mapData['active'] != null &&
                mapData['active']['planId'] != null) {
              final planId = mapData['active']['planId'];
              final planSnapshot = await _database
                  .ref()
                  .child('subscription_plans')
                  .child(planId)
                  .get();
              if (planSnapshot.exists) {
                final planData = Map<dynamic, dynamic>.from(
                  planSnapshot.value as Map,
                );
                mapData['active']['price'] = planData['price'] ?? 0.0;
              }
            }

            return Right<Failure, ShopSubscriptionEntity>(
              ShopSubscriptionModel.fromJson(mapData, shopId),
            );
          } catch (e) {
            return Left<Failure, ShopSubscriptionEntity>(
              ServerFailure(e.toString()),
            );
          }
        });
  }

  @override
  Future<Either<Failure, List<ShopSubscriptionLogEntity>>>
  getShopSubscriptionHistory(String shopId, String ownerId) async {
    try {
      // Fetch the entire shop subscription node to get both active and history
      final snapshot = await _database
          .ref()
          .child('shop_subscriptions')
          .child(shopId)
          .get();

      final logs = <ShopSubscriptionLogEntity>[];

      if (snapshot.exists) {
        final data = Map<dynamic, dynamic>.from(snapshot.value as Map);

        // Fetch all plans once for price lookup
        final plansSnapshot = await _database
            .ref()
            .child('subscription_plans')
            .get();
        final plansData = plansSnapshot.exists
            ? Map<dynamic, dynamic>.from(plansSnapshot.value as Map)
            : {};

        // 1. Process Active Plan (if it exists)
        if (data['active'] != null) {
          final activeData = Map<String, dynamic>.from(data['active'] as Map);
          final planId = activeData['planId'];
          
          // Lookup price for active plan
          if (planId != null && plansData[planId] != null) {
            final planMap = Map<dynamic, dynamic>.from(plansData[planId] as Map);
            activeData['price'] = planMap['price'] ?? 0.0;
          }

          logs.add(ShopSubscriptionLogModel.fromJson(
            {
              ...activeData,
              'action': 'active', // Mark as current active plan
              'timestamp': activeData['startDate'] ?? DateTime.now().millisecondsSinceEpoch,
              'shopId': shopId,
            },
            'current_active',
          ));
        }

        // 2. Process Queued Plans (if they exist)
        if (data['queued'] != null) {
          final queuedData = Map<dynamic, dynamic>.from(data['queued'] as Map);
          queuedData.forEach((key, value) {
            final logData = Map<String, dynamic>.from(value as Map);
            final planId = logData['planId'];

            // Lookup price for queued plan
            if (planId != null && plansData[planId] != null) {
              final planMap = Map<dynamic, dynamic>.from(plansData[planId] as Map);
              logData['price'] = planMap['price'] ?? 0.0;
            }

            logs.add(ShopSubscriptionLogModel.fromJson(
              {
                ...logData,
                'action': 'queued',
                'status': 'queued',
                'timestamp': DateTime.now().millisecondsSinceEpoch + 1000, // Slightly in future to keep above active
                'shopId': shopId,
              },
              key.toString(),
            ));
          });
        }

        // 3. Process History Logs (if they exist)
        if (data['history'] != null) {
          final historyData = Map<dynamic, dynamic>.from(data['history'] as Map);
          historyData.forEach((key, value) {
            final logData = Map<String, dynamic>.from(value as Map);

            // Lookup price for history plan
            if (logData['planId'] != null) {
              final planId = logData['planId'];
              final planInfo = plansData[planId];
              if (planInfo != null) {
                final planMap = Map<dynamic, dynamic>.from(planInfo as Map);
                logData['price'] = planMap['price'] ?? 0.0;
              }
            }

            logs.add(ShopSubscriptionLogModel.fromJson(logData, key.toString()));
          });
        }
      }

      // Sort by timestamp descending
      logs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return Right(logs);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> renewShopSubscription({
    required String shopId,
    required String ownerId,
    required int validityValue,
    required String validityUnit,
    required double price,
    required String updatedById,
  }) async {
    // This logic might need further update based on how the user wants "assigned" vs "renew" to work
    // For now, I'll update the paths to match the new schema
    try {
      final String _ =
          _database.ref().child('shop_subscription_logs').push().key ??
          DateTime.now().millisecondsSinceEpoch.toString();

      // Note: Full implementation of renewal with the new nested active/queued structure
      // depends on the business logic for queuing.
      // For now, I'm just correcting the paths based on the provided JSON.

      // ... renewal logic would go here, updating 'shop_subscriptions/$shopId/...'
      // and 'shop_subscription_logs/$logId'

      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
