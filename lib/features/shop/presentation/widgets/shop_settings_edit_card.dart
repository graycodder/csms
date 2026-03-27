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
          const Divider(height: 32, color: Color(0xFFF2F4F7)),
          _buildInputRow(
            title: 'Reminder Days',
            subtitle: 'Reminder warning days',
            controller: _expiredDaysController,
          ),
          const Divider(height: 32, color: Color(0xFFF2F4F7)),
          _buildSwitchRow(
            title: 'WhatsApp Reminder',
            subtitle: 'Send WhatsApp reminder for renewals',
            value: _whatsappReminderEnabled,
            onChanged: (v) => setState(() => _whatsappReminderEnabled = v),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: widget.onCancel,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    minimumSize: const Size(double.infinity, 48),
                    side: const BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      color: AppColors.textLight,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Save',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
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
