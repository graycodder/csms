import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:csms/core/theme/app_colors.dart';
import 'package:csms/core/utils/terminology_helper.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:csms/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:csms/features/reports/domain/entities/report_entity.dart';
import 'package:csms/features/reports/presentation/bloc/report_bloc.dart';
import 'package:intl/intl.dart';
import 'package:csms/core/utils/loading_overlay.dart';

class DailyReportView extends StatefulWidget {
  const DailyReportView({super.key});

  @override
  State<DailyReportView> createState() => _DailyReportViewState();
}

class _DailyReportViewState extends State<DailyReportView> {
  DateTime _referenceDate = DateTime.now();
  DashboardLoaded? _lastDashState;

  void _triggerFilter(DashboardLoaded dashState) {
    context.read<ReportBloc>().add(
      ChangeReportFilter(
        shopId: dashState.shop.shopId,
        ownerId: dashState.shop.ownerId,
        filter: ReportFilter.daily,
        referenceDate: _referenceDate,
      ),
    );
  }

  Future<void> _selectDate(
    BuildContext context,
    DashboardLoaded dashState,
  ) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _referenceDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textDark,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _referenceDate) {
      setState(() {
        _referenceDate = picked;
      });
      _triggerFilter(dashState);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardBloc, DashboardState>(
      builder: (context, dashState) {
        if (dashState is DashboardLoaded) {
          if (_lastDashState != dashState) {
            _lastDashState = dashState;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _triggerFilter(dashState);
            });
          }
          final term = TerminologyHelper.getTerminology(
            dashState.shop.category,
          );

          return BlocListener<ReportBloc, ReportState>(
            listener: (context, reportState) {
              if (reportState is ReportLoading) {
                LoadingOverlayHelper.show(context);
              } else {
                LoadingOverlayHelper.hide();
              }
            },
            child: BlocBuilder<ReportBloc, ReportState>(
              builder: (context, reportState) {
                if (reportState is ReportLoaded) {
                  return _buildContent(
                    context,
                    reportState.report,
                    term,
                    dashState,
                  );
                } else if (reportState is ReportLoading &&
                    reportState.report != null) {
                  // While loading, if we have cached data, show it.
                  // The LoadingOverlayHelper will handle the spinner.
                  return _buildContent(
                    context,
                    reportState.report!,
                    term,
                    dashState,
                  );
                } else if (reportState is ReportError) {
                  return Center(child: Text('Error: ${reportState.message}'));
                }
                return const SizedBox.shrink();
              },
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildContent(
    BuildContext context,
    ReportEntity report,
    BusinessTerminology term,
    DashboardLoaded dashState,
  ) {
    return Container(
      color: Colors.grey[100],
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildReportTitleSection(dashState),
            SizedBox(height: 16.h),
            _buildRevenueHeroCard(report, term),
            SizedBox(height: 10.h),
            _buildPaymentModeCard(report),
            SizedBox(height: 10.h),
            _buildRevenueChart(report),
            SizedBox(height: 24.h),
            Text(
              'Member Activity',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            SizedBox(height: 12.h),
            _buildActivityGrid(report, term),
            SizedBox(height: 24.h),
            Text(
              '${term.planLabel} Breakdown',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            SizedBox(height: 10.h),
            _buildPlansBreakdownList(report),
            SizedBox(height: 32.h),
          ],
        ),
      ),
    );
  }

  Widget _buildReportTitleSection(DashboardLoaded dashState) {
    final dateStr = DateFormat('MMMM d, yyyy').format(_referenceDate);

    return GestureDetector(
      onTap: () => _selectDate(context, dashState),
      child: Row(
        children: [
          Text(
            'Day Report: ',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          Icon(
            Icons.calendar_month_outlined,
            size: 18.sp,
            color: AppColors.textDark,
          ),
          SizedBox(width: 8.w),
          Text(
            dateStr,
            style: TextStyle(
              fontSize: 16.sp,
              color: AppColors.textDark,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueHeroCard(ReportEntity report, BusinessTerminology term) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Revenue Collected',
                    style: TextStyle(
                      color: AppColors.textDark.withOpacity(0.8),
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    '₹${report.totalRevenueCollected.toStringAsFixed(0)}',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 24.sp,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1,
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 24.h),
          Row(
            children: [
              Expanded(
                child: _buildRevenueGridItem(
                  'Subscription:',
                  '₹${report.subscriptionRevenueCollected.toStringAsFixed(0)}',
                  Icons.autorenew,
                  const Color(0xFFE0F7FA),
                  const Color(0xFF006064),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _buildRevenueGridItem(
                  'Reg. Fees',
                  '₹${report.registrationFeeCollected.toStringAsFixed(0)}',
                  Icons.badge_outlined,
                  const Color(0xFFE0F2F1),
                  const Color(0xFF004D40),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: _buildRevenueGridItem(
                  'Pending Balance',
                  '₹${report.totalPendingBalance.toStringAsFixed(0)}',
                  Icons.access_time,
                  const Color(0xFFFFF3E0),
                  const Color(0xFFE65100),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _buildRevenueGridItem(
                  'Pending Reg. Fees',
                  '₹${report.registrationFeePending.toStringAsFixed(0)}',
                  Icons.access_time,
                  const Color(0xFFFFF3E0),
                  const Color(0xFFE65100),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueGridItem(
    String label,
    String value,
    IconData icon,
    Color bgColor,
    Color iconColor,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20.sp, color: iconColor),
          SizedBox(width: 8.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: AppColors.textDark.withOpacity(0.8),
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  value,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityGrid(ReportEntity report, BusinessTerminology term) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12.h,
      crossAxisSpacing: 12.w,
      childAspectRatio: 1.6,
      children: [
        _buildActivityCard(
          'New ${term.customerLabel}s',
          report.newJoiners.toString(),
          Icons.person,
          const Color(0xFFE0F7FA),
          const Color(0xFF00838F),
        ),
        _buildActivityCard(
          'New ${term.subscriptionLabel}s',
          report.newSubscriptions.toString(),
          Icons.edit_document,
          const Color(0xFFE0F7FA),
          const Color(0xFF00838F),
        ),
        _buildActivityCard(
          'Active Members',
          report.activeCustomers.toString(),
          Icons.group,
          const Color(0xFFE0F7FA),
          const Color(0xFF00838F),
        ),
        _buildActivityCard(
          'Inactive Members',
          report.inactiveCustomers.toString(),
          Icons.group_off,
          const Color(0xFFE0F7FA),
          const Color(0xFF00838F),
        ),
        _buildActivityCard(
          'Expiring Soon',
          report.expiringSoonSubscriptions.toString(),
          Icons.notifications_active,
          const Color(0xFFFFF3E0),
          const Color(0xFFE65100),
        ),
        _buildActivityCard(
          'Expired',
          report.expiredSubscriptions.toString(),
          Icons.notifications_off,
          const Color(0xFFFFF3E0),
          const Color(0xFFE65100),
        ),
      ],
    );
  }

  Widget _buildActivityCard(
    String label,
    String value,
    IconData icon,
    Color bg,
    Color iconColor, {
    String? subtitle,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(10.r),
            decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
            child: Icon(icon, size: 20.sp, color: iconColor),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2.h),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                  ),
                ),
                if (subtitle != null) ...[
                  SizedBox(height: 2.h),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 8.sp,
                      color: AppColors.textLight,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Payment Mode Breakdown Card ─────────────────────────────────────────
  Widget _buildPaymentModeCard(ReportEntity report) {
    final modes = [
      ('Cash', const Color(0xFF43A047), const Color(0xFFE8F5E9)),
      ('UPI', const Color(0xFF1E88E5), const Color(0xFFE3F2FD)),
      ('Card', const Color(0xFF8E24AA), const Color(0xFFF3E5F5)),
      ('Bank Transfer', const Color(0xFF00897B), const Color(0xFFE0F2F1)),
      ('Other', const Color(0xFF757575), const Color(0xFFF5F5F5)),
    ];

    final total = report.paymentModeBreakdown.values.fold(
      0.0,
      (s, v) => s + v,
    );

    final hasData = total > 0;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Collection by Payment Mode',
            style: TextStyle(
              fontSize: 15.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          SizedBox(height: 14.h),
          if (hasData) ...
            [
              // Stacked progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(8.r),
                child: Row(
                  children: modes.map((m) {
                    final val = report.paymentModeBreakdown[m.$1] ?? 0.0;
                    final frac = val / total;
                    if (frac <= 0) return const SizedBox.shrink();
                    return Flexible(
                      flex: (frac * 1000).round(),
                      child: Container(
                        height: 10.h,
                        color: m.$2,
                      ),
                    );
                  }).toList(),
                ),
              ),
              SizedBox(height: 16.h),
            ]
          else
            Container(
              height: 10.h,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
          SizedBox(height: 16.h),
          ...modes.map((m) {
            final val = report.paymentModeBreakdown[m.$1] ?? 0.0;
            final pct = hasData ? (val / total * 100) : 0.0;
            return Padding(
              padding: EdgeInsets.only(bottom: 10.h),
              child: Row(
                children: [
                  Container(
                    width: 10.w,
                    height: 10.h,
                    decoration: BoxDecoration(
                      color: m.$2,
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      m.$1,
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                  Text(
                    '₹${val.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  SizedBox(
                    width: 42.w,
                    child: Text(
                      '${pct.toStringAsFixed(1)}%',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: AppColors.textLight,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── Revenue Bar Chart ───────────────────────────────────────────────────
  Widget _buildRevenueChart(ReportEntity report) {
    if (report.revenueChartData.isEmpty) return const SizedBox.shrink();

    final nonZeroData = report.revenueChartData.where((p) => p.value > 0);
    final double maxVal = nonZeroData.isEmpty
        ? 100
        : nonZeroData.fold(0.0, (m, p) => p.value > m ? p.value : m);
    final double yLimit = (maxVal * 1.25).ceilToDouble();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Revenue by Hour',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            'Tap a bar to see the amount',
            style: TextStyle(fontSize: 11.sp, color: AppColors.textLight),
          ),
          SizedBox(height: 16.h),
          SizedBox(
            height: 200.h,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: yLimit,
                minY: 0,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final label =
                          report.revenueChartData[group.x.toInt()].label;
                      return BarTooltipItem(
                        '₹${rod.toY.toInt()}\n$label',
                        TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 11.sp,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (val, meta) {
                        final idx = val.toInt();
                        if (idx < 0 ||
                            idx >= report.revenueChartData.length) {
                          return const SizedBox.shrink();
                        }
                        // Only show every 4th label to avoid crowding
                        if (report.revenueChartData.length > 8 &&
                            idx % 4 != 0) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: EdgeInsets.only(top: 6.h),
                          child: Text(
                            report.revenueChartData[idx].label,
                            style: TextStyle(
                              color: AppColors.textLight,
                              fontSize: 9.sp,
                            ),
                          ),
                        );
                      },
                      reservedSize: 28.h,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (val, meta) {
                        if (val == 0) return const SizedBox.shrink();
                        return Text(
                          '₹${val.toInt()}',
                          style: TextStyle(
                            color: AppColors.textLight,
                            fontSize: 9.sp,
                          ),
                        );
                      },
                      reservedSize: 45.w,
                    ),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => const FlLine(
                    color: Color(0xFFF3F4F6),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: report.revenueChartData
                    .asMap()
                    .entries
                    .map(
                      (e) => BarChartGroupData(
                        x: e.key,
                        barRods: [
                          BarChartRodData(
                            toY: e.value.value,
                            width: report.revenueChartData.length > 16
                                ? 6.w
                                : 10.w,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(4.r),
                              topRight: Radius.circular(4.r),
                            ),
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                const Color(0xFF29B6F6),
                                const Color(0xFF0288D1),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlansBreakdownList(ReportEntity report) {
    if (report.productBreakdown.isEmpty) {
      return Container(
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          'No plans found.',
          style: TextStyle(fontSize: 14.sp, color: AppColors.textLight),
        ),
      );
    }
    return ListView.separated(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: report.productBreakdown.length,
      separatorBuilder: (context, index) => SizedBox(height: 12.h),
      itemBuilder: (context, index) {
        final plan = report.productBreakdown[index];
        return Container(
          padding: EdgeInsets.all(16.r),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                plan.productName,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              SizedBox(height: 16.h),
              Row(
                children: [
                  Expanded(
                    child: _buildPlanStat(
                      'Active',
                      plan.activeCount,
                      const Color(0xFF00838F),
                      const Color(0xFFE0F7FA),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: _buildPlanStat(
                      'Expiring',
                      plan.expiringCount,
                      const Color(0xFFE65100),
                      const Color(0xFFFFF3E0),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: _buildPlanStat(
                      'Expired',
                      plan.expiredCount,
                      const Color(0xFFC62828),
                      const Color(0xFFFFEBEE),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPlanStat(
    String label,
    int value,
    Color textColor,
    Color bgColor,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12.h),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        children: [
          Text(
            value.toString(),
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w900,
              color: textColor,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.sp,
              fontWeight: FontWeight.w600,
              color: textColor.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }
}
