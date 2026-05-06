import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:csms/core/theme/app_colors.dart';
import 'package:csms/features/shop/presentation/pages/shop_management_page.dart';
import 'package:csms/features/product/presentation/pages/product_management_page.dart';
import 'package:csms/features/product/presentation/bloc/product_bloc.dart';
import 'package:csms/features/staff/presentation/pages/staff_management_page.dart';
import 'package:csms/features/staff/presentation/bloc/staff_bloc.dart';
import 'package:csms/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:csms/features/auth/presentation/bloc/auth_state.dart';
import 'package:csms/features/profile/presentation/pages/profile_page.dart';
import 'package:csms/features/shop_subscription/presentation/pages/shop_subscription_page.dart';
import 'package:csms/injection_container.dart' as di;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:csms/core/widgets/web_sidebar.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsPageWeb extends StatelessWidget {
  const SettingsPageWeb({super.key});

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
                  child: ListView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 32,
                    ),
                    children: [
                      _buildMenuCard(context),
                      const SizedBox(height: 40),
                      _buildVersionFooter(),
                      const SizedBox(height: 40),
                    ],
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
                'Settings',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Manage your app settings',
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

  Widget _buildMenuCard(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    String role = '';
    if (authState is AuthAuthenticated) {
      role = authState.role.toLowerCase();
    }

    final bool isAdminOrManager =
        role == 'owner' || role == 'admin' || role == 'manager';

    final items = <_SettingItemWeb>[
      _SettingItemWeb(
        icon: Icons.person_outline,
        iconBg: const Color(0xFFE3F2FD),
        iconColor: const Color(0xFF1976D2),
        title: 'Profile',
        subtitle: 'View your profile',
        onTap: () {
          if (authState is AuthAuthenticated) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProfilePage(userId: authState.userId),
              ),
            );
          }
        },
      ),
      if (isAdminOrManager) ...[
        _SettingItemWeb(
          icon: Icons.store_outlined,
          iconBg: const Color(0xFFE8EAF6),
          iconColor: const Color(0xFF3D5AFE),
          title: 'Shop Management',
          subtitle: 'Edit shop details',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ShopManagementPage()),
          ),
        ),
        _SettingItemWeb(
          icon: Icons.inventory_2_outlined,
          iconBg: const Color(0xFFEDE7F6),
          iconColor: const Color(0xFF7C4DFF),
          title: 'Product Management',
          subtitle: 'Manage products',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BlocProvider(
                create: (_) => di.sl<ProductBloc>(),
                child: const ProductManagementPage(),
              ),
            ),
          ),
        ),
        _SettingItemWeb(
          icon: Icons.people_outline,
          iconBg: const Color(0xFFE8F5E9),
          iconColor: const Color(0xFF2E7D32),
          title: 'Staff Management',
          subtitle: 'Manage team members',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BlocProvider(
                create: (_) => di.sl<StaffBloc>(),
                child: const StaffManagementPage(),
              ),
            ),
          ),
        ),
        _SettingItemWeb(
          icon: Icons.card_membership_outlined,
          iconBg: const Color(0xFFFCE4EC),
          iconColor: const Color(0xFFC2185B),
          title: 'Business Subscription',
          subtitle: 'Manage your business subscription',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ShopSubscriptionPage()),
          ),
        ),
      ],
      _SettingItemWeb(
        icon: Icons.description_outlined,
        iconBg: const Color(0xFFFFF3E0),
        iconColor: const Color(0xFFEF6C00),
        title: 'Terms & Conditions',
        subtitle: 'View terms of service',
        onTap: () => launchUrl(
          Uri.parse('https://csms-saas-platform.web.app/legal/terms'),
          mode: LaunchMode.externalApplication,
        ),
      ),
      _SettingItemWeb(
        icon: Icons.security_outlined,
        iconBg: const Color(0xFFE8EAF6),
        iconColor: const Color(0xFF3D5AFE),
        title: 'Privacy Policy',
        subtitle: 'View privacy policy',
        onTap: () => launchUrl(
          Uri.parse('https://csms-saas-platform.web.app/legal/privacy'),
          mode: LaunchMode.externalApplication,
        ),
      ),
    ];

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final isLast = entry.key == items.length - 1;
          return _buildTile(entry.value, isLast: isLast);
        }).toList(),
      ),
    );
  }

  Widget _buildTile(_SettingItemWeb item, {bool isLast = false}) {
    return Column(
      children: [
        InkWell(
          onTap: item.onTap,
          borderRadius: isLast
              ? const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                )
              : BorderRadius.zero,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: item.iconBg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(item.icon, color: item.iconColor, size: 24),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.subtitle,
                        style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
              ],
            ),
          ),
        ),
        if (!isLast)
          const Divider(
            height: 1,
            indent: 92,
            endIndent: 24,
            color: Color(0xFFF0F0F0),
          ),
      ],
    );
  }

  Widget _buildVersionFooter() {
    return FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (context, snapshot) {
        final version = snapshot.data?.version ?? '1.0.0';
        return Column(
          children: [
            Text(
              'Version $version',
              style: TextStyle(fontSize: 13, color: Colors.grey[400]),
            ),
            const SizedBox(height: 4),
            Text(
              '© 2026 Subscription Manager',
              style: TextStyle(fontSize: 12, color: Colors.grey[400]),
            ),
          ],
        );
      },
    );
  }
}

class _SettingItemWeb {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingItemWeb({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
}
