import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';

class ShopSubscriptionLockPageWeb extends StatelessWidget {
  final String shopName;
  final DateTime? startDate;
  final DateTime? endDate;
  final String status;

  const ShopSubscriptionLockPageWeb({
    super.key,
    required this.shopName,
    this.startDate,
    this.endDate,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final String startStr = startDate != null
        ? DateFormat('MMMM dd, yyyy').format(startDate!)
        : 'N/A';
    final String endStr = endDate != null
        ? DateFormat('MMMM dd, yyyy').format(endDate!)
        : 'N/A';

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6), // Light gray background
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(40),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Container(
              padding: const EdgeInsets.all(48),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 40,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon
                  Container(
                    width: 100,
                    height: 100,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFEF2F2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.lock_clock_outlined,
                      size: 48,
                      color: Color(0xFFEF4444),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Title
                  const Text(
                    'Business Access Restricted',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111827),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Description
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: const TextStyle(
                        fontSize: 18,
                        color: Color(0xFF4B5563),
                        height: 1.6,
                      ),
                      children: [
                        const TextSpan(text: 'The subscription for '),
                        TextSpan(
                          text: '"$shopName"',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF111827),
                          ),
                        ),
                        TextSpan(
                          text:
                              ' has $status. Access to the management dashboard is currently disabled.',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 48),

                  // Info Card
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Column(
                      children: [
                        _buildWebInfoRow(
                          'Current Status',
                          status.toUpperCase(),
                          isStatus: true,
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Divider(color: Color(0xFFE5E7EB)),
                        ),
                        _buildWebInfoRow('Subscription Started', startStr),
                        const SizedBox(height: 16),
                        _buildWebInfoRow('Subscription Expired', endStr),
                      ],
                    ),
                  ),
                  const SizedBox(height: 48),

                  // Contact Support
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.support_agent,
                          color: AppColors.primary,
                          size: 28,
                        ),
                        const SizedBox(width: 20),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Need help?',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Color(0xFF111827),
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Please contact your system administrator or reach out to our support team to renew your subscription.',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF4B5563),
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWebInfoRow(String label, String value, {bool isStatus = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            color: Color(0xFF6B7280),
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isStatus ? const Color(0xFFEF4444) : const Color(0xFF111827),
          ),
        ),
      ],
    );
  }
}
