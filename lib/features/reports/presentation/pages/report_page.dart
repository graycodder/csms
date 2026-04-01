import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:csms/core/theme/app_colors.dart';
import 'package:csms/features/reports/domain/entities/report_entity.dart';
import 'package:csms/features/reports/presentation/pages/daily_report_page.dart';
import 'package:csms/features/reports/presentation/pages/monthly_report_page.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:csms/features/reports/presentation/bloc/report_bloc.dart';
import 'package:csms/injection_container.dart';

class ReportPage extends StatefulWidget {
  const ReportPage({super.key});

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  ReportFilter _currentFilter = ReportFilter.daily;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: ReportFilter.values.length,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<ReportBloc>(),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        body: Column(
          children: [
            _buildHeader(context),
            SizedBox(height: 16.h),
            _buildPillSwitcher(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                physics: const NeverScrollableScrollPhysics(), // Only via tabs
                children: const [DailyReportView(), MonthlyReportView()],
              ),
            ),
          ],
        ),
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
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.2.w,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                'View your business reports',
                style: TextStyle(color: Colors.white70, fontSize: 13.sp),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPillSwitcher() {
    return Container(
      height: 44.h,
      width: 280.w,
      decoration: BoxDecoration(
        color: const Color(0xFFF2F4F7),
        borderRadius: BorderRadius.circular(22.r),
      ),
      padding: EdgeInsets.all(4.r),
      child: Row(
        children: ReportFilter.values.map((filter) {
          final isSelected = _currentFilter == filter;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _currentFilter = filter;
                  _tabController.animateTo(filter.index);
                });
              },
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(20.r),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  filter.label,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected
                        ? AppColors.textDark
                        : AppColors.textLight,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
