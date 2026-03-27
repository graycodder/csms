import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:csms/core/theme/app_colors.dart';
import 'package:csms/features/staff/domain/entities/staff_entity.dart';

class StaffItemCard extends StatelessWidget {
  final StaffEntity staff;
  final VoidCallback onEdit;
  final VoidCallback onToggleStatus;

  const StaffItemCard({
    super.key,
    required this.staff,
    required this.onEdit,
    required this.onToggleStatus,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = staff.status == 'active';
    
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.border.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          // Avatar circle
          Container(
            width: 44.w,
            height: 44.w,
            decoration: BoxDecoration(
              color: isActive ? const Color(0xFFE8EAF6) : Colors.grey[200],
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                staff.name.isNotEmpty
                    ? staff.name[0].toUpperCase()
                    : '?',
                style: TextStyle(
                  color: isActive ? const Color(0xFF3D5AFE) : Colors.grey[500],
                  fontWeight: FontWeight.bold,
                  fontSize: 18.sp,
                ),
              ),
            ),
          ),
          SizedBox(width: 12.w),
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      staff.name[0].toUpperCase() + staff.name.substring(1).toLowerCase(),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15.sp,
                        color: isActive ? const Color(0xFF1A1A2E) : Colors.grey[600],
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                      decoration: BoxDecoration(
                        color: isActive ? Colors.green[50] : Colors.red[50],
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                      child: Text(
                        isActive ? 'Active' : 'Inactive',
                        style: TextStyle(
                          color: isActive ? Colors.green[700] : Colors.red[700],
                          fontSize: 10.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 2.h),
                Text(
                  staff.role,
                  style: TextStyle(
                    color: isActive ? const Color(0xFF6B7280) : Colors.grey[400],
                    fontSize: 13.sp,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  staff.phone,
                  style: TextStyle(
                    color: isActive ? const Color(0xFF9E9E9E) : Colors.grey[400],
                    fontSize: 12.sp,
                  ),
                ),
              ],
            ),
          ),
          // Action buttons
          Row(
            children: [
              GestureDetector(
                onTap: onEdit,
                child: Icon(
                  Icons.edit_outlined,
                  color: isActive ? AppColors.primary : Colors.grey[400],
                  size: 20.sp,
                ),
              ),
              SizedBox(width: 16.w),
              GestureDetector(
                onTap: onToggleStatus,
                child: Icon(
                  isActive ? Icons.toggle_on : Icons.toggle_off,
                  color: isActive ? Colors.green : Colors.grey[400],
                  size: 45.sp,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
