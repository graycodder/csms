import 'package:flutter/material.dart';
import 'package:csms/core/widgets/responsive_layout.dart';
import 'package:csms/features/subscription/domain/entities/subscription_entity.dart';
import 'edit_subscription_page_mobile.dart';
import 'edit_subscription_page_web.dart';

class EditSubscriptionPage extends StatelessWidget {
  final SubscriptionEntity subscription;
  final String productName;
  final String shopCategory;
  final String customerName;
  final String? priceType;

  const EditSubscriptionPage({
    super.key,
    required this.subscription,
    required this.productName,
    required this.shopCategory,
    required this.customerName,
    this.priceType,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: EditSubscriptionPageMobile(
        subscription: subscription,
        productName: productName,
        shopCategory: shopCategory,
        customerName: customerName,
        priceType: priceType,
      ),
      web: EditSubscriptionPageWeb(
        subscription: subscription,
        productName: productName,
        shopCategory: shopCategory,
        customerName: customerName,
        priceType: priceType,
      ),
    );
  }
}
