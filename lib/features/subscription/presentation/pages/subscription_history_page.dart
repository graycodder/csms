import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_colors.dart';
import 'package:csms/injection_container.dart' as di;
import '../bloc/subscription_bloc.dart';
import 'package:csms/core/utils/terminology_helper.dart';

class SubscriptionHistoryPage extends StatelessWidget {
  final String shopId;
  final String ownerId;
  final String? customerId;
  final String? customerName;
  final String shopCategory;

  const SubscriptionHistoryPage({
    super.key,
    required this.shopId,
    required this.ownerId,
    this.customerId,
    this.customerName,
    required this.shopCategory,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => di.sl<SubscriptionBloc>()
        ..add(LoadSubscriptionHistory(
          shopId: shopId,
          ownerId: ownerId,
          customerId: customerId,
        )),
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: Text('${TerminologyHelper.getTerminology(shopCategory).subscriptionLabel} History',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.sp),
          ),
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: AppColors.textDark,
        ),
        body: BlocBuilder<SubscriptionBloc, SubscriptionState>(
          builder: (context, state) {
            if (state is SubscriptionLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is SubscriptionError) {
              return Center(child: Text('Error: ${state.message}', style: TextStyle(fontSize: 14.sp)));
            } else if (state is SubscriptionHistoryLoaded) {
              if (state.logs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history_outlined, size: 64.sp, color: Colors.grey[300]),
                      SizedBox(height: 16.h),
                      Text(
                        'No history found',
                        style: TextStyle(color: Colors.grey[500], fontSize: 16.sp),
                      ),
                    ],
                  ),
                );
              }

              return ListView.separated(
                padding: EdgeInsets.all(16.r),
                itemCount: state.logs.length,
                separatorBuilder: (context, index) => SizedBox(height: 12.h),
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

  Widget _buildLogCard(dynamic log) {
    final bool isRenewal = log.action.toLowerCase() == 'renew';
    final Color accentColor = isRenewal ? const Color(0xFF27AE60) : AppColors.primary;
    final IconData icon = isRenewal ? Icons.refresh : Icons.add_circle_outline;

    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10.r,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(10.r),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(icon, color: accentColor, size: 24.sp),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      log.action.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                        color: accentColor,
                        letterSpacing: 0.5.w,
                      ),
                    ),
                    Text(
                      DateFormat('MMM dd, yyyy • hh:mm a').format(log.createdAt),
                      style: TextStyle(fontSize: 12.sp, color: Colors.grey[400]),
                    ),
                  ],
                ),
                SizedBox(height: 10.h),
                if (log.productName != null) ...[
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                        child: Text(
                          log.productName!,
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      if (log.status != null) ...[
                        SizedBox(width: 8.w),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                          decoration: BoxDecoration(
                            color: log.status == 'active' ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                          child: Text(
                            log.status!.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.bold,
                              color: log.status == 'active' ? Colors.green : Colors.grey,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  SizedBox(height: 8.h),
                ],
                Text(
                  log.description,
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textDark,
                  ),
                ),
                SizedBox(height: 8.h),
                if (log.startDate != null && log.endDate != null) ...[
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 14.sp, color: Colors.grey[500]),
                      SizedBox(width: 4.w),
                      Text(
                        '${DateFormat('MMM dd, yyyy').format(log.startDate!)} - ${DateFormat('MMM dd, yyyy').format(log.endDate!)}',
                        style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  SizedBox(height: 4.h),
                ],
                if (log.price != null && log.price! > 0) ...[
                  Row(
                    children: [
                      Icon(Icons.payments_outlined, size: 14.sp, color: Colors.grey[500]),
                      SizedBox(width: 4.w),
                      Text(
                        'Price: ₹${log.price!.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 12.sp, 
                          color: const Color(0xFF27AE60),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4.h),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
