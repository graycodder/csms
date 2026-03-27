import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:csms/core/theme/app_colors.dart';
import 'package:csms/features/shop/domain/entities/shop_entity.dart';
import 'package:csms/features/shop/presentation/bloc/shop_context_bloc.dart';
import 'package:csms/features/shop/presentation/widgets/shop_settings_edit_card.dart';
import 'package:csms/core/utils/loading_overlay.dart';

class ShopSettingsEditPage extends StatelessWidget {
  final ShopEntity shop;

  const ShopSettingsEditPage({
    super.key,
    required this.shop,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      appBar: AppBar(
        title: const Text(
          'Edit Business Settings',
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
        child: ShopSettingsEditCard(
          settings: shop.settings,
          onSave: (updatedSettings) {
            _showConfirmDialog(context, updatedSettings);
          },
          onCancel: () => Navigator.pop(context),
        ),
      ),
    );
  }

  void _showConfirmDialog(BuildContext context, dynamic updatedSettings) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Confirm Changes', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to update the business settings?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textLight)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx); // Close dialog
              final updatedShop = ShopEntity(
                shopId: shop.shopId,
                ownerId: shop.ownerId,
                shopName: shop.shopName,
                shopAddress: shop.shopAddress,
                category: shop.category,
                phone: shop.phone,
                settings: updatedSettings,
                createdAt: shop.createdAt,
                updatedAt: DateTime.now(),
                updatedById: shop.updatedById,
              );
              _updateShop(context, updatedShop);
              Navigator.pop(context); // Close page
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Confirm', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _updateShop(BuildContext context, ShopEntity updatedShop) {
    LoadingOverlay.show(context);
    context.read<ShopContextBloc>().add(UpdateShop(updatedShop));
  }
}
