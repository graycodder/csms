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
      padding: const EdgeInsets.all(20),
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
              Text(
                'Business Settings',
                style: TextStyle(
                  color: AppColors.textDark,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              GestureDetector(
                onTap: onEdit,
                child: Row(
                  children: [
                    const Icon(
                      Icons.edit_outlined,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Edit',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // _buildSettingsRow(
          //   title: 'Auto Archive Expired',
          //   subtitle: 'Automatically archive expired subscriptions',
          //   trailing: _buildBadge(
          //     settings.autoArchiveExpired ? 'Enabled' : 'Disabled',
          //     settings.autoArchiveExpired ? const Color(0xFFE8F5E9) : const Color(0xFFF2F4F7),
          //     settings.autoArchiveExpired ? const Color(0xFF2E7D32) : const Color(0xFF5F6368),
          //   ),
          // ),
          // const Divider(height: 32, color: Color(0xFFF2F4F7)),
          // _buildSettingsRow(
          //   title: 'Show Product Filters',
          //   subtitle: 'Display product filters in customer list',
          //   trailing: _buildBadge(
          //     settings.showProductFilters ? 'Enabled' : 'Disabled',
          //     settings.showProductFilters ? const Color(0xFFE8F5E9) : const Color(0xFFF2F4F7),
          //     settings.showProductFilters ? const Color(0xFF2E7D32) : const Color(0xFF5F6368),
          //   ),
          // ),
          // const Divider(height: 32, color: Color(0xFFF2F4F7)),
          // _buildSettingsRow(
          //   title: 'Notification Days Before',
          //   subtitle: 'Days before expiry to send notifications',
          //   trailing: Text(
          //     '${settings.notificationDaysBefore} days',
          //     style: TextStyle(
          //       fontWeight: FontWeight.bold,
          //       fontSize: 15,
          //       color: AppColors.textDark,
          //     ),
          //   ),
          // ),
          const Divider(height: 32, color: Color(0xFFF2F4F7)),
          _buildSettingsRow(
            title: 'Expired Days Before',
            subtitle: 'Days to mark subscription as expired',
            trailing: Text(
              '${settings.expiredDaysBefore} days',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: AppColors.textDark,
              ),
            ),
          ),
          const Divider(height: 32, color: Color(0xFFF2F4F7)),
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
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  color: AppColors.textLight.withOpacity(0.8),
                  fontSize: 12,
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}
