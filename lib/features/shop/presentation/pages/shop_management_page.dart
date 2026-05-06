import 'package:flutter/material.dart';
import 'package:csms/core/widgets/responsive_layout.dart';
import 'package:csms/features/shop/presentation/pages/shop_management_page_mobile.dart';
import 'package:csms/features/shop/presentation/pages/shop_management_page_web.dart';

class ShopManagementPage extends StatelessWidget {
  const ShopManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ResponsiveLayout(
      mobile: ShopManagementPageMobile(),
      web: ShopManagementPageWeb(),
      breakpoint: 800,
    );
  }
}
