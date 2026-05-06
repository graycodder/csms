import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:csms/core/theme/app_colors.dart';
import 'package:csms/features/shop/presentation/bloc/shop_context_bloc.dart';
import 'package:csms/features/shop/presentation/pages/shop_edit_page.dart';
import 'package:csms/features/shop/presentation/pages/shop_settings_edit_page.dart';
import 'package:csms/features/shop/domain/entities/shop_entity.dart';
import 'package:csms/core/utils/loading_overlay.dart';
import 'package:csms/core/widgets/web_sidebar.dart';

class ShopManagementPageWeb extends StatelessWidget {
  const ShopManagementPageWeb({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      body: Row(
        children: [
          const WebSidebar(selectedIndex: 3),
          Expanded(
            child: Column(
              children: [
                _buildHeader(context),
                Expanded(
                  child: BlocConsumer<ShopContextBloc, ShopContextState>(
                    listener: (context, state) {
                      if (state is ShopSelected || state is ShopContextError) {
                        LoadingOverlayHelper.hide();
                      }
                    },
                    builder: (context, state) {
                      if (state is ShopSelected) {
                        return ListView(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 40,
                            vertical: 32,
                          ),
                          children: [
                            _buildShopInfoCard(context, state.selectedShop),
                            const SizedBox(height: 32),
                            _buildShopSettingsCard(context, state.selectedShop),
                            const SizedBox(height: 40),
                          ],
                        );
                      } else if (state is ShopContextLoading) {
                        return const Center(child: AppLoadingSpinner(size: 48));
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
          ),
        ],
      ),
    );
  }


  Widget _buildHeader(BuildContext context) {
    return Container(
      height: 120,
      padding: const EdgeInsets.symmetric(horizontal: 40),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: const BorderRadius.only(
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
                'Shop Management',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Configure and manage',
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

  Widget _buildShopInfoCard(BuildContext context, ShopEntity shop) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(
              left: 32,
              right: 24,
              top: 24,
              bottom: 16,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Shop Information',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ShopEditPage(shop: shop),
                      ),
                    );
                  },
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Edit'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF0F0F0)),
          Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('Shop Name', shop.shopName, Icons.store_outlined),
                const SizedBox(height: 24),
                _buildInfoRow(
                  'Location',
                  shop.shopAddress,
                  Icons.location_on_outlined,
                ),
                const SizedBox(height: 24),
                _buildInfoRow(
                  'Phone Number',
                  shop.phone ?? 'Not provided',
                  Icons.phone_outlined,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[500],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(icon, size: 20, color: Colors.grey[400]),
            const SizedBox(width: 12),
            Text(
              value,
              style: const TextStyle(fontSize: 16, color: Colors.black87),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildShopSettingsCard(BuildContext context, ShopEntity shop) {
    final settings = shop.settings;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(
              left: 32,
              right: 24,
              top: 24,
              bottom: 16,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Shop Settings',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ShopSettingsEditPage(shop: shop),
                      ),
                    );
                  },
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Edit'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF0F0F0)),
          _buildSettingsRow(
            'Reminder Days',
            'Days before expiration to notify',
            Text(
              '${settings.expiredDaysBefore} days',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF0F0F0)),
          _buildSettingsRow(
            'WhatsApp Reminder',
            'Send WhatsApp reminder for renewals',
            _buildBadge(
              settings.whatsappReminderEnabled ? 'Enabled' : 'Disabled',
              settings.whatsappReminderEnabled,
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF0F0F0)),
          _buildSettingsRow(
            'Show Registration Fees',
            'Display registration fees in customer',
            _buildBadge(
              settings.registrationFeeEnabled ? 'Enabled' : 'Disabled',
              settings.registrationFeeEnabled,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsRow(String title, String subtitle, Widget trailing) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }

  Widget _buildBadge(String text, bool isEnabled) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isEnabled
            ? Colors.green.withOpacity(0.1)
            : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isEnabled ? Colors.green[700] : Colors.grey[700],
        ),
      ),
    );
  }
}
