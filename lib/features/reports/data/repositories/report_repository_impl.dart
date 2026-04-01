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
        _database.ref().child('customers').orderByChild('ownerId').equalTo(ownerId).get(),
        _database.ref().child('subscriptions').orderByChild('ownerId').equalTo(ownerId).get(),
        _database.ref().child('subscription_logs').child(shopId).get(),
        _database.ref().child('products').orderByChild('ownerId').equalTo(ownerId).get(),
      ]);
      
      final DataSnapshot customerSnap = results[0];
      final DataSnapshot subSnap = results[1];
      final DataSnapshot logSnap = results[2];
      final DataSnapshot productSnap = results[3];

      // ── Robust Parsing ───────────────────────────────────────────────────
      List<CustomerModel> _parseCustomers() {
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

      List<SubscriptionModel> _parseSubs() {
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

      List<SubscriptionLogModel> _parseLogs() {
        final list = <SubscriptionLogModel>[];
        if (logSnap.value != null) {
          final data = logSnap.value as Map<dynamic, dynamic>;
          data.forEach((key, val) {
            list.add(SubscriptionLogModel.fromJson(Map<String, dynamic>.from(val as Map), key.toString()));
          });
        }
        return list;
      }

      List<ProductModel> _parseProducts() {
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

      final allCustomers = _parseCustomers();
      final allSubscriptions = _parseSubs();
      final allLogs = _parseLogs();
      final allProducts = _parseProducts();

      // ── Helper: Date Range Check ──────────────────────────────────────────
      bool isInFilterRange(DateTime dt) {
        if (dt.year == 1970) return false; // Never count legacy fallback as "New Activity"
        final local = dt.toLocal();
        return !local.isBefore(rangeFrom) && !local.isAfter(rangeTo);
      }

      bool isBeforeFilterEnd(DateTime dt) {
        if (dt.year == 1970) return true; // Legacy records are always "Historical"
        return !dt.toLocal().isAfter(rangeTo);
      }

      // ── Metrics Generation ────────────────────────────────────────────────
      
      // Activity for the selected period
      final filteredLogs = allLogs.where((l) => isInFilterRange(l.createdAt)).toList();
      
      // For Subscriptions: If createdAt is missing (1970), fallback to startDate for activity matching
      final filteredSubs = allSubscriptions.where((s) {
        final dateToUse = (s.createdAt.year == 1970) ? s.startDate : s.createdAt;
        return isInFilterRange(dateToUse);
      }).toList();

      final filteredCusts = allCustomers.where((c) => isInFilterRange(c.createdAt)).toList();

      // New Joinees/Subs (Always trust actual object count over logs)
      final newJoiners = filteredCusts.length;
      final newSubsCount = filteredSubs.length;

      // REVENUE CALCULATION (Hybrid Approach)
      double logSubRevenue = 0.0;
      double logRegRevenue = 0.0;
      for (var l in filteredLogs) {
        logSubRevenue += (l.paidAmount ?? 0.0);
        logRegRevenue += (l.registrationFeePaid ?? 0.0);
      }

      double subFallbackRevenue = 0.0;
      double regFallbackRevenue = 0.0;
      for (var s in filteredSubs) {
        subFallbackRevenue += s.paidAmount;
        regFallbackRevenue += s.registrationFeePaid;
      }
      
      for (var c in filteredCusts) {
        // Fallback for cases where registrationFeePaid wasn't captured in logs/subs
        // but only if it's not already counted via regFallbackRevenue (logs/subs are more accurate for timeline)
        // However, for the total revenue metrics, we want to be as inclusive as possible.
        // We'll trust the customer record as a secondary fallback.
        if (logRegRevenue <= 0 && regFallbackRevenue <= 0) {
           regFallbackRevenue += c.registrationFeePaidAmount;
        }
      }

      // Final Revenue Logic: Take the maximum of logs or explicit source models 
      // to ensure no transaction drops.
      final totalSubRevenue = logSubRevenue > subFallbackRevenue ? logSubRevenue : subFallbackRevenue;
      final totalRegRevenue = logRegRevenue > regFallbackRevenue ? logRegRevenue : regFallbackRevenue;

      // Historical Status (Cards)
      final historicalCusts = allCustomers.where((c) => isBeforeFilterEnd(c.createdAt)).toList();
      final historicalSubs = allSubscriptions.where((s) {
        final start = s.startDate.toLocal();
        final end = s.endDate.toLocal();
        return !start.isAfter(rangeTo) && !end.isBefore(rangeFrom);
      }).toList();

      final totalCustCount = historicalCusts.length;
      final activeCustCount = historicalSubs.map((s) => s.customerId).toSet().length;
      final activeSubCount = historicalSubs.length;
      final expiredCount = historicalSubs.where((s) => s.endDate.toLocal().isBefore(rangeFrom)).length;
      final expiringSoonCount = historicalSubs.where((s) {
        final days = s.endDate.toLocal().difference(rangeTo).inDays;
        return days >= 0 && days <= 7;
      }).length;

      // Current Pending (Always from unique latest subs)
      final Map<String, SubscriptionModel> latestPerPlan = {};
      for (var s in allSubscriptions) {
        final key = '${s.customerId}_${s.productId}';
        final existing = latestPerPlan[key];
        if (existing == null || s.endDate.isAfter(existing.endDate)) {
          latestPerPlan[key] = s;
        }
      }
      final pendingBalanceTotal = latestPerPlan.values.fold<double>(0.0, (sum, s) => sum + (s.balanceAmount > 0 ? s.balanceAmount : 0));
      final pendingRegTotal = allCustomers.fold<double>(0.0, (sum, c) {
        final double due = (c.registrationFeeAmount - c.registrationFeePaidAmount).clamp(0, double.infinity);
        return sum + due;
      });

      // Chart Data
      final Map<DateTime, double> hourlyRev = {};

      // 1. Initialize with 0s for a full timeline (so the chart looks professional)
      if (filter == ReportFilter.daily) {
        for (int h = 0; h < 24; h++) {
          hourlyRev[DateTime(ref.year, ref.month, ref.day, h)] = 0.0;
        }
      } else {
        final lastDayOfMonth = DateTime(ref.year, ref.month + 1, 0).day;
        for (int d = 1; d <= lastDayOfMonth; d++) {
          hourlyRev[DateTime(ref.year, ref.month, d)] = 0.0;
        }
      }

      DateTime getBucket(DateTime dt) => (filter == ReportFilter.daily)
          ? DateTime(dt.year, dt.month, dt.day, dt.hour)
          : DateTime(dt.year, dt.month, dt.day);

      // 2. Populate chart (Hybrid approach matching total revenue logic)
      // Accumulate from logs first
      for (var l in filteredLogs) {
        final total = (l.paidAmount ?? 0.0) + (l.registrationFeePaid ?? 0.0);
        if (total > 0) {
          final b = getBucket(l.createdAt.toLocal());
          if (hourlyRev.containsKey(b)) {
            hourlyRev[b] = (hourlyRev[b] ?? 0.0) + total;
          }
        }
      }

      // Fallback to subs for any gaps
      for (var s in filteredSubs) {
        final total = s.paidAmount + s.registrationFeePaid;
        if (total > 0) {
          final b = getBucket(s.createdAt.toLocal());
          if (hourlyRev.containsKey(b) && hourlyRev[b] == 0) {
            hourlyRev[b] = total;
          }
        }
      }

      final sortedBuckets = hourlyRev.keys.toList()..sort();
      final List<ChartDataPoint> revenueChart = sortedBuckets.map((dt) {
        final label = (filter == ReportFilter.daily)
            ? '${dt.hour.toString().padLeft(2, '0')}:00'
            : '${dt.day}/${dt.month}';
        return ChartDataPoint(label, hourlyRev[dt]!);
      }).toList();

      // Product Breakdown
      final productBreakdownList = allProducts.where((p) => p.status == 'active').map((prod) {
        final pid = prod.productId;
        final pSubs = historicalSubs.where((s) => s.productId == pid).toList();
        final pExpired = pSubs.where((s) => s.endDate.toLocal().isBefore(rangeFrom)).length;
        final pExpiring = pSubs.where((s) {
          final days = s.endDate.toLocal().difference(rangeTo).inDays;
          return days >= 0 && days <= 7;
        }).length;
        return ProductReportEntry(
          productId: pid,
          productName: prod.name,
          activeCount: pSubs.length - pExpired,
          expiringCount: pExpiring,
          expiredCount: pExpired,
        );
      }).toList();

      return Right(ReportEntity(
        totalCustomers: totalCustCount,
        activeCustomers: activeCustCount,
        inactiveCustomers: totalCustCount - activeCustCount,
        activeSubscriptions: activeSubCount,
        expiringSoonSubscriptions: expiringSoonCount,
        expiredSubscriptions: expiredCount,
        newJoiners: newJoiners,
        newSubscriptions: newSubsCount,
        registrationFeeCollected: totalRegRevenue,
        registrationFeePending: pendingRegTotal,
        totalPendingBalance: pendingBalanceTotal,
        subscriptionRevenueCollected: totalSubRevenue,
        totalRevenueCollected: totalSubRevenue + totalRegRevenue,
        revenueChartData: revenueChart,
        filter: filter,
        productBreakdown: productBreakdownList,
      ));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
