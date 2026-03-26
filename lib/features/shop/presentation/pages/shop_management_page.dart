import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:csms/core/theme/app_colors.dart';
import 'package:csms/features/shop/domain/entities/shop_entity.dart';
import 'package:csms/features/shop/presentation/bloc/shop_context_bloc.dart';
import 'package:csms/features/shop/presentation/widgets/shop_info_card.dart';
import 'package:csms/features/shop/presentation/widgets/shop_edit_card.dart';
import 'package:csms/features/shop/presentation/widgets/shop_settings_card.dart';
import 'package:csms/features/shop/presentation/widgets/shop_settings_edit_card.dart';
import 'package:lottie/lottie.dart';
import 'package:csms/core/utils/loading_overlay.dart';

class ShopManagementPage extends StatefulWidget {
  const ShopManagementPage({super.key});

  @override
  State<ShopManagementPage> createState() => _ShopManagementPageState();
}

class _ShopManagementPageState extends State<ShopManagementPage> {
  bool _isEditingInfo = false;
  bool _isEditingSettings = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: BlocConsumer<ShopContextBloc, ShopContextState>(
              listener: (context, state) {
                if (state is ShopSelected) {
                  LoadingOverlay.hide();
                } else if (state is ShopContextError) {
                  LoadingOverlay.hide();
                }
              },
              builder: (context, state) {
                if (state is ShopSelected) {
                  final shop = state.selectedShop;
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _isEditingInfo
                            ? ShopEditCard(
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
                                  setState(() => _isEditingInfo = false);
                                },
                                onCancel: () => setState(() => _isEditingInfo = false),
                              )
                            : ShopInfoCard(
                                shopName: shop.shopName,
                                shopAddress: shop.shopAddress,
                                shopCategory: shop.category,
                                shopPhone: shop.phone ?? '',
                                onEdit: () => setState(() => _isEditingInfo = true),
                              ),
                        const SizedBox(height: 20),
                        _isEditingSettings
                            ? ShopSettingsEditCard(
                                settings: shop.settings,
                                onSave: (updatedSettings) {
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
                                  setState(() => _isEditingSettings = false);
                                },
                                onCancel: () => setState(() => _isEditingSettings = false),
                              )
                            : ShopSettingsCard(
                                settings: shop.settings,
                                onEdit: () => setState(() => _isEditingSettings = true),
                              ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  );
                } else if (state is ShopContextLoading) {
                  return Center(
                    child: Lottie.asset(
                      'assets/animations/loading.json',
                      width: 80,
                      height: 80,
                    ),
                  );
                } else if (state is ShopContextError) {
                  return Center(
                    child: Text('Failed to load shop: ${state.message}'),
                  );
                }
                return const Center(child: Text('No shop selected.'));
              },
            ),
          ),
        ],
      ),
    );
  }

  void _updateShop(BuildContext context, ShopEntity updatedShop) {
    LoadingOverlay.show(context);
    context.read<ShopContextBloc>().add(UpdateShop(updatedShop));
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        left: 20,
        right: 20,
        bottom: 28,
      ),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Row(
        children: [
          InkWell(
            onTap: () => Navigator.pop(context),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_back,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 16),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Business Management',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.2,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Configure and manage',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
