import 'package:flutter/material.dart';
import 'package:csms/core/theme/app_colors.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ShopInfoCard extends StatelessWidget {
  final String shopName;
  final String shopAddress;
  final String shopCategory;
  final String shopPhone;
  final VoidCallback onEdit;

  const ShopInfoCard({
    super.key,
    required this.shopName,
    required this.shopAddress,
    required this.shopCategory,
    required this.shopPhone,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.border.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Business Information',
                  style: TextStyle(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.bold,
                    fontSize: 18.sp,
                  ),
                ),
              ),
              GestureDetector(
                onTap: onEdit,
                child: Row(
                  children: [
                    Icon(
                      Icons.edit_outlined,
                      size: 16.sp,
                      color: AppColors.primary,
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      'Edit',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14.sp,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 24.h),
          _buildInfoFieldRow(
            title: 'Business Name',
            value: shopName,
            icon: Icons.business_outlined,
          ),
          SizedBox(height: 16.h),
          _buildInfoFieldRow(
            title: 'Business Address',
            value: shopAddress,
            icon: Icons.location_on_outlined,
          ),
          SizedBox(height: 16.h),
          _buildInfoFieldRow(
            title: 'Category',
            value: shopCategory,
            icon: Icons.category_outlined,
          ),
          SizedBox(height: 16.h),
          _buildInfoFieldRow(
            title: 'Phone Number',
            value: shopPhone,
            icon: Icons.phone_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoFieldRow({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: AppColors.textLight,
            fontWeight: FontWeight.w600,
            fontSize: 13.sp,
          ),
        ),
        SizedBox(height: 8.h),
        Row(
          children: [
            Icon(icon, color: AppColors.textLight, size: 20.sp),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                value,
                style: TextStyle(
                  color: AppColors.textDark,
                  fontWeight: FontWeight.w500,
                  fontSize: 16.sp,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
