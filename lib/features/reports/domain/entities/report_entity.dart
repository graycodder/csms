import 'package:equatable/equatable.dart';

enum ReportFilter { daily, monthly }

extension ReportFilterLabel on ReportFilter {
  String get label {
    switch (this) {
      case ReportFilter.daily:
        return 'Daily Report';
      case ReportFilter.monthly:
        return 'Monthly Report';
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
  // ── Activity (date-filtered) ───────────────────────────────────────────────
  final int newJoiners;
  final int newSubscriptions;
  final double registrationFeeCollected;
  final double registrationFeePending;
  final double totalPendingBalance;
  final double subscriptionRevenueCollected;
  final double totalRevenueCollected;
  final List<ChartDataPoint> revenueChartData;

  // ── Applied filter ─────────────────────────────────────────────────────────
  final ReportFilter filter;
  final DateTime? customStartDate;
  final DateTime? customEndDate;

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
    required this.subscriptionRevenueCollected,
    required this.totalRevenueCollected,
    required this.revenueChartData,
    required this.filter,
    this.customStartDate,
    this.customEndDate,
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
    subscriptionRevenueCollected,
    totalRevenueCollected,
    revenueChartData,
    filter,
    customStartDate,
    customEndDate,
    productBreakdown,
  ];
}

class ChartDataPoint extends Equatable {
  final String label;
  final double value;

  const ChartDataPoint(this.label, this.value);

  @override
  List<Object?> get props => [label, value];
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
  List<Object?> get props => [
    productId,
    productName,
    activeCount,
    expiringCount,
    expiredCount,
  ];
}
