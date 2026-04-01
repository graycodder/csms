import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:csms/core/theme/app_colors.dart';
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
                  LoadingOverlayHelper.hide();
                } else if (state is ShopContextError) {
                  LoadingOverlayHelper.hide();
                }
              },
              builder: (context, state) {
                if (state is ShopSelected) {
                  final shop = state.selectedShop;
                  return SingleChildScrollView(
                    padding: EdgeInsets.all(16.r),
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
                        SizedBox(height: 20.h),
                        ShopSettingsCard(
                          settings: shop.settings,
                          shopCategory: shop.category,
                          onEdit: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    ShopSettingsEditPage(shop: shop),
                              ),
                            );
                          },
                        ),
                        SizedBox(height: 20.h),
                      ],
                    ),
                  );
                } else if (state is ShopContextLoading) {
                  return Center(
                    child: Lottie.asset(
                      'assets/animations/loading.json',
                      width: 80.w,
                      height: 80.w,
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Business Management',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22.sp,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.2,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  'Configure and manage',
                  style: TextStyle(color: Colors.white70, fontSize: 13.sp),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
