import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:csms/core/theme/app_colors.dart';
import 'package:csms/features/shop/domain/entities/shop_entity.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ShopSettingsEditCard extends StatefulWidget {
  final ShopSettings settings;
  final Function(ShopSettings updatedSettings) onSave;
  final VoidCallback onCancel;

  const ShopSettingsEditCard({
    super.key,
    required this.settings,
    required this.onSave,
    required this.onCancel,
  });

  @override
  State<ShopSettingsEditCard> createState() => _ShopSettingsEditCardState();
}

class _ShopSettingsEditCardState extends State<ShopSettingsEditCard> {
  late bool _autoArchiveExpired;
  late bool _showProductFilters;
  late bool _whatsappReminderEnabled;
  late TextEditingController _notificationDaysController;
  late TextEditingController _expiredDaysController;

  @override
  void initState() {
    super.initState();
    _autoArchiveExpired = widget.settings.autoArchiveExpired;
    _showProductFilters = widget.settings.showProductFilters;
    _whatsappReminderEnabled = widget.settings.whatsappReminderEnabled;
    _notificationDaysController = TextEditingController(
      text: widget.settings.notificationDaysBefore.toString(),
    );
    _expiredDaysController = TextEditingController(
      text: widget.settings.expiredDaysBefore.toString(),
    );
  }

  @override
  void dispose() {
    _notificationDaysController.dispose();
    _expiredDaysController.dispose();
    super.dispose();
  }

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
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      final notifDays = int.tryParse(_notificationDaysController.text) ?? 2;
                      final expDays = int.tryParse(_expiredDaysController.text) ?? 10;
                      
                      if (expDays <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Expired days must be greater than 0')),
                        );
                        return;
                      }

                      final updated = ShopSettings(
                        notificationDaysBefore: notifDays,
                        expiredDaysBefore: expDays,
                        showProductFilters: _showProductFilters,
                        autoArchiveExpired: _autoArchiveExpired,
                        whatsappReminderEnabled: _whatsappReminderEnabled,
                      );
                      widget.onSave(updated);
                    },
                    child: Row(
                      children: [
                        const Icon(Icons.check, size: 16, color: AppColors.success),
                        const SizedBox(width: 4),
                        Text(
                          'Save',
                          style: TextStyle(
                            color: AppColors.success,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  GestureDetector(
                    onTap: widget.onCancel,
                    child: Row(
                      children: [
                        const Icon(Icons.close, size: 16, color: AppColors.textLight),
                        const SizedBox(width: 4),
                        Text(
                          'Cancel',
                          style: TextStyle(
                            color: AppColors.textLight,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          // _buildSwitchRow(
          //   title: 'Auto Archive Expired',
          //   subtitle: 'Automatically archive expired subscriptions',
          //   value: _autoArchiveExpired,
          //   onChanged: (v) => setState(() => _autoArchiveExpired = v),
          // ),
          // const Divider(height: 32, color: Color(0xFFF2F4F7)),
          // _buildSwitchRow(
          //   title: 'Show Product Filters',
          //   subtitle: 'Display product filters in customer list',
          //   value: _showProductFilters,
          //   onChanged: (v) => setState(() => _showProductFilters = v),
          // ),
          // const Divider(height: 32, color: Color(0xFFF2F4F7)),
          // _buildInputRow(
          //   title: 'Notification Days Before',
          //   subtitle: 'Days before expiry to send notifications',
          //   controller: _notificationDaysController,
          // ),
          const Divider(height: 32, color: Color(0xFFF2F4F7)),
          _buildInputRow(
            title: 'Expired Days Before',
            subtitle: 'Days to mark subscription as expired',
            controller: _expiredDaysController,
          ),
          const Divider(height: 32, color: Color(0xFFF2F4F7)),
          _buildSwitchRow(
            title: 'WhatsApp Reminder',
            subtitle: 'Send WhatsApp reminder for renewals',
            value: _whatsappReminderEnabled,
            onChanged: (v) => setState(() => _whatsappReminderEnabled = v),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchRow({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
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
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: Colors.white,
          activeTrackColor: AppColors.primary,
        ),
      ],
    );
  }

  Widget _buildInputRow({
    required String title,
    required String subtitle,
    required TextEditingController controller,
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
        SizedBox(
          width: 60.w,
          child: TextFormField(
            controller: controller,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              FilteringTextInputFormatter.deny(RegExp(r'^0')),
            ],
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              hintText: '>',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
