import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:csms/core/widgets/responsive_layout.dart';
import 'package:csms/features/shop/domain/entities/shop_entity.dart';
import 'package:csms/features/shop/presentation/bloc/shop_context_bloc.dart';
import 'package:csms/core/utils/loading_overlay.dart';
import 'shop_edit_page_mobile.dart';
import 'shop_edit_page_web.dart';

class ShopEditPage extends StatelessWidget {
  final ShopEntity shop;

  const ShopEditPage({super.key, required this.shop});

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: ShopEditPageMobile(
        shop: shop,
        onSave: (name, shopAddress, category, phone) {
          FocusManager.instance.primaryFocus?.unfocus();
          _showConfirmDialog(context, name, shopAddress, category, phone);
        },
        onCancel: () => Navigator.pop(context),
      ),
      web: ShopEditPageWeb(shop: shop),
    );
  }

  void _showConfirmDialog(
    BuildContext context,
    String name,
    String address,
    String category,
    String phone,
  ) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Update Business Info'),
            content: const Text(
              'Are you sure you want to update your business information?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  LoadingOverlayHelper.show(context);
                  context.read<ShopContextBloc>().add(
                    UpdateShop(
                      shop.copyWith(
                        shopName: name,
                        shopAddress: address,
                        category: category,
                        phone: phone,
                        updatedAt: DateTime.now(),
                      ),
                    ),
                  );
                },
                child: const Text(
                  'Update',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
    );
  }
}
