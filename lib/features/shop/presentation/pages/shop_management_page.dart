import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:csms/core/theme/app_colors.dart';
import 'package:csms/features/shop/domain/entities/shop_entity.dart';
import 'package:csms/features/shop/presentation/bloc/shop_context_bloc.dart';
import 'package:csms/features/shop/presentation/widgets/shop_info_card.dart';
import 'package:csms/features/shop/presentation/widgets/shop_settings_card.dart';
import 'package:csms/features/shop/presentation/pages/shop_edit_page.dart';
import 'package:csms/features/shop/presentation/pages/shop_settings_edit_page.dart';
import 'package:lottie/lottie.dart';
import 'package:csms/core/utils/loading_overlay.dart';

class ShopManagementPage extends StatefulWidget {
  const ShopManagementPage({super.key});

  @override
  State<ShopManagementPage> createState() => _ShopManagementPageState();
}

class _ShopManagementPageState extends State<ShopManagementPage> {

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
                        ShopInfoCard(
                          shopName: shop.shopName,
                          shopAddress: shop.shopAddress,
                          shopCategory: shop.category,
                          shopPhone: shop.phone ?? '',
                          onEdit: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ShopEditPage(shop: shop),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 20),
                        ShopSettingsCard(
                          settings: shop.settings,
                          onEdit: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ShopSettingsEditPage(shop: shop),
                              ),
                            );
                          },
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
