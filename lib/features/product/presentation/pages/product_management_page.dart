import 'package:flutter/material.dart';
import 'package:csms/core/widgets/responsive_layout.dart';
import 'package:csms/features/product/presentation/pages/product_management_page_mobile.dart';
import 'package:csms/features/product/presentation/pages/product_management_page_web.dart';

class ProductManagementPage extends StatelessWidget {
  const ProductManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ResponsiveLayout(
      mobile: ProductManagementPageMobile(),
      web: ProductManagementPageWeb(),
      breakpoint: 800,
    );
  }
}
