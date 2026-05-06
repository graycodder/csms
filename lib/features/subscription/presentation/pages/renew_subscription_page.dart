import 'package:flutter/material.dart';
import 'package:csms/core/widgets/responsive_layout.dart';
import 'renew_subscription_page_mobile.dart';
import 'renew_subscription_page_web.dart';

class RenewSubscriptionPage extends StatelessWidget {
  final String subscriptionId;
  final String shopId;
  final String ownerId;
  final DateTime currentEndDate;
  final String productName;
  final String validityUnit;
  final int validityValue;
  final String priceType;
  final String validityType;
  final double basePrice;
  final String shopCategory;
  final String customerName;
  final double currentBalance;

  const RenewSubscriptionPage({
    super.key,
    required this.subscriptionId,
    required this.shopId,
    required this.ownerId,
    required this.currentEndDate,
    required this.productName,
    required this.validityUnit,
    required this.validityValue,
    this.priceType = 'fixed',
    this.validityType = 'fixed',
    this.basePrice = 0.0,
    required this.shopCategory,
    required this.customerName,
    this.currentBalance = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: RenewSubscriptionPageMobile(
        subscriptionId: subscriptionId,
        shopId: shopId,
        ownerId: ownerId,
        currentEndDate: currentEndDate,
        productName: productName,
        validityUnit: validityUnit,
        validityValue: validityValue,
        priceType: priceType,
        validityType: validityType,
        basePrice: basePrice,
        shopCategory: shopCategory,
        customerName: customerName,
        currentBalance: currentBalance,
      ),
      web: RenewSubscriptionPageWeb(
        subscriptionId: subscriptionId,
        shopId: shopId,
        ownerId: ownerId,
        currentEndDate: currentEndDate,
        productName: productName,
        validityUnit: validityUnit,
        validityValue: validityValue,
        priceType: priceType,
        validityType: validityType,
        basePrice: basePrice,
        shopCategory: shopCategory,
        customerName: customerName,
        currentBalance: currentBalance,
      ),
    );
  }
}
