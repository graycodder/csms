import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:csms/core/theme/app_colors.dart';
import 'package:csms/features/shop/presentation/bloc/shop_context_bloc.dart';
import 'package:csms/features/dashboard/presentation/pages/dashboard_page.dart';

class ShopSelectionPage extends StatelessWidget {
  const ShopSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Select Business", style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textDark,
      ),
      body: BlocConsumer<ShopContextBloc, ShopContextState>(
        listener: (context, state) {
          if (state is ShopSelected) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const DashboardPage()),
            );
          }
        },
        builder: (context, state) {
          if (state is ShopContextLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ShopContextLoaded) {
            return ListView.separated(
              padding: EdgeInsets.all(24.r),
              itemCount: state.shops.length,
              separatorBuilder: (_, __) => SizedBox(height: 16.h),
              itemBuilder: (context, index) {
                final shop = state.shops[index];
                return ListTile(
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 24.w,
                    vertical: 12.h,
                  ),
                  tileColor: AppColors.primary.withOpacity(0.05),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.primary,
                    child: Icon(Icons.business_rounded, color: Colors.white),
                  ),
                  title: Text(
                    shop.shopName,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp),
                  ),
                  subtitle: Text(
                    shop.settings.notificationDaysBefore > 0
                        ? "Alerts: ${shop.settings.notificationDaysBefore} days before"
                        : "No alerts",
                    style: TextStyle(fontSize: 13.sp),
                  ),
                  trailing: Icon(Icons.arrow_forward_ios, size: 16.sp),
                  onTap: () {
                    context.read<ShopContextBloc>().add(SelectShop(shop, state.shops));
                  },
                );
              },
            );
          }

          if (state is ShopContextEmpty) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(32.r),
                child: Text(
                  "No business accounts found. Please complete onboarding.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16.sp, color: AppColors.textLight),
                ),
              ),
            );
          }

          if (state is ShopContextError) {
            return Center(child: Text(state.message));
          }

          return const Center(child: Text("Initializing..."));
        },
      ),
    ),
  );
}
}
