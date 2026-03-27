import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:csms/core/theme/app_colors.dart';
import 'package:csms/features/shop/domain/entities/shop_entity.dart';
import 'package:csms/features/shop/presentation/bloc/shop_context_bloc.dart';
import 'package:csms/features/shop/presentation/widgets/shop_edit_card.dart';
import 'package:csms/core/utils/loading_overlay.dart';

class ShopEditPage extends StatelessWidget {
  final ShopEntity shop;

  const ShopEditPage({
    super.key,
    required this.shop,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      appBar: AppBar(
        title: const Text(
          'Edit Business Info',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: ShopEditCard(
          shop: shop,
          onSave: (name, shopAddress, category, phone) {
            final updatedShop = ShopEntity(
              shopId: shop.shopId,
              ownerId: shop.ownerId,
              shopName: name,
              shopAddress: shopAddress,
              category: category,
              phone: phone,
              settings: shop.settings,
              createdAt: shop.createdAt,
              updatedAt: DateTime.now(),
              updatedById: shop.updatedById,
            );
            _updateShop(context, updatedShop);
            Navigator.pop(context);
          },
          onCancel: () => Navigator.pop(context),
        ),
      ),
    );
  }

  void _updateShop(BuildContext context, ShopEntity updatedShop) {
    LoadingOverlay.show(context);
    context.read<ShopContextBloc>().add(UpdateShop(updatedShop));
  }
}
