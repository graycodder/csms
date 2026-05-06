import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:csms/core/theme/app_colors.dart';
import 'package:csms/features/shop/domain/entities/shop_entity.dart';
import 'package:csms/features/shop/presentation/bloc/shop_context_bloc.dart';
import 'package:csms/features/shop/presentation/widgets/shop_settings_edit_card_web.dart';
import 'package:csms/core/utils/loading_overlay.dart';
import 'package:csms/core/widgets/web_sidebar.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ShopSettingsEditPageWeb extends StatelessWidget {
  final ShopEntity shop;

  const ShopSettingsEditPageWeb({super.key, required this.shop});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      body: Row(
        children: [
          const WebSidebar(selectedIndex: 3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(context),
                Expanded(
                  child: BlocListener<ShopContextBloc, ShopContextState>(
                    listener: (context, state) {
                      if (state is ShopSelected &&
                          state.actionSuccessMessage != null) {
                        LoadingOverlayHelper.hide();
                        if (Navigator.canPop(context)) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(state.actionSuccessMessage!),
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 32,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: 800.w),
                          child: _buildFormCard(context),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      height: 120,
      padding: const EdgeInsets.symmetric(horizontal: 40),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          InkWell(
            onTap: () => Navigator.pop(context),
            borderRadius: BorderRadius.circular(24),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_back,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 24),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Business Settings',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Update your business operational settings',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ShopSettingsEditCardWeb(
        settings: shop.settings,
        onSave: (updatedSettings) {
          FocusManager.instance.primaryFocus?.unfocus();
          _showConfirmDialog(context, updatedSettings);
        },
        onCancel: () => Navigator.pop(context),
      ),
    );
  }

  void _showConfirmDialog(BuildContext context, dynamic updatedSettings) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Confirm Changes',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        content: const Text(
          'Are you sure you want to update the business settings?',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () {
              FocusManager.instance.primaryFocus?.unfocus();
              Navigator.pop(ctx);
            },
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textLight, fontSize: 14),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              FocusManager.instance.primaryFocus?.unfocus();
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
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Confirm',
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
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
