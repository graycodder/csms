import 'package:equatable/equatable.dart';

enum ReportFilter { today, thisMonth, allTime }

extension ReportFilterLabel on ReportFilter {
  String get label {
    switch (this) {
      case ReportFilter.today:
        return 'Today';
      case ReportFilter.thisMonth:
        return 'This Month';
      case ReportFilter.allTime:
        return 'All Time';
    }
  }
}

/// Holds all computed business performance metrics.
/// Computed purely from existing DashboardLoaded data — no new Firebase reads.
class ReportEntity extends Equatable {
  // ── Current State (always live, not date-filtered) ─────────────────────────
  final int totalCustomers;
  final int activeCustomers;
  final int inactiveCustomers;
  final int activeSubscriptions;
  final int expiringSoonSubscriptions;
  final int expiredSubscriptions;

  // ── Activity (date-filtered) ───────────────────────────────────────────────
  final int newJoiners;
  final int newSubscriptions;
  final double registrationFeeCollected;
  final double registrationFeePending;
  final double totalPendingBalance;

  // ── Applied filter ─────────────────────────────────────────────────────────
  final ReportFilter filter;

  // ── Per-product breakdown ──────────────────────────────────────────────────
  final List<ProductReportEntry> productBreakdown;

  const ReportEntity({
    required this.totalCustomers,
    required this.activeCustomers,
    required this.inactiveCustomers,
    required this.activeSubscriptions,
    required this.expiringSoonSubscriptions,
    required this.expiredSubscriptions,
    required this.newJoiners,
    required this.newSubscriptions,
    required this.registrationFeeCollected,
    required this.registrationFeePending,
    required this.totalPendingBalance,
    required this.filter,
    required this.productBreakdown,
  });

  @override
  List<Object?> get props => [
        totalCustomers,
        activeCustomers,
        inactiveCustomers,
        activeSubscriptions,
        expiringSoonSubscriptions,
        expiredSubscriptions,
        newJoiners,
        newSubscriptions,
        registrationFeeCollected,
        registrationFeePending,
        totalPendingBalance,
        filter,
        productBreakdown,
      ];
}

class ProductReportEntry extends Equatable {
  final String productId;
  final String productName;
  final int activeCount;
  final int expiringCount;
  final int expiredCount;

  const ProductReportEntry({
    required this.productId,
    required this.productName,
    required this.activeCount,
    required this.expiringCount,
    required this.expiredCount,
  });

  @override
  List<Object?> get props =>
      [productId, productName, activeCount, expiringCount, expiredCount];
}
