import 'package:flutter/material.dart';
import 'package:csms/core/widgets/responsive_layout.dart';
import 'subscription_history_page_mobile.dart';
import 'subscription_history_page_web.dart';

class SubscriptionHistoryPage extends StatelessWidget {
  final String shopId;
  final String ownerId;
  final String? customerId;
  final String? customerName;
  final String shopCategory;

  const SubscriptionHistoryPage({
    super.key,
    required this.shopId,
    required this.ownerId,
    this.customerId,
    this.customerName,
    required this.shopCategory,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: SubscriptionHistoryPageMobile(
        shopId: shopId,
        ownerId: ownerId,
        customerId: customerId,
        customerName: customerName,
        shopCategory: shopCategory,
      ),
      web: SubscriptionHistoryPageWeb(
        shopId: shopId,
        ownerId: ownerId,
        customerId: customerId,
        customerName: customerName,
        shopCategory: shopCategory,
      ),
    );
  }
}
