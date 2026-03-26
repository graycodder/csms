import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:csms/core/utils/launcher_utils.dart';
import 'package:csms/features/shop/domain/entities/shop_entity.dart';
import 'package:csms/features/subscription/domain/entities/subscription_entity.dart';
import 'package:csms/features/customer/domain/entities/customer_entity.dart';
import 'package:csms/features/product/domain/entities/product_entity.dart';
import 'package:csms/core/utils/terminology_helper.dart';

class WhatsappReminderBanner extends StatelessWidget {
  final ShopEntity shop;
  final CustomerEntity customer;
  final SubscriptionEntity sub;
  final int daysLeft;
  final List<ProductEntity> products;
  final String Function(DateTime) formatDate;

  const WhatsappReminderBanner({
    super.key,
    required this.shop,
    required this.customer,
    required this.sub,
    required this.daysLeft,
    required this.products,
    required this.formatDate,
  });

  @override
  Widget build(BuildContext context) {
    final term = TerminologyHelper.getTerminology(shop.category);
    
    return GestureDetector(
      onTap: () {
        if (shop.settings.whatsappReminderEnabled) {
          final productName = products.where((p) => p.productId == sub.productId).firstOrNull?.name ?? sub.productId;
          
          String message = term.reminderMessageTemplate;
          message = message.replaceAll('{customer_name}', customer.name);
          message = message.replaceAll('{shop_name}', shop.shopName);
          message = message.replaceAll('{product_name}', productName);
          message = message.replaceAll('{days_left}', daysLeft.toString());
          message = message.replaceAll('{end_date}', formatDate(sub.endDate));
          message = message.replaceAll('{sub_label}', term.subscriptionLabel.toLowerCase());
          message = message.replaceAll('{plan_label}', term.planLabel.toLowerCase());
          message = message.replaceAll('{renew_label}', term.renewActionLabel.toLowerCase());

          AppLauncherUtils.launchWhatsApp(
            customer.mobileNumber, 
            message,
            defaultCountryCode: shop.settings.defaultCountryCode,
          );
        }
      },
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF3E0),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: const Color(0xFFE67E22), size: 18.w),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                '${term.renewActionLabel} needed soon',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: const Color(0xFFE67E22),
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (shop.settings.whatsappReminderEnabled) ...[
              Icon(Icons.share_outlined, color: const Color(0xFFE67E22), size: 16.w),
              SizedBox(width: 4.w),
            ],
          ],
        ),
      ),
    );
  }
}
