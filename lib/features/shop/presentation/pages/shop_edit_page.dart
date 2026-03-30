import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
        title: Text(
          'Edit Business Info',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20.sp,
          ),
        ),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: BlocListener<ShopContextBloc, ShopContextState>(
        listener: (context, state) {
          if (state is ShopSelected) {
            LoadingOverlayHelper.hide();
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Business information updated successfully!'),
                  backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          } else if (state is ShopContextError) {
            LoadingOverlayHelper.hide();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20.r),
          child: ShopEditCard(
            shop: shop,
            onSave: (name, shopAddress, category, phone) {
              FocusManager.instance.primaryFocus?.unfocus();
              _showConfirmDialog(context, name, shopAddress, category, phone);
            },
            onCancel: () => Navigator.pop(context),
          ),
        ),
      ),
    );
  }

  void _showConfirmDialog(BuildContext context, String name, String address, String category, String phone) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: Text('Confirm Changes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.sp)),
        content: Text('Are you sure you want to update the business information?', style: TextStyle(fontSize: 14.sp)),
        actions: [
          TextButton(
            onPressed: () {
              FocusManager.instance.primaryFocus?.unfocus();
              Navigator.pop(ctx);
            },
            child: Text('Cancel', style: TextStyle(color: AppColors.textLight, fontSize: 14.sp)),
          ),
          ElevatedButton(
            onPressed: () {
              FocusManager.instance.primaryFocus?.unfocus();
              Navigator.pop(ctx); // Close dialog
              final updatedShop = ShopEntity(
                shopId: shop.shopId,
                ownerId: shop.ownerId,
                shopName: name,
                shopAddress: address,
                category: category,
                phone: phone,
                settings: shop.settings,
                createdAt: shop.createdAt,
                updatedAt: DateTime.now(),
                updatedById: shop.updatedById,
              );
              _updateShop(context, updatedShop);
              // Navigator.pop(context); // REMOVED: Wait for Bloc state to pop
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
            ),
            child: Text('Confirm', style: TextStyle(color: Colors.white, fontSize: 14.sp)),
          ),
        ],
      ),
    );
  }

  void _updateShop(BuildContext context, ShopEntity updatedShop) {
    LoadingOverlayHelper.show(context);
    context.read<ShopContextBloc>().add(UpdateShop(updatedShop));
  }
}
