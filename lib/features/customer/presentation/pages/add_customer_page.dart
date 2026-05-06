import 'package:flutter/material.dart';
import 'package:csms/core/widgets/responsive_layout.dart';
import 'package:csms/features/product/domain/entities/product_entity.dart';
import 'package:csms/core/utils/terminology_helper.dart';
import 'add_customer_page_mobile.dart';
import 'add_customer_page_web.dart';

class AddCustomerPage extends StatelessWidget {
  final List<ProductEntity> products;
  final String shopCategory;

  const AddCustomerPage({
    super.key,
    required this.products,
    required this.shopCategory,
  });

  @override
  Widget build(BuildContext context) {
    final term = TerminologyHelper.getTerminology(shopCategory);
    
    return ResponsiveLayout(
      mobile: AddCustomerPageMobile(
        products: products,
        shopCategory: shopCategory,
      ),
      web: AddCustomerPageWeb(
        products: products,
        shopCategory: shopCategory,
        term: term,
      ),
      breakpoint: 800,
    );
  }
}
