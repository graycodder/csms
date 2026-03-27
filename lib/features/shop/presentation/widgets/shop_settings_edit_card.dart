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
  late bool _whatsappReminderEnabled;
  late TextEditingController _expiredDaysController;

  @override
  void initState() {
    super.initState();
    _whatsappReminderEnabled = widget.settings.whatsappReminderEnabled;
    _expiredDaysController = TextEditingController(
      text: widget.settings.expiredDaysBefore.toString(),
    );
  }

  @override
  void dispose() {
    _expiredDaysController.dispose();
    super.dispose();
  }

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
          _buildInputRow(
            title: 'Reminder Days',
            subtitle: 'Warning days before expiration',
            controller: _expiredDaysController,
          ),
          Divider(height: 32.h, color: const Color(0xFFF2F4F7)),
          _buildSwitchRow(
            title: 'WhatsApp Reminder',
            subtitle: 'Send WhatsApp reminder for renewals',
            value: _whatsappReminderEnabled,
            onChanged: (v) => setState(() => _whatsappReminderEnabled = v),
          ),
          SizedBox(height: 32.h),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: widget.onCancel,
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    minimumSize: Size(double.infinity, 48.h),
                    side: const BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: AppColors.textLight,
                      fontWeight: FontWeight.bold,
                      fontSize: 14.sp,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    final expDays = int.tryParse(_expiredDaysController.text) ?? 10;
                    
                    if (expDays <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Expired days must be greater than 0')),
                      );
                      return;
                    }

                    final updated = widget.settings.copyWith(
                      expiredDaysBefore: expDays,
                      whatsappReminderEnabled: _whatsappReminderEnabled,
                    );
                    widget.onSave(updated);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    minimumSize: Size(double.infinity, 48.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Save',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14.sp,
                    ),
                  ),
                ),
              ),
            ],
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
              contentPadding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
              hintText: '>',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
                borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
                borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
