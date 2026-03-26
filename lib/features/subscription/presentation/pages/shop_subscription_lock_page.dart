import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';

class ShopSubscriptionLockPage extends StatelessWidget {
  final String shopName;
  final DateTime? startDate;
  final DateTime? endDate;
  final String status;

  const ShopSubscriptionLockPage({
    super.key,
    required this.shopName,
    this.startDate,
    this.endDate,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final String startStr = startDate != null ? DateFormat('dd/MM/yyyy').format(startDate!) : 'N/A';
    final String endStr = endDate != null ? DateFormat('dd/MM/yyyy').format(endDate!) : 'N/A';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 30.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Lock Icon Container
              Container(
                width: 120.w,
                height: 120.w,
                decoration: const BoxDecoration(
                  color: Color(0xFFFEF2F2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.lock_clock_outlined,
                  size: 60.w,
                  color: const Color(0xFFEF4444),
                ),
              ),
              SizedBox(height: 40.h),

              // Title
              Text(
                'Shop Access Locked',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              SizedBox(height: 16.h),

              // Description
              Text(
                'The subscription for "$shopName" has ${status.toLowerCase()}. Access to the management tools is currently restricted.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16.sp,
                  color: AppColors.textLight,
                  height: 1.5,
                ),
              ),
              SizedBox(height: 32.h),

              // Detailed Dates Box
              Container(
                padding: EdgeInsets.all(20.r),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Column(
                  children: [
                    _buildDateRow('Status', status.toUpperCase(), isStatus: true),
                    const Divider(height: 24, color: Color(0xFFE5E7EB)),
                    _buildDateRow('Start Date', startStr),
                    SizedBox(height: 12.h),
                    _buildDateRow('Expiry Date', endStr),
                  ],
                ),
              ),
              SizedBox(height: 48.h),

              // Action Info
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.info_outline, size: 20.w, color: AppColors.primary),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Text(
                      'Please contact your system administrator to renew your plan.',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: AppColors.textDark,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateRow(String label, String value, {bool isStatus = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14.sp,
            color: AppColors.textLight,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
            color: isStatus ? const Color(0xFFEF4444) : AppColors.textDark,
          ),
        ),
      ],
    );
  }
}
