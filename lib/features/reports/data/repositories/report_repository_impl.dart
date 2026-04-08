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
      // NOTE: Rules only permit orderByChild('ownerId') at the collection level.
      // We fetch by ownerId and then filter by shopId in Dart.
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
        _database.ref().child('shops').child(shopId).get(),
      ]);

      final DataSnapshot customerSnap = results[0];
      final DataSnapshot subSnap = results[1];
      final DataSnapshot logSnap = results[2];
      final DataSnapshot productSnap = results[3];
      final DataSnapshot shopSnap = results[4];

      // ── Shop Settings (for threshold alignment) ──────────────────────────
      int expiringThreshold = 30; // Dashboard default
      if (shopSnap.exists) {
        final shopData = Map<String, dynamic>.from(shopSnap.value as Map);
        final settings = shopData['settings'] as Map?;
        if (settings != null) {
          expiringThreshold = settings['expiredDaysBefore'] ?? 30;
        }
      }

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
      final List<SubscriptionLogModel> periodLogs = allLogs
          .where(
            (l) =>
                l.createdAt.toLocal().isAfter(
                  rangeFrom.subtract(const Duration(milliseconds: 1)),
                ) &&
                l.createdAt.toLocal().isBefore(
                  rangeTo.add(const Duration(milliseconds: 1)),
                ),
          )
          .toList();

      final List<SubscriptionModel> newSubs = allSubscriptions.where((s) {
        final dateToUse = s.createdAt.year == 1970 ? s.startDate : s.createdAt;
        final local = dateToUse.toLocal();
        return !local.isBefore(rangeFrom) && !local.isAfter(rangeTo);
      }).toList();

      final List<CustomerModel> newCustomers = allCustomers.where((c) {
        final local = c.createdAt.toLocal();
        return !local.isBefore(rangeFrom) && !local.isAfter(rangeTo);
      }).toList();

      // ── REVENUE & PAYMENT MODE CALCULATION ─────────────────────────────────
      double totalSubRevenue = 0.0;
      double totalRegRevenue = 0.0;
      final Map<String, double> paymentModeBreakdown = {};
      final Map<String, double> loggedSubPaidMap = {}; // subscriptionId -> sum

      // 1. Sum only subscription payments from logs in the period
      for (var l in periodLogs) {
        if (l.action == 'payment' ||
            l.action == 'create' ||
            l.action == 'renew') {
          final double sPaid = l.paidAmount ?? 0.0;

          totalSubRevenue += sPaid;

          if (l.subscriptionId != null) {
            loggedSubPaidMap[l.subscriptionId!] =
                (loggedSubPaidMap[l.subscriptionId!] ?? 0.0) + sPaid;
          }

          if (sPaid != 0) {
            final mode = _normaliseMode(l.paymentMode);
            paymentModeBreakdown[mode] =
                (paymentModeBreakdown[mode] ?? 0.0) + sPaid;
          }
        }
      }

      // 2. Fallback for Subscriptions: Add missing from logs
      double missingSubRevenue = 0.0;
      for (var s in newSubs) {
        final double logged = loggedSubPaidMap[s.subscriptionId] ?? 0.0;
        final double missing = (s.paidAmount - logged).clamp(
          0,
          double.infinity,
        );
        missingSubRevenue += missing;
      }
      totalSubRevenue += missingSubRevenue;

      // 3. Fallback/Other assignment
      if (missingSubRevenue > 0) {
        final modeOther = _normaliseMode('Other');
        paymentModeBreakdown[modeOther] =
            (paymentModeBreakdown[modeOther] ?? 0.0) + missingSubRevenue;
      }

      // 3. Registration Fee Collected: Calculate purely from Customers Collection 
      // (Registration fees are tied to customers joined in this period)
      for (var c in newCustomers) {
        if (c.registrationFeePaidAmount > 0) {
          totalRegRevenue += c.registrationFeePaidAmount;
          final mode = _normaliseMode(c.registrationFeePaymentMode);
          paymentModeBreakdown[mode] =
              (paymentModeBreakdown[mode] ?? 0.0) + c.registrationFeePaidAmount;
        }
      }

      // ── HISTORICAL STATUS: Snapshot as of rangeTo ────────────────────────
      // 1. All customers created before or at rangeTo
      final customersInScope = allCustomers
          .where((c) => !c.createdAt.toLocal().isAfter(rangeTo))
          .toList();

      // 2. Customers currently marked as 'active' (case-insensitive)
      final activeStatusCustomers = customersInScope
          .where((c) => c.status.toLowerCase() == 'active')
          .toList();
      final activeStatusCustomerIds = activeStatusCustomers
          .map((c) => c.customerId)
          .toSet();

      // 3. Subscription pools (Snapshot as of rangeTo)
      // Any subscription with status == 'active' is considered a member's current plan pool
      final activeStatusSubs = allSubscriptions.where((s) {
        final isStatusActive = s.status.toLowerCase() == 'active';
        // Member must also be an 'active' status customer
        return isStatusActive && activeStatusCustomerIds.contains(s.customerId);
      }).toList();

      // CATEGORIZE THE POOL:
      // Active: Plan is current (or starts in future)
      final activeSubsAtEnd = activeStatusSubs.where((s) {
        return !s.endDate.toLocal().isBefore(rangeTo);
      }).toList();

      // Expired: Plan status is 'active' but date is in the past
      final expiredSubsAtEnd = activeStatusSubs.where((s) {
        return s.endDate.toLocal().isBefore(rangeTo);
      }).toList();

      // Expiring Soon: Active plans ending in the next X days from rangeTo
      // Matches Dashboard logic (threshold from shop settings)
      final expiringSoonSubs = activeSubsAtEnd.where((s) {
        final days = s.endDate.toLocal().difference(rangeTo).inDays;
        return days >= 0 && days <= expiringThreshold;
      }).toList();

      // 4. Counts
      final activeCount = customersInScope
          .where((c) => c.status.toLowerCase() == 'active')
          .length;
      final inactiveCount = customersInScope
          .where((c) => c.status.toLowerCase() == 'inactive')
          .length;
      final expiredCount = expiredSubsAtEnd.length;

      // ── PENDING CALCULATIONS: Current live state ──────────────────────────
      final Map<String, SubscriptionModel> latestPerPlan = {};
      for (var s in allSubscriptions) {
        final key = '${s.customerId}_${s.productId}';
        final existing = latestPerPlan[key];
        if (existing == null || s.endDate.isAfter(existing.endDate)) {
          latestPerPlan[key] = s;
        }
      }
      final double totalPendingSubBalance = latestPerPlan.values.fold(
        0.0,
        (sum, s) => sum + (s.balanceAmount > 0 ? s.balanceAmount : 0),
      );

      final double totalPendingRegBalance = customersInScope.fold(
        0.0,
        (sum, c) =>
            sum +
            (c.registrationFeeAmount - c.registrationFeePaidAmount).clamp(
              0,
              double.infinity,
            ),
      );

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

      // Add subscription payments from logs
      for (var l in periodLogs) {
        if (l.action == 'payment' ||
            l.action == 'create' ||
            l.action == 'renew') {
          final double sPaid = l.paidAmount ?? 0.0;

          if (sPaid != 0) {
            final b = getBucket(l.createdAt.toLocal());
            if (hourlyRev.containsKey(b)) {
              hourlyRev[b] = (hourlyRev[b] ?? 0.0) + sPaid;
            }
          }
        }
      }

      // Add missing subscription revenues
      for (var s in newSubs) {
        final double logged = loggedSubPaidMap[s.subscriptionId] ?? 0.0;
        final double missing = (s.paidAmount - logged).clamp(
          0,
          double.infinity,
        );
        if (missing > 0) {
          final b = getBucket(s.createdAt.toLocal());
          if (hourlyRev.containsKey(b)) {
            hourlyRev[b] = (hourlyRev[b] ?? 0.0) + missing;
          }
        }
      }

      // Add Registration fees from Customers collection
      for (var c in newCustomers) {
        if (c.registrationFeePaidAmount > 0) {
          final b = getBucket(c.createdAt.toLocal());
          if (hourlyRev.containsKey(b)) {
            hourlyRev[b] = (hourlyRev[b] ?? 0.0) + c.registrationFeePaidAmount;
          }
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
          .where((p) => p.status.toLowerCase() == 'active')
          .map((prod) {
            final pid = prod.productId;
            final pActive = activeSubsAtEnd
                .where((s) => s.productId == pid)
                .length;
            final pExpiring = expiringSoonSubs
                .where((s) => s.productId == pid)
                .length;
            final pExpired = expiredSubsAtEnd
                .where((s) => s.productId == pid)
                .length;

            return ProductReportEntry(
              productId: pid,
              productName: prod.name,
              activeCount: pActive,
              expiringCount: pExpiring,
              expiredCount: pExpired,
            );
          })
          .toList();

      return Right(
        ReportEntity(
          totalCustomers: customersInScope.length,
          activeCustomers: activeCount,
          inactiveCustomers: inactiveCount.clamp(0, 999999),
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
          paymentModeBreakdown: paymentModeBreakdown,
        ),
      );
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  static String _normaliseMode(String? raw) {
    if (raw == null || raw.isEmpty) return 'Other';
    final normalized = raw.trim().toLowerCase();
    switch (normalized) {
      case 'cash':
        return 'Cash';
      case 'upi':
        return 'UPI';
      case 'card':
        return 'Card';
      case 'bank transfer':
        return 'Bank Transfer';
      default:
        return raw.trim();
    }
  }
}
