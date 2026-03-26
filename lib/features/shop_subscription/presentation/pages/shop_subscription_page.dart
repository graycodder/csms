import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:csms/core/theme/app_colors.dart';
import 'package:csms/features/shop/presentation/bloc/shop_context_bloc.dart';
import '../bloc/shop_subscription_bloc.dart';
import 'shop_subscription_history_page.dart';
import 'package:csms/injection_container.dart' as di;

class ShopSubscriptionPage extends StatelessWidget {
  const ShopSubscriptionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final shopState = context.read<ShopContextBloc>().state;
        final bloc = di.sl<ShopSubscriptionBloc>();
        if (shopState is ShopSelected) {
          bloc.add(LoadShopSubscriptionStatus(shopState.selectedShop.shopId));
        }
        return bloc;
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(
            'Business Subscription',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: AppColors.textDark,
        ),
        body: BlocBuilder<ShopSubscriptionBloc, ShopSubscriptionState>(
          builder: (context, state) {
            if (state is ShopSubscriptionLoading || state is ShopSubscriptionInitial) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is ShopSubscriptionError) {
              return Center(
                child: Text(
                  state.message,
                  style: TextStyle(color: AppColors.errorText),
                ),
              );
            }

            if (state is ShopSubscriptionStatusLoaded) {
              final status = state.status;
              final active = status.activePlan;
              final now = DateTime.now();
              final isExpired = active == null || active.status == 'expired' || active.endDate.isBefore(now);

              final Color statusColor = isExpired ? AppColors.errorText : AppColors.success;
              final Color statusBg = isExpired ? AppColors.errorBg : AppColors.successBg;

              return SingleChildScrollView(
                padding: EdgeInsets.all(20.r),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status Card
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(24.r),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24.r),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 16.r,
                            offset: Offset(0, 8.h),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            status.shopName,
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          if (active != null) ...[
                             SizedBox(height: 4.h),
                             Text(
                              active.planName,
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                          SizedBox(height: 32.h),
                          const Divider(height: 1, color: AppColors.border),
                          SizedBox(height: 24.h),
                          _buildInfoRow(
                            'Start Date',
                            active != null
                                ? DateFormat('MMMM dd, yyyy').format(active.startDate)
                                : 'N/A',
                            Icons.calendar_today_outlined,
                          ),
                          SizedBox(height: 16.h),
                          _buildInfoRow(
                            'Expiry Date',
                            active != null
                                ? DateFormat('MMMM dd, yyyy').format(active.endDate)
                                : 'No active plan',
                            Icons.event_available_outlined,
                          ),
                          SizedBox(height: 16.h),
                          _buildInfoRow(
                            'Status',
                            active != null ? active.status.toUpperCase() : 'N/A',
                            Icons.check_circle_outline_rounded,
                          ),
                          if (active != null) ...[
                            SizedBox(height: 16.h),
                            _buildInfoRow(
                              'Plan Price',
                              '₹${active.price.toStringAsFixed(2)}',
                              Icons.payments_outlined,
                            ),
                          ],
                        ],
                      ),
                    ),
                    SizedBox(height: 32.h),
                    Text(
                      'Actions',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    SizedBox(height: 12.h),
                    _buildActionTile(
                      context,
                      title: 'Subscription History',
                      subtitle: 'View past transaction records',
                      icon: Icons.history_rounded,
                      color: Colors.orange,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ShopSubscriptionHistoryPage(
                              shopId: status.shopId,
                              ownerId: 'N/A',
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              );
            }
            return const SizedBox();
          },
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18.w, color: AppColors.textLight),
        SizedBox(width: 12.w),
        Text(
          label,
          style: TextStyle(
            color: AppColors.textLight,
            fontSize: 14.sp,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
            fontSize: 14.sp,
          ),
        ),
      ],
    );
  }

  Widget _buildActionTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18.r),
      child: Container(
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24.w),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: AppColors.textLight,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: AppColors.textLight, size: 20.w),
          ],
        ),
      ),
    );
  }
}
