import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:csms/core/theme/app_colors.dart';
import 'package:csms/core/utils/terminology_helper.dart';
import 'package:csms/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:csms/features/reports/domain/entities/report_entity.dart';
import 'package:csms/features/reports/presentation/bloc/report_bloc.dart';

class ReportPage extends StatefulWidget {
  const ReportPage({super.key});

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  ReportFilter _currentFilter = ReportFilter.allTime;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardBloc, DashboardState>(
      builder: (context, dashState) {
        if (dashState is DashboardLoaded) {
          // Trigger compute whenever dashboard state is available
          context.read<ReportBloc>().add(LoadReport(dashState, filter: _currentFilter));
          final term = TerminologyHelper.getTerminology(dashState.shop.category);

          return BlocBuilder<ReportBloc, ReportState>(
            builder: (context, reportState) {
              if (reportState is ReportLoaded) {
                return _buildPage(context, reportState.report, term, dashState);
              }
              return _buildPage(
                context,
                ReportEntity(
                  totalCustomers: 0,
                  activeCustomers: 0,
                  inactiveCustomers: 0,
                  activeSubscriptions: 0,
                  expiringSoonSubscriptions: 0,
                  expiredSubscriptions: 0,
                  newJoiners: 0,
                  newSubscriptions: 0,
                  registrationFeeCollected: 0,
                  registrationFeePending: 0,
                  totalPendingBalance: 0,
                  filter: _currentFilter,
                  productBreakdown: [],
                ),
                term,
                dashState,
              );
            },
          );
        }
        return Scaffold(
          appBar: AppBar(
            backgroundColor: AppColors.primary,
            title: const Text('Business Report',
                style: TextStyle(color: Colors.white)),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: const Center(child: CircularProgressIndicator()),
        );
      },
    );
  }

  Widget _buildPage(
      BuildContext context, ReportEntity report, BusinessTerminology term, DashboardLoaded dashState) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16.r),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('📊 Current Status', Icons.analytics_outlined),
                  SizedBox(height: 12.h),
                  _buildCurrentStatusGrid(report, term),

                  SizedBox(height: 24.h),
                  Row(
                    children: [
                      _buildSectionTitle('📅 Activity', Icons.history),
                      const SizedBox(width: 12),
                      Expanded(child: _buildFilterChips(dashState)),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  _buildActivitySection(report, term),

                  if (report.productBreakdown.isNotEmpty) ...[
                    SizedBox(height: 24.h),
                    _buildSectionTitle('📦 Product Breakdown', Icons.inventory_2_outlined),
                    SizedBox(height: 12.h),
                    _buildProductBreakdown(report, term),
                  ],

                  SizedBox(height: 32.h),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(DashboardLoaded dashState) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: ReportFilter.values.map((filter) {
        final isSelected = _currentFilter == filter;
        return Padding(
          padding: EdgeInsets.only(left: 8.w),
          child: ChoiceChip(
            label: Text(
              filter.label,
              style: TextStyle(
                fontSize: 11.sp,
                color: isSelected ? Colors.white : AppColors.textLight,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            selected: isSelected,
            onSelected: (selected) {
              if (selected) {
                setState(() {
                  _currentFilter = filter;
                });
                context.read<ReportBloc>().add(
                  ChangeReportFilter(dashboardState: dashState, filter: filter)
                );
              }
            },
            selectedColor: AppColors.primary,
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.r),
              side: BorderSide(
                color: isSelected ? AppColors.primary : const Color(0xFFE0E0E0),
              ),
            ),
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        );
      }).toList(),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16.h,
        left: 20.w,
        right: 20.w,
        bottom: 28.h,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28.r),
          bottomRight: Radius.circular(28.r),
        ),
      ),
      child: Row(
        children: [
          InkWell(
            onTap: () => Navigator.pop(context),
            borderRadius: BorderRadius.circular(20.r),
            child: Container(
              padding: EdgeInsets.all(8.r),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.arrow_back, color: Colors.white, size: 22.sp),
            ),
          ),
          SizedBox(width: 16.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Business Report',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22.sp,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.2,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                'Performance overview',
                style: TextStyle(color: Colors.white70, fontSize: 13.sp),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16.sp,
        fontWeight: FontWeight.bold,
        color: AppColors.textDark,
      ),
    );
  }

  Widget _buildCurrentStatusGrid(ReportEntity report, BusinessTerminology term) {
    return Column(
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _statCard(
                  label: 'Total',
                  subLabel: '${term.customerLabel}s',
                  value: '${report.totalCustomers}',
                  valueColor: AppColors.textDark,
                  bgColor: Colors.white,
                  icon: Icons.people_outline,
                  iconColor: AppColors.primary,
                  iconBg: AppColors.primary.withOpacity(0.1),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _statCard(
                  label: 'Active',
                  subLabel: '${term.customerLabel}s',
                  value: '${report.activeCustomers}',
                  valueColor: const Color(0xFF27AE60),
                  bgColor: Colors.white,
                  icon: Icons.check_circle_outline,
                  iconColor: const Color(0xFF27AE60),
                  iconBg: const Color(0xFFE8F5E9),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 12.h),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _statCard(
                  label: 'Active',
                  subLabel: '${term.subscriptionLabel}s',
                  value: '${report.activeSubscriptions}',
                  valueColor: const Color(0xFF27AE60),
                  bgColor: Colors.white,
                  icon: Icons.verified_outlined,
                  iconColor: const Color(0xFF27AE60),
                  iconBg: const Color(0xFFE8F5E9),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _statCard(
                  label: 'Inactive',
                  subLabel: '${term.customerLabel}s',
                  value: '${report.inactiveCustomers}',
                  valueColor: const Color(0xFF9E9E9E),
                  bgColor: Colors.white,
                  icon: Icons.person_off_outlined,
                  iconColor: const Color(0xFF9E9E9E),
                  iconBg: const Color(0xFFF5F5F5),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 12.h),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _statCard(
                  label: 'Expiring Soon',
                  subLabel: '${term.subscriptionLabel}s',
                  value: '${report.expiringSoonSubscriptions}',
                  valueColor: const Color(0xFFE67E22),
                  bgColor: Colors.white,
                  icon: Icons.timer_outlined,
                  iconColor: const Color(0xFFE67E22),
                  iconBg: const Color(0xFFFFF3E0),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _statCard(
                  label: 'Expired',
                  subLabel: '${term.subscriptionLabel}s',
                  value: '${report.expiredSubscriptions}',
                  valueColor: Colors.red,
                  bgColor: Colors.white,
                  icon: Icons.cancel_outlined,
                  iconColor: Colors.red,
                  iconBg: Colors.red.withOpacity(0.1),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActivitySection(ReportEntity report, BusinessTerminology term) {
    return Column(
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _statCard(
                  label: 'New Joiners',
                  subLabel: '${term.customerLabel}s',
                  value: '${report.newJoiners}',
                  valueColor: AppColors.primary,
                  bgColor: Colors.white,
                  icon: Icons.person_add_outlined,
                  iconColor: AppColors.primary,
                  iconBg: AppColors.primary.withOpacity(0.1),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _statCard(
                  label: 'New Plans',
                  subLabel: '${term.subscriptionLabel}s',
                  value: '${report.newSubscriptions}',
                  valueColor: const Color(0xFF9C27B0),
                  bgColor: Colors.white,
                  icon: Icons.add_task_outlined,
                  iconColor: const Color(0xFF9C27B0),
                  iconBg: const Color(0xFFF3E5F5),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 12.h),
        Container(
          padding: EdgeInsets.all(20.r),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10.r,
                offset: Offset(0, 4.h),
              ),
            ],
          ),
          child: Column(
            children: [
              _revenueRow(
                'Reg. Fee Collected',
                '₹${report.registrationFeeCollected.toStringAsFixed(0)}',
                const Color(0xFF27AE60),
                Icons.check_circle_outline,
              ),
              Divider(height: 20.h, color: const Color(0xFFF0F0F0)),
              _revenueRow(
                'Reg. Fee Pending',
                '₹${report.registrationFeePending.toStringAsFixed(0)}',
                const Color(0xFFE67E22),
                Icons.pending_outlined,
              ),
              Divider(height: 20.h, color: const Color(0xFFF0F0F0)),
              _revenueRow(
                'Selected Range Dues',
                '₹${report.totalPendingBalance.toStringAsFixed(0)}',
                Colors.red,
                Icons.account_balance_wallet_outlined,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _revenueRow(String label, String value, Color color, IconData icon) {
    return Row(
      children: [
        Container(
          width: 36.w,
          height: 36.w,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 18.sp),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14.sp,
              color: AppColors.textLight,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildProductBreakdown(ReportEntity report, BusinessTerminology term) {
    return Column(
      children: report.productBreakdown.map((entry) {
        return Container(
          margin: EdgeInsets.only(bottom: 12.h),
          padding: EdgeInsets.all(16.r),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8.r,
                offset: Offset(0, 4.h),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 8.w,
                    height: 8.w,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      entry.productName,
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 14.h),
              Row(
                children: [
                  _productStat('Active', '${entry.activeCount}',
                      const Color(0xFF27AE60)),
                  SizedBox(width: 12.w),
                  _productStat('Expiring', '${entry.expiringCount}',
                      const Color(0xFFE67E22)),
                  SizedBox(width: 12.w),
                  _productStat('Expired', '${entry.expiredCount}', Colors.red),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _productStat(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 10.h),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.sp,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard({
    required String label,
    required String subLabel,
    required String value,
    required Color valueColor,
    required Color bgColor,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10.r,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40.w,
            height: 40.w,
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 20.sp),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 22.sp,
                    fontWeight: FontWeight.bold,
                    color: valueColor,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
                Text(
                  subLabel,
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: AppColors.textLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _monthName(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[dt.month - 1];
  }
}
