import 'package:flutter/material.dart';
import 'package:csms/core/widgets/responsive_layout.dart';
import 'package:csms/features/customer/domain/entities/customer_entity.dart';
import 'package:csms/features/product/domain/entities/product_entity.dart';
import 'edit_customer_page_mobile.dart';
import 'edit_customer_page_web.dart';

class EditCustomerPage extends StatelessWidget {
  final CustomerEntity customer;
  final List<ProductEntity> products;
  final String shopCategory;
  final bool registrationFeeEnabled;

  const EditCustomerPage({
    super.key,
    required this.customer,
    required this.products,
    required this.shopCategory,
    this.registrationFeeEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: EditCustomerPageMobile(
        customer: customer,
        products: products,
        shopCategory: shopCategory,
        registrationFeeEnabled: registrationFeeEnabled,
      ),
      web: EditCustomerPageWeb(
        customer: customer,
        products: products,
        shopCategory: shopCategory,
        registrationFeeEnabled: registrationFeeEnabled,
      ),
    );
  }
}
