import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:csms/core/theme/app_colors.dart';
import '../bloc/shop_subscription_bloc.dart';
import '../../domain/entities/shop_subscription_log_entity.dart';
import 'package:csms/injection_container.dart' as di;

class ShopSubscriptionHistoryPage extends StatelessWidget {
  final String shopId;
  final String ownerId;

  const ShopSubscriptionHistoryPage({
    super.key,
    required this.shopId,
    required this.ownerId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => di.sl<ShopSubscriptionBloc>()
        ..add(LoadShopSubscriptionHistory(
          shopId,
          ownerId,
        )),
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(
            'Subscription History',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: AppColors.textDark,
        ),
        body: BlocBuilder<ShopSubscriptionBloc, ShopSubscriptionState>(
          builder: (context, state) {
            if (state is ShopSubscriptionLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is ShopSubscriptionError) {
              return Center(
                child: Padding(
                  padding: EdgeInsets.all(24.r),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline_rounded, size: 48.w, color: AppColors.errorText),
                      SizedBox(height: 16.h),
                      Text(
                        state.message,
                        style: TextStyle(color: AppColors.textLight),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            } else if (state is ShopSubscriptionHistoryLoaded) {
              if (state.logs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history_rounded, size: 64.w, color: Colors.grey[300]),
                      SizedBox(height: 16.h),
                      Text(
                        'No history found',
                        style: TextStyle(
                          color: AppColors.textLight,
                          fontSize: 16.sp,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.separated(
                padding: EdgeInsets.all(20.r),
                itemCount: state.logs.length,
                separatorBuilder: (context, index) => SizedBox(height: 16.h),
                itemBuilder: (context, index) {
                  final log = state.logs[index];
                  return _buildLogCard(log);
                },
              );
            }
            return const SizedBox();
          },
        ),
      ),
    );
  }

  Widget _buildLogCard(ShopSubscriptionLogEntity log) {
    final bool isAssigned = log.action.toLowerCase() == 'assigned';
    final Color accentColor = isAssigned ? AppColors.success : AppColors.primary;
    final IconData icon = isAssigned ? Icons.star_rounded : Icons.refresh_rounded;

    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10.r,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      log.planName,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                    if (log.price != null)
                      Text(
                        '₹${log.price!.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                  ],
                ),
                if (log.startDate != null && log.endDate != null) ...[
                  SizedBox(height: 8.h),
                  Row(
                    children: [
                      Icon(Icons.date_range_outlined, size: 12.w, color: AppColors.textLight),
                      SizedBox(width: 4.w),
                      Text(
                        '${DateFormat('dd MMM yyyy').format(log.startDate!)} - ${DateFormat('dd MMM yyyy').format(log.endDate!)}',
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: AppColors.textLight,
                        ),
                      ),
                    ],
                  ),
                ],
                if (log.status != null) ...[
                  SizedBox(height: 12.h),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: log.status == 'active' ? AppColors.success.withOpacity(0.1) : AppColors.border.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    child: Text(
                      log.status!.toUpperCase(),
                      style: TextStyle(
                        fontSize: 9.sp,
                        fontWeight: FontWeight.bold,
                        color: log.status == 'active' ? AppColors.success : AppColors.textLight,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
