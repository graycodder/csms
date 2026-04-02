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
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildReportTitleSection(dashState),
          SizedBox(height: 24.h),
          _buildRevenueHeroCard(report, term),
          SizedBox(height: 24.h),
          _buildSectionTitle('Trends', Icons.trending_up),
          SizedBox(height: 16.h),
          _buildRevenueChart(report),
          SizedBox(height: 24.h),
          _buildSectionTitle('${term.customerLabel} Activity', Icons.people),
          SizedBox(height: 12.h),
          _buildActivityGrid(report, term),
          SizedBox(height: 24.h),
          _buildSectionTitle('${term.planLabel} Breakdown', Icons.inventory_2),
          SizedBox(height: 12.h),
          _buildProductBreakdown(report, term),
          SizedBox(height: 32.h),
        ],
      ),
    );
  }

  Widget _buildReportTitleSection(DashboardLoaded dashState) {
    final title = 'End of Day Report';
    final dateStr = DateFormat('EEEE, d MMMM yyyy').format(_referenceDate);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 22.sp,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        GestureDetector(
          onTap: () => _selectDate(context, dashState),
          child: Row(
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: 14.sp,
                color: AppColors.textLight,
              ),
              SizedBox(width: 6.w),
              Text(
                dateStr,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: AppColors.textLight,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(width: 4.w),
              Icon(
                Icons.arrow_drop_down,
                size: 16.sp,
                color: AppColors.textLight,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRevenueHeroCard(ReportEntity report, BusinessTerminology term) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(24.r),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.8)],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total Revenue Collected',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            '₹${report.totalRevenueCollected.toStringAsFixed(0)}',
            style: TextStyle(
              color: Colors.white,
              fontSize: 32.sp,
              fontWeight: FontWeight.w900,
              letterSpacing: -1,
            ),
          ),
          SizedBox(height: 20.h),
          Row(
            children: [
              Expanded(
                child: _buildRevenueMiniStat(
                  'Subscription',
                  report.subscriptionRevenueCollected,
                ),
              ),
              Spacer(),
              Expanded(
                child: _buildRevenueMiniStat(
                  'Reg. Fees',
                  report.registrationFeeCollected,
                ),
              ),
            ],
          ),
          Divider(color: Colors.white.withValues(alpha: 0.2), height: 32.h),
          Row(
            children: [
              Expanded(
                child: _buildRevenueMiniStat(
                  'Pending Balance',
                  report.totalPendingBalance,
                  isLight: true,
                ),
              ),
              Spacer(),
              Expanded(
                child: _buildRevenueMiniStat(
                  'Pending Reg.',
                  report.registrationFeePending,
                  isLight: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueMiniStat(
    String label,
    double value, {
    bool isLight = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: isLight ? 0.6 : 0.8),
            fontSize: 11.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          '₹${value.toStringAsFixed(0)}',
          style: TextStyle(
            color: Colors.white,
            fontSize: 15.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildActivityGrid(ReportEntity report, BusinessTerminology term) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12.h,
      crossAxisSpacing: 12.w,
      childAspectRatio: 1.6,
      children: [
        _buildActivityCard(
          'New ${term.customerLabel}s',
          report.newJoiners.toString(),
          Icons.person_add_outlined,
          const Color(0xFFE0F2FE),
          const Color(0xFF0369A1),
        ),
        _buildActivityCard(
          'New ${term.subscriptionLabel}s',
          report.newSubscriptions.toString(),
          Icons.card_membership_outlined,
          const Color(0xFFF0FDF4),
          const Color(0xFF15803D),
        ),
        _buildActivityCard(
          'Active ${term.subscriptionLabel}s',
          report.activeSubscriptions.toString(),
          Icons.check_circle_outline,
          const Color(0xFFFDF2F8),
          const Color(0xFFBE185D),
        ),
        _buildActivityCard(
          'Expiring Soon',
          report.expiringSoonSubscriptions.toString(),
          Icons.timer_outlined,
          const Color(0xFFFFF7ED),
          const Color(0xFFC2410C),
        ),
      ],
    );
  }

  Widget _buildActivityCard(
    String label,
    String value,
    IconData icon,
    Color bg,
    Color iconColor,
  ) {
    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFF3F4F6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.all(6.r),
                decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
                child: Icon(icon, size: 16.sp, color: iconColor),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
              color: AppColors.textLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductBreakdown(ReportEntity report, BusinessTerminology term) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: const Color(0xFFF3F4F6)),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: report.productBreakdown.length,
        separatorBuilder: (_, __) =>
            const Divider(height: 1, color: Color(0xFFF3F4F6)),
        itemBuilder: (context, index) {
          final entry = report.productBreakdown[index];
          return Padding(
            padding: EdgeInsets.all(16.r),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.productName,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        'Total Users For this Period',
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: AppColors.textLight,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildProductStat(
                  'Active',
                  entry.activeCount.toString(),
                  AppColors.successText,
                ),
                SizedBox(width: 16.w),
                _buildProductStat(
                  'Expiring',
                  entry.expiringCount.toString(),
                  const Color(0xFFD97706),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductStat(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 15.sp,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 10.sp, color: AppColors.textLight),
        ),
      ],
    );
  }

  Widget _buildRevenueChart(ReportEntity report) {
    if (report.revenueChartData.isEmpty) return const SizedBox.shrink();
    final double maxVal = report.revenueChartData.fold(
      0,
      (max, p) => p.value > max ? p.value : max,
    );
    final double yLimit = (maxVal * 1.2).ceilToDouble();
    return Container(
      height: 220.h,
      padding: EdgeInsets.only(right: 16.w, top: 16.h),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) =>
                const FlLine(color: Color(0xFFF3F4F6), strokeWidth: 1),
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
                  int idx = val.toInt();
                  if (idx >= 0 && idx < report.revenueChartData.length) {
                    if (report.revenueChartData.length > 8 && idx % 4 != 0) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: EdgeInsets.only(top: 8.h),
                      child: Text(
                        report.revenueChartData[idx].label,
                        style: TextStyle(
                          color: AppColors.textLight,
                          fontSize: 9.sp,
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
                reservedSize: 30.h,
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
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: report.revenueChartData
                  .asMap()
                  .entries
                  .map((e) => FlSpot(e.key.toDouble(), e.value.value))
                  .toList(),
              isCurved: true,
              color: AppColors.primary,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) =>
                    FlDotCirclePainter(
                      radius: 4,
                      color: Colors.white,
                      strokeWidth: 2,
                      strokeColor: AppColors.primary,
                    ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.primary.withValues(alpha: 0.15),
                    AppColors.primary.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ],
          minY: 0,
          maxY: yLimit,
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18.sp, color: AppColors.primary),
        SizedBox(width: 8.w),
        Text(
          title,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w800,
            color: AppColors.textDark,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }
}
