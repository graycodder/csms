import 'package:flutter/material.dart';
import 'package:csms/core/theme/app_colors.dart';
import 'package:csms/features/shop/domain/entities/shop_entity.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ShopSettingsCard extends StatelessWidget {
  final ShopSettings settings;
  final VoidCallback onEdit;

  const ShopSettingsCard({
    super.key,
    required this.settings,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10.r,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Business Settings',
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
          Divider(height: 32.h, color: const Color(0xFFF2F4F7)),
          _buildSettingsRow(
            title: 'Reminder Days',
            subtitle: 'Days before expiration to notify',
            trailing: Text(
              '${settings.expiredDaysBefore} days',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15.sp,
                color: AppColors.textDark,
              ),
            ),
          ),
          Divider(height: 32.h, color: const Color(0xFFF2F4F7)),
          _buildSettingsRow(
            title: 'WhatsApp Reminder',
            subtitle: 'Send WhatsApp reminder for renewals',
            trailing: _buildBadge(
              settings.whatsappReminderEnabled ? 'Enabled' : 'Disabled',
              settings.whatsappReminderEnabled ? const Color(0xFFE8F5E9) : const Color(0xFFF2F4F7),
              settings.whatsappReminderEnabled ? const Color(0xFF2E7D32) : const Color(0xFF5F6368),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsRow({
    required String title,
    required String subtitle,
    required Widget trailing,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: AppColors.textDark,
                  fontWeight: FontWeight.bold,
                  fontSize: 15.sp,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                subtitle,
                style: TextStyle(
                  color: AppColors.textLight.withOpacity(0.8),
                  fontSize: 12.sp,
                ),
              ),
            ],
          ),
        ),
        trailing,
      ],
    );
  }

  Widget _buildBadge(String label, Color bgColor, Color textColor) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w600,
          fontSize: 12.sp,
        ),
      ),
    );
  }
}
