import 'package:flutter/material.dart';
import '../../../../core/widgets/responsive_layout.dart';
import 'shop_subscription_lock_page_mobile.dart';
import 'shop_subscription_lock_page_web.dart';

class ShopSubscriptionLockPage extends StatelessWidget {
  final String shopName;
  final DateTime? startDate;
  final DateTime? endDate;
  final String status;

  const ShopSubscriptionLockPage({
    super.key,
    required this.shopName,
    this.startDate,
    this.endDate,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: ShopSubscriptionLockPageMobile(
        shopName: shopName,
        startDate: startDate,
        endDate: endDate,
        status: status,
      ),
      web: ShopSubscriptionLockPageWeb(
        shopName: shopName,
        startDate: startDate,
        endDate: endDate,
        status: status,
      ),
    );
  }
}
