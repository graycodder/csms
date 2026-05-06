import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:csms/core/theme/app_colors.dart';
import 'package:csms/features/shop_subscription/domain/entities/shop_subscription_entity.dart';
import 'shop_subscription_history_page.dart';

class ShopSubscriptionPageMobile extends StatelessWidget {
  final ShopSubscriptionEntity subscription;
  final String ownerId;

  const ShopSubscriptionPageMobile({
    super.key,
    required this.subscription,
    required this.ownerId,
  });

  @override
  Widget build(BuildContext context) {
    final active = subscription.activePlan;
    final now = DateTime.now();
    final isExpired = active == null ||
        active.status == 'expired' ||
        active.endDate.isBefore(now);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Business Subscription',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textDark,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Card
            Container(
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                color: isExpired ? AppColors.errorBg : AppColors.successBg,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: isExpired ? AppColors.errorText : AppColors.success,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isExpired ? Icons.error_outline : Icons.check_circle_outline,
                    color: isExpired ? AppColors.errorText : AppColors.success,
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isExpired ? 'Subscription Expired' : 'Active Plan',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isExpired
                                ? AppColors.errorText
                                : AppColors.success,
                          ),
                        ),
                        if (active != null)
                          Text(
                            'Plan: ${active.planName}',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: isExpired
                                  ? AppColors.errorText
                                  : AppColors.success,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24.h),
            if (active != null) ...[
              const Text(
                'Plan Details',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 12.h),
              _detailRow('Start Date', DateFormat('MMM dd, yyyy').format(active.startDate)),
              _detailRow('End Date', DateFormat('MMM dd, yyyy').format(active.endDate)),
              _detailRow('Status', active.status.toUpperCase()),
              SizedBox(height: 32.h),
            ],
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ShopSubscriptionHistoryPage(
                      shopId: subscription.shopId,
                      ownerId: ownerId,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50.h),
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('View History'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
