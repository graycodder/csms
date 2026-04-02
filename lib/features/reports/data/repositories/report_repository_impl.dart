import 'package:dartz/dartz.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:csms/core/error/failures.dart';
import 'package:csms/features/reports/domain/entities/report_entity.dart';
import 'package:csms/features/reports/domain/repositories/report_repository.dart';
import 'package:csms/features/customer/data/models/customer_model.dart';
import 'package:csms/features/subscription/data/models/subscription_model.dart';
import 'package:csms/features/subscription/data/models/subscription_log_model.dart';
import 'package:csms/features/product/data/models/product_model.dart';

class ReportRepositoryImpl implements ReportRepository {
  final FirebaseDatabase _database;

  ReportRepositoryImpl({required FirebaseDatabase database})
    : _database = database;

  @override
  Future<Either<Failure, ReportEntity>> getReport({
    required String shopId,
    required String ownerId,
    required ReportFilter filter,
    DateTime? referenceDate,
  }) async {
    try {
      final ref = referenceDate ?? DateTime.now();

      // ── Range Bounds (IST Local) ──────────────────────────────────────────
      DateTime rangeFrom;
      DateTime rangeTo;
      switch (filter) {
        case ReportFilter.daily:
          rangeFrom = DateTime(ref.year, ref.month, ref.day);
          rangeTo = DateTime(ref.year, ref.month, ref.day, 23, 59, 59, 999);
          break;
        case ReportFilter.monthly:
          rangeFrom = DateTime(ref.year, ref.month, 1);
          rangeTo = DateTime(ref.year, ref.month + 1, 0, 23, 59, 59, 999);
          break;
      }

      // ── Fetch Data ────────────────────────────────────────────────────────
      final results = await Future.wait([
        _database
            .ref()
            .child('customers')
            .orderByChild('ownerId')
            .equalTo(ownerId)
            .get(),
        _database
            .ref()
            .child('subscriptions')
            .orderByChild('ownerId')
            .equalTo(ownerId)
            .get(),
        _database.ref().child('subscription_logs').child(shopId).get(),
        _database
            .ref()
            .child('products')
            .orderByChild('ownerId')
            .equalTo(ownerId)
            .get(),
      ]);

      final DataSnapshot customerSnap = results[0];
      final DataSnapshot subSnap = results[1];
      final DataSnapshot logSnap = results[2];
      final DataSnapshot productSnap = results[3];

      // ── Robust Parsing ───────────────────────────────────────────────────
      List<CustomerModel> parseCustomers() {
        final list = <CustomerModel>[];
        if (customerSnap.value != null) {
          final data = customerSnap.value as Map<dynamic, dynamic>;
          data.forEach((key, val) {
            final map = Map<String, dynamic>.from(val as Map);
            if (map['shopId'] == shopId) {
              list.add(CustomerModel.fromJson(map, key.toString()));
            }
          });
        }
        return list;
      }

      List<SubscriptionModel> parseSubs() {
        final list = <SubscriptionModel>[];
        if (subSnap.value != null) {
          final data = subSnap.value as Map<dynamic, dynamic>;
          data.forEach((key, val) {
            final map = Map<String, dynamic>.from(val as Map);
            if (map['shopId'] == shopId) {
              list.add(SubscriptionModel.fromJson(map, key.toString()));
            }
          });
        }
        return list;
      }

      List<SubscriptionLogModel> parseLogs() {
        final list = <SubscriptionLogModel>[];
        if (logSnap.value != null) {
          final data = logSnap.value as Map<dynamic, dynamic>;
          data.forEach((key, val) {
            list.add(
              SubscriptionLogModel.fromJson(
                Map<String, dynamic>.from(val as Map),
                key.toString(),
              ),
            );
          });
        }
        return list;
      }

      List<ProductModel> parseProducts() {
        final list = <ProductModel>[];
        if (productSnap.value != null) {
          final data = productSnap.value as Map<dynamic, dynamic>;
          data.forEach((key, val) {
            final map = Map<String, dynamic>.from(val as Map);
            if (map['shopId'] == shopId) {
              list.add(ProductModel.fromJson(map, key.toString()));
            }
          });
        }
        return list;
      }

      final allCustomers = parseCustomers();
      final allSubscriptions = parseSubs();
      final allLogs = parseLogs();
      final allProducts = parseProducts();

      // ── Metrics Generation ────────────────────────────────────────────────
      // Period Activity

      // Period Activity
      final List<SubscriptionLogModel> periodLogs = allLogs.where((l) => 
        l.createdAt.toLocal().isAfter(rangeFrom.subtract(const Duration(milliseconds: 1))) && 
        l.createdAt.toLocal().isBefore(rangeTo.add(const Duration(milliseconds: 1)))
      ).toList();

      final List<SubscriptionModel> newSubs = allSubscriptions.where((s) {
        final dateToUse = s.createdAt.year == 1970 ? s.startDate : s.createdAt;
        final local = dateToUse.toLocal();
        return !local.isBefore(rangeFrom) && !local.isAfter(rangeTo);
      }).toList();

      final List<CustomerModel> newCustomers = allCustomers.where((c) {
        final local = c.createdAt.toLocal();
        return !local.isBefore(rangeFrom) && !local.isAfter(rangeTo);
      }).toList();

      // ── REVENUE CALCULATION: Difference-based Fallback Logic ───────────────
      double totalSubRevenue = 0.0;
      double totalRegRevenue = 0.0;

      // 1. Sum all payments from logs in the period
      final Map<String, double> loggedSubPaidMap = {}; // subscriptionId -> sum
      final Map<String, double> loggedRegPaidMap = {}; // customerId -> sum

      for (var l in periodLogs) {
        if (l.action == 'payment') {
          final sPaid = l.paidAmount ?? 0.0;
          final rPaid = l.registrationFeePaid ?? 0.0;
          totalSubRevenue += sPaid;
          totalRegRevenue += rPaid;
          
          if (l.subscriptionId != null) {
            loggedSubPaidMap[l.subscriptionId!] = (loggedSubPaidMap[l.subscriptionId!] ?? 0.0) + sPaid;
          }
          loggedRegPaidMap[l.customerId] = (loggedRegPaidMap[l.customerId] ?? 0.0) + rPaid;
        }
      }

      // 2. Fallback for New Subscriptions: Add what's missing from logs
      for (var s in newSubs) {
        final double logged = loggedSubPaidMap[s.subscriptionId] ?? 0.0;
        final double missing = (s.paidAmount - logged).clamp(0, double.infinity);
        totalSubRevenue += missing;
        
        // Also check if reg fee was skipped in logs
        final double regLogged = loggedRegPaidMap[s.customerId] ?? 0.0;
        final double regMissing = (s.registrationFeePaid - regLogged).clamp(0, double.infinity);
        totalRegRevenue += regMissing;
        
        // Update map so we don't count it again in newCustomers fallback
        loggedRegPaidMap[s.customerId] = regLogged + regMissing;
      }

      // 3. Fallback for New Customers: Add remaining reg fee missing from logs/subs
      for (var c in newCustomers) {
        final double logged = loggedRegPaidMap[c.customerId] ?? 0.0;
        final double missing = (c.registrationFeePaidAmount - logged).clamp(0, double.infinity);
        totalRegRevenue += missing;
      }

      // ── HISTORICAL STATUS: Snapshot as of rangeTo ────────────────────────
      // Someone is active if they have ANY subscription that exists at rangeTo
      // i.e. startDate <= rangeTo AND endDate >= rangeTo
      final activeSubsAtEnd = allSubscriptions.where((s) {
        final start = s.startDate.toLocal();
        final end = s.endDate.toLocal();
        return !start.isAfter(rangeTo) && !end.isBefore(rangeFrom); 
      }).toList();

      final Set<String> activeCustomerIds = activeSubsAtEnd.map((s) => s.customerId).toSet();
      
      // Cumulative Stats (created before or at rangeTo)
      final customersBeforeEnd = allCustomers.where((c) => !c.createdAt.toLocal().isAfter(rangeTo)).toList();

      // Expiring Soon: Active subs ending in the next 7 days from rangeTo
      final expiringSoonSubs = activeSubsAtEnd.where((s) {
        final days = s.endDate.toLocal().difference(rangeTo).inDays;
        return days >= 0 && days <= 7;
      }).toList();

      // Expired: Total ever expired as of rangeTo
      final expiredCount = allSubscriptions.where((s) => s.endDate.toLocal().isBefore(rangeFrom)).length;

      // ── PENDING CALCULATIONS: Current live state ──────────────────────────
      final Map<String, SubscriptionModel> latestPerPlan = {};
      for (var s in allSubscriptions) {
        final key = '${s.customerId}_${s.productId}';
        final existing = latestPerPlan[key];
        if (existing == null || s.endDate.isAfter(existing.endDate)) {
          latestPerPlan[key] = s;
        }
      }
      final double totalPendingSubBalance = latestPerPlan.values.fold(0.0, 
        (sum, s) => sum + (s.balanceAmount > 0 ? s.balanceAmount : 0));
        
      final double totalPendingRegBalance = allCustomers.fold(0.0, 
        (sum, c) => sum + (c.registrationFeeAmount - c.registrationFeePaidAmount).clamp(0, double.infinity));

      // ── CHART DATA ────────────────────────────────────────────────────────
      final Map<DateTime, double> hourlyRev = {};
      if (filter == ReportFilter.daily) {
        for (int h = 0; h < 24; h++) {
          hourlyRev[DateTime(ref.year, ref.month, ref.day, h)] = 0.0;
        }
      } else {
        final lastDay = DateTime(ref.year, ref.month + 1, 0).day;
        for (int d = 1; d <= lastDay; d++) {
          hourlyRev[DateTime(ref.year, ref.month, d)] = 0.0;
        }
      }

      DateTime getBucket(DateTime dt) => (filter == ReportFilter.daily)
          ? DateTime(dt.year, dt.month, dt.day, dt.hour)
          : DateTime(dt.year, dt.month, dt.day);

      for (var s in newSubs) {
         final b = getBucket(s.createdAt.toLocal());
         if (hourlyRev.containsKey(b)) {
            final double logged = loggedSubPaidMap[s.subscriptionId] ?? 0.0;
            final double missing = (s.paidAmount - logged).clamp(0, double.infinity);
            
            final double regLogged = loggedRegPaidMap[s.customerId] ?? 0.0;
            final double regMissing = (s.registrationFeePaid - regLogged).clamp(0, double.infinity);
            
            hourlyRev[b] = (hourlyRev[b] ?? 0.0) + missing + regMissing;
            
            // Update maps to avoid double-counting in newCustomers
            loggedRegPaidMap[s.customerId] = regLogged + regMissing;
         }
      }
      
      for (var c in newCustomers) {
         final b = getBucket(c.createdAt.toLocal());
         if (hourlyRev.containsKey(b)) {
            final double logged = loggedRegPaidMap[c.customerId] ?? 0.0;
            final double missing = (c.registrationFeePaidAmount - logged).clamp(0, double.infinity);
            hourlyRev[b] = (hourlyRev[b] ?? 0.0) + missing;
         }
      }

      final List<DateTime> sortedKeys = hourlyRev.keys.toList()
        ..sort((a, b) => a.compareTo(b));
        
      final List<ChartDataPoint> revenueChart = sortedKeys.map((dt) {
          final label = (filter == ReportFilter.daily)
              ? '${dt.hour.toString().padLeft(2, '0')}:00'
              : '${dt.day}/${dt.month}';
          return ChartDataPoint(label, hourlyRev[dt]!);
      }).toList();

      // ── PRODUCT BREAKDOWN ──────────────────────────────────────────────────
      final productBreakdownList = allProducts
          .where((p) => p.status == 'active')
          .map((prod) {
            final pid = prod.productId;
            final pSubs = activeSubsAtEnd.where((s) => s.productId == pid).toList();
            final pExpiring = expiringSoonSubs.where((s) => s.productId == pid).length;
            final pExpired = allSubscriptions.where((s) => s.productId == pid && s.endDate.toLocal().isBefore(rangeFrom)).length;

            return ProductReportEntry(
              productId: pid,
              productName: prod.name,
              activeCount: pSubs.length,
              expiringCount: pExpiring,
              expiredCount: pExpired,
            );
          })
          .toList();

      return Right(
        ReportEntity(
          totalCustomers: customersBeforeEnd.length,
          activeCustomers: activeCustomerIds.length,
          inactiveCustomers: (customersBeforeEnd.length - activeCustomerIds.length).clamp(0, 999999),
          activeSubscriptions: activeSubsAtEnd.length,
          expiringSoonSubscriptions: expiringSoonSubs.length,
          expiredSubscriptions: expiredCount,
          newJoiners: newCustomers.length,
          newSubscriptions: newSubs.length,
          registrationFeeCollected: totalRegRevenue,
          registrationFeePending: totalPendingRegBalance,
          totalPendingBalance: totalPendingSubBalance,
          subscriptionRevenueCollected: totalSubRevenue,
          totalRevenueCollected: totalSubRevenue + totalRegRevenue,
          revenueChartData: revenueChart,
          filter: filter,
          productBreakdown: productBreakdownList,
        ),
      );
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
