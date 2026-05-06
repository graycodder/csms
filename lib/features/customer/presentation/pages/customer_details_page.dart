import 'package:flutter/material.dart';
import 'package:csms/core/widgets/responsive_layout.dart';
import 'customer_details_page_mobile.dart';
import 'customer_details_page_web.dart';

class CustomerDetailsPage extends StatelessWidget {
  final String customerId;

  const CustomerDetailsPage({super.key, required this.customerId});

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: CustomerDetailsPageMobile(customerId: customerId),
      web: CustomerDetailsPageWeb(customerId: customerId),
    );
  }
}
