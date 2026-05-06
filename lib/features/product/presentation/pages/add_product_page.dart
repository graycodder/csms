import 'package:flutter/material.dart';
import 'package:csms/core/widgets/responsive_layout.dart';
import 'add_product_page_mobile.dart';
import 'add_product_page_web.dart';

class AddProductPage extends StatelessWidget {
  final String shopId;
  final String ownerId;

  const AddProductPage({
    super.key,
    required this.shopId,
    required this.ownerId,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: AddProductPageMobile(
        shopId: shopId,
        ownerId: ownerId,
      ),
      web: AddProductPageWeb(
        shopId: shopId,
        ownerId: ownerId,
      ),
    );
  }
}
