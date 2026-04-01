import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:csms/core/theme/app_colors.dart';
import 'package:csms/features/shop/presentation/pages/shop_management_page.dart';
import 'package:csms/features/product/presentation/pages/product_management_page.dart';
import 'package:csms/features/product/presentation/bloc/product_bloc.dart';
import 'package:csms/features/staff/presentation/pages/staff_management_page.dart';
import 'package:csms/features/staff/presentation/bloc/staff_bloc.dart';
import 'package:csms/features/reports/presentation/pages/report_page.dart';
import 'package:csms/features/reports/presentation/bloc/report_bloc.dart';
import 'package:csms/core/presentation/pages/webview_page.dart';
import 'package:csms/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:csms/features/auth/presentation/bloc/auth_state.dart';
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
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.h),
              child: Column(
                children: [
                  _buildMenuCard(context),
                  SizedBox(height: 32.h),
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
        top: MediaQuery.of(context).padding.top + 16.h,
        left: 20.w,
        right: 20.w,
        bottom: 28.h,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28.r),
          bottomRight: Radius.circular(28.r),
        ),
      ),
      child: Row(
        children: [
          InkWell(
            onTap: () => Navigator.pop(context),
            borderRadius: BorderRadius.circular(20.r),
            child: Container(
              padding: EdgeInsets.all(8.r),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.arrow_back, color: Colors.white, size: 22.sp),
            ),
          ),
          SizedBox(width: 16.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Settings',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.2.w,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                'Manage your app settings',
                style: TextStyle(color: Colors.white70, fontSize: 13.sp),
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
              MaterialPageRoute(
                builder: (_) => ProfilePage(userId: authState.userId),
              ),
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
          icon: Icons.bar_chart_outlined,
          iconBg: const Color(0xFFE3F2FD),
          iconColor: const Color(0xFF0D47A1),
          title: 'Business Reports',
          subtitle: 'View performance & analytics',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BlocProvider(
                create: (_) => di.sl<ReportBloc>(),
                child: const ReportPage(),
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
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12.r,
            offset: Offset(0, 4.h),
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 44.w,
                  height: 44.w,
                  decoration: BoxDecoration(
                    color: item.iconBg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(item.icon, color: item.iconColor, size: 22.sp),
                ),
                SizedBox(width: 14.w),
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
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: const Color(0xFF9E9E9E),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: const Color(0xFFBDBDBD),
                  size: 22.sp,
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

        return Column(
          children: [
            Text(
              'Version $version',
              style: TextStyle(fontSize: 13.sp, color: const Color(0xFFBDBDBD)),
            ),
            SizedBox(height: 4.h),
            Text(
              '© 2026 Business Manager',
              style: TextStyle(fontSize: 12.sp, color: const Color(0xFFBDBDBD)),
            ),
          ],
        );
      },
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
    required this.onTap,
  }) : isLast = false,
       titleColor = null;
}
