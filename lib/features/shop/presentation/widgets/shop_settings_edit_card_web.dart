import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:csms/core/theme/app_colors.dart';
import 'package:csms/features/shop/domain/entities/shop_entity.dart';

class ShopSettingsEditCardWeb extends StatefulWidget {
  final ShopSettings settings;
  final Function(ShopSettings updatedSettings) onSave;
  final VoidCallback onCancel;

  const ShopSettingsEditCardWeb({
    super.key,
    required this.settings,
    required this.onSave,
    required this.onCancel,
  });

  @override
  State<ShopSettingsEditCardWeb> createState() => _ShopSettingsEditCardWebState();
}

class _ShopSettingsEditCardWebState extends State<ShopSettingsEditCardWeb> {
  late bool _whatsappReminderEnabled;
  late bool _registrationFeeEnabled;
  late TextEditingController _expiredDaysController;

  @override
  void initState() {
    super.initState();
    _whatsappReminderEnabled = widget.settings.whatsappReminderEnabled;
    _registrationFeeEnabled = widget.settings.registrationFeeEnabled;
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
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInputRow(
            title: 'Reminder Days',
            subtitle: 'Warning days before expiration',
            controller: _expiredDaysController,
          ),
          const Divider(height: 48, color: Color(0xFFF2F4F7)),
          _buildSwitchRow(
            title: 'WhatsApp Reminder',
            subtitle: 'Send WhatsApp reminder for renewals',
            value: _whatsappReminderEnabled,
            onChanged: (v) => setState(() => _whatsappReminderEnabled = v),
          ),
          const Divider(height: 48, color: Color(0xFFF2F4F7)),
          _buildSwitchRow(
            title: 'Registration Fee',
            subtitle: 'Collect fee during customer onboarding',
            value: _registrationFeeEnabled,
            onChanged: (v) => setState(() => _registrationFeeEnabled = v),
          ),
          const SizedBox(height: 48),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: widget.onCancel,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    minimumSize: const Size(double.infinity, 56),
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
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
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
                      registrationFeeEnabled: _registrationFeeEnabled,
                    );
                    widget.onSave(updated);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    minimumSize: const Size(double.infinity, 56),
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
                      fontSize: 16,
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
                style: const TextStyle(
                  color: AppColors.textDark,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  color: AppColors.textLight.withOpacity(0.8),
                  fontSize: 14,
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
                style: const TextStyle(
                  color: AppColors.textDark,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  color: AppColors.textLight.withOpacity(0.8),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          width: 80,
          child: TextFormField(
            controller: controller,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              FilteringTextInputFormatter.deny(RegExp(r'^0')),
            ],
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
