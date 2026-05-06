import 'package:flutter/material.dart';
import 'package:csms/core/widgets/responsive_layout.dart';
import 'package:csms/features/product/domain/entities/product_entity.dart';
import 'edit_product_page_mobile.dart';
import 'edit_product_page_web.dart';

class EditProductPage extends StatelessWidget {
  final ProductEntity product;
  final String ownerId;

  const EditProductPage({
    super.key,
    required this.product,
    required this.ownerId,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: EditProductPageMobile(
        product: product,
        ownerId: ownerId,
      ),
      web: EditProductPageWeb(
        product: product,
        ownerId: ownerId,
      ),
    );
  }
}
