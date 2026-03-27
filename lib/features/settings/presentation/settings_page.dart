import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:csms/core/theme/app_colors.dart';
import 'package:csms/features/shop/presentation/pages/shop_management_page.dart';
import 'package:csms/features/product/presentation/pages/product_management_page.dart';
import 'package:csms/features/product/presentation/bloc/product_bloc.dart';
import 'package:csms/features/staff/presentation/pages/staff_management_page.dart';
import 'package:csms/features/staff/presentation/bloc/staff_bloc.dart';
import 'package:csms/core/presentation/pages/webview_page.dart';
import 'package:csms/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:csms/features/auth/presentation/bloc/auth_event.dart';
import 'package:csms/features/auth/presentation/bloc/auth_state.dart';
import 'package:csms/features/auth/presentation/pages/login_page.dart';
import 'package:csms/features/profile/presentation/pages/profile_page.dart';
import 'package:csms/features/shop_subscription/presentation/pages/shop_subscription_page.dart';
import 'package:csms/injection_container.dart' as di;
import 'package:package_info_plus/package_info_plus.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Column(
                children: [
                  _buildMenuCard(context),
                  const SizedBox(height: 32),
                  _buildVersionFooter(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
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
                'Settings',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.2,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Manage your app settings',
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

  Widget _buildMenuCard(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    String role = '';
    if (authState is AuthAuthenticated) {
      role = authState.role.toLowerCase();
    }
    
    final bool isAdminOrManager = role == 'owner' || role == 'admin' || role == 'manager';

    final items = <_SettingItem>[
      _SettingItem(
        icon: Icons.person_outline,
        iconBg: const Color(0xFFE3F2FD),
        iconColor: const Color(0xFF1976D2),
        title: 'My Profile',
        subtitle: 'View and edit profile details',
        onTap: () {
          if (authState is AuthAuthenticated) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ProfilePage(userId: authState.userId)),
            );
          }
        },
      ),
      if (isAdminOrManager) ...[
        _SettingItem(
          icon: Icons.business_outlined,
          iconBg: const Color(0xFFE8EAF6),
          iconColor: const Color(0xFF3D5AFE),
          title: 'Business Management',
          subtitle: 'Edit business details',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ShopManagementPage()),
          ),
        ),
        _SettingItem(
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
        _SettingItem(
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
        _SettingItem(
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
      _SettingItem(
        icon: Icons.description_outlined,
        iconBg: const Color(0xFFFFF3E0),
        iconColor: const Color(0xFFEF6C00),
        title: 'Terms & Conditions',
        subtitle: 'View terms of service',
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const WebViewPage(
              title: 'Terms & Conditions',
              url: 'https://csms-saas-platform.web.app/legal/terms',
            ),
          ),
        ),
      ),
      _SettingItem(
        icon: Icons.security_outlined,
        iconBg: const Color(0xFFE8EAF6),
        iconColor: const Color(0xFF3D5AFE),
        title: 'Privacy Policy',
        subtitle: 'View privacy policy',
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const WebViewPage(
              title: 'Privacy Policy',
              url: 'https://csms-saas-platform.web.app/legal/privacy',
            ),
          ),
        ),
      ),
      // _SettingItem(
      //   icon: Icons.logout,
      //   iconBg: const Color(0xFFFFEBEE),
      //   iconColor: const Color(0xFFE53935),
      //   title: 'Log Out',
      //   subtitle: 'Sign out of your account',
      //   titleColor: const Color(0xFFE53935),
      //   onTap: () => _confirmLogout(context),
      //   isLast: true,
      // ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: items
            .map((item) => _buildTile(item, isLast: item.isLast))
            .toList(),
      ),
    );
  }

  Widget _buildTile(_SettingItem item, {bool isLast = false}) {
    return Column(
      children: [
        InkWell(
          onTap: item.onTap,
          borderRadius: isLast
              ? const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                )
              : BorderRadius.zero,
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: item.iconBg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(item.icon, color: item.iconColor, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: item.titleColor ?? const Color(0xFF1A1A2E),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF9E9E9E),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: Color(0xFFBDBDBD),
                  size: 22,
                ),
              ],
            ),
          ),
        ),
        if (!isLast)
          const Divider(
            height: 1,
            thickness: 1,
            indent: 74,
            endIndent: 16,
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
        final buildNumber = snapshot.data?.buildNumber ?? '1';
        
        return Column(
          children: [
            Text(
              'Version $version',
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFFBDBDBD),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              '© 2026 Business Manager',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFFBDBDBD),
              ),
            ),
          ],
        );
      },
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AuthBloc>().add(SignOutRequested());
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
                (route) => false,
              );
            },
            child: const Text(
              'Log Out',
              style: TextStyle(color: Color(0xFFE53935)),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingItem {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Color? titleColor;
  final VoidCallback onTap;
  final bool isLast;

  const _SettingItem({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.titleColor,
    required this.onTap,
    this.isLast = false,
  });
}
