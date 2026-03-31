import 'package:csms/core/utils/date_utils.dart';
import 'package:csms/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:csms/features/reports/domain/entities/report_entity.dart';

/// Pure use case — derives all business report metrics from already-loaded
/// [DashboardLoaded] state. Accepts a [ReportFilter] to scope activity metrics.
class GetBusinessReport {
  ReportEntity call(DashboardLoaded state, {ReportFilter filter = ReportFilter.allTime}) {
    final now = DateTime.now();
    final customers = state.customers;
    final activeSubs = state.activeSubs;
    final expiringSoon = state.expiringSoon;
    final products = state.products;

    // ── Date range bounds ─────────────────────────────────────────────────────
    DateTime? from;
    switch (filter) {
      case ReportFilter.today:
        from = DateTime(now.year, now.month, now.day);
        break;
      case ReportFilter.thisMonth:
        from = DateTime(now.year, now.month, 1);
        break;
      case ReportFilter.allTime:
        from = null;
        break;
    }

    bool inRange(DateTime dt) {
      if (from == null) return true;
      return dt.toLocal().isAfter(from!.subtract(const Duration(seconds: 1)));
    }

    // ── Current State (live — not date-filtered) ──────────────────────────────
    final activeCustomers =
        customers.where((c) => c.status.toLowerCase() == 'active').length;
    final inactiveCustomers =
        customers.where((c) => c.status.toLowerCase() == 'inactive').length;

    // De-duplicate: pick latest sub per (customer, product)
    final Map<String, dynamic> latestSubMap = {};
    for (final sub in [...activeSubs, ...expiringSoon]) {
      final key = '${sub.customerId}_${sub.productId}';
      final existing = latestSubMap[key];
      if (existing == null || sub.endDate.isAfter(existing.endDate)) {
        latestSubMap[key] = sub;
      }
    }
    final uniqueSubs = latestSubMap.values.toList();
    final expiredCount =
        uniqueSubs.where((s) => AppDateUtils.calculateDaysLeft(s.endDate) < 0).length;
    final expiringSoonCount =
        expiringSoon.map((s) => '${s.customerId}_${s.productId}').toSet().length;
    final activeSubCount =
        activeSubs.map((s) => '${s.customerId}_${s.productId}').toSet().length;

    // ── Activity (date-filtered) ───────────────────────────────────────────────
    final filteredCustomers =
        customers.where((c) => inRange(c.createdAt.toLocal())).toList();

    final newJoiners = filteredCustomers.length;

    final newSubscriptions = activeSubs
        .where((s) => inRange(s.startDate.toLocal()))
        .map((s) => '${s.customerId}_${s.productId}')
        .toSet()
        .length;

    final filteredActiveSubs = activeSubs
        .where((s) => inRange(s.startDate.toLocal()))
        .toList();

    double regFeeCollected = 0.0;
    double regFeePending = 0.0;

    for (var c in filteredCustomers) {
      if (c.registrationFeeStatus.toLowerCase() == 'paid') {
        regFeeCollected += c.registrationFeeAmount;
      } else if (c.registrationFeeStatus.toLowerCase() == 'partial' || c.registrationFeeStatus.toLowerCase() == 'unpaid') {
        regFeePending += c.registrationFeeAmount;
      }
    }

    // Pending balance (subscription portion)
    final filteredUniqueSubs = uniqueSubs
        .where((s) => inRange(s.startDate.toLocal()))
        .toList();

    final pendingBalance = filteredUniqueSubs
        .fold<double>(0, (sum, s) => sum + (s.balanceAmount > 0 ? s.balanceAmount : 0));

    // ── Per-product breakdown ─────────────────────────────────────────────────
    final productBreakdown = products
        .where((p) => p.status == 'active')
        .map((product) {
          final pid = product.productId;
          final pActiveSubs = activeSubs.where((s) => s.productId == pid).toSet();
          final pExpiringSubs = expiringSoon.where((s) => s.productId == pid).toSet();
          final pExpired = pActiveSubs
              .where((s) => AppDateUtils.calculateDaysLeft(s.endDate) < 0)
              .length;
          final pExpiring = pExpiringSubs.length;
          final pActive = pActiveSubs.length - pExpired;

          return ProductReportEntry(
            productId: pid,
            productName: product.name,
            activeCount: pActive < 0 ? 0 : pActive,
            expiringCount: pExpiring,
            expiredCount: pExpired,
          );
        })
        .toList();

    return ReportEntity(
      totalCustomers: customers.length,
      activeCustomers: activeCustomers,
      inactiveCustomers: inactiveCustomers,
      activeSubscriptions: activeSubCount,
      expiringSoonSubscriptions: expiringSoonCount,
      expiredSubscriptions: expiredCount,
      newJoiners: newJoiners,
      newSubscriptions: newSubscriptions,
      registrationFeeCollected: regFeeCollected,
      registrationFeePending: regFeePending,
      totalPendingBalance: pendingBalance,
      filter: filter,
      productBreakdown: productBreakdown,
    );
  }
}
