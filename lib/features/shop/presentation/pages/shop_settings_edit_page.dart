import 'package:flutter/material.dart';
import 'package:csms/core/widgets/responsive_layout.dart';
import 'package:csms/features/shop/domain/entities/shop_entity.dart';
import 'shop_settings_edit_page_mobile.dart';
import 'shop_settings_edit_page_web.dart';

class ShopSettingsEditPage extends StatelessWidget {
  final ShopEntity shop;

  const ShopSettingsEditPage({
    super.key,
    required this.shop,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: ShopSettingsEditPageMobile(shop: shop),
      web: ShopSettingsEditPageWeb(shop: shop),
    );
  }
}
