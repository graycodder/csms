import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:csms/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:csms/features/auth/presentation/bloc/auth_state.dart';
import 'package:csms/features/customer/presentation/bloc/customer_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:csms/core/theme/app_colors.dart';
import 'package:csms/core/utils/date_utils.dart';
import 'package:csms/core/utils/launcher_utils.dart';
import 'package:csms/core/utils/terminology_helper.dart';
import 'package:csms/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:csms/features/subscription/domain/entities/subscription_entity.dart';
import 'package:csms/features/customer/domain/entities/customer_entity.dart';
import 'package:csms/features/dashboard/presentation/widgets/whatsapp_reminder_banner.dart';
import 'package:csms/features/customer/presentation/pages/customer_details_page.dart';

class CustomerCard extends StatelessWidget {
  final CustomerEntity customer;
  final DashboardLoaded state;
  final BusinessTerminology term;
  final String selectedProductId;
  final String Function(DateTime) formatDate;
  final VoidCallback? onReturn;

  const CustomerCard({
    super.key,
    required this.customer,
    required this.state,
    required this.term,
    required this.selectedProductId,
    required this.formatDate,
    this.onReturn,
  });

  @override
  Widget build(BuildContext context) {
    final allSubs = [
      ...state.activeSubs.where((s) => s.customerId == customer.customerId),
      ...state.expiringSoon.where((s) => s.customerId == customer.customerId),
    ];

    // Filter to show only the subscription with the latest end date for each product
    final Map<String, SubscriptionEntity> latestSubsPerProduct = {};
    for (var sub in allSubs) {
      final current = latestSubsPerProduct[sub.productId];
      if (current == null || sub.endDate.isAfter(current.endDate)) {
        latestSubsPerProduct[sub.productId] = sub;
      }
    }
    final uniqueSubs = latestSubsPerProduct.values.toList();

    // Sort by expiry (most urgent first)
    uniqueSubs.sort((a, b) => a.endDate.compareTo(b.endDate));

    // Priority 1: Subscription matching the selected product chip
    // Priority 2: Most urgent active subscription
    final sub =
        uniqueSubs.where((s) => s.productId == selectedProductId).firstOrNull ??
        uniqueSubs.firstOrNull;

    final daysLeft = sub != null
        ? AppDateUtils.calculateDaysLeft(sub.endDate)
        : -1;
    final warningThreshold = state.shop.settings.expiredDaysBefore;

    final productNames = uniqueSubs
        .map((s) {
          final p = state.products
              .where((prod) => prod.productId == s.productId)
              .firstOrNull;
          return p?.name ?? s.productId;
        })
        .toList()
        .join(', ');

    final isExpired = daysLeft < 0;
    final isWarn = !isExpired && daysLeft <= warningThreshold;

    final Color statusColor = isExpired
        ? Colors.red
        : (isWarn ? const Color(0xFFE67E22) : const Color(0xFF27AE60));
    final Color bgColor = isExpired
        ? Colors.red.withOpacity(0.1)
        : (isWarn ? const Color(0xFFFFF3E0) : const Color(0xFFE8F5E9));

    // final price = sub != null ? sub.price.toStringAsFixed(0) : '—';

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                CustomerDetailsPage(customerId: customer.customerId),
          ),
        ).then((_) {
          if (onReturn != null) onReturn!();
        });
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 16.h),
        padding: EdgeInsets.only(
          left: 20.r,
          right: 20.r,
          top: 15.r,
          bottom: 15.r,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 8.r,
              offset: Offset(0, 4.h),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (customer.status == 'inactive') ...[
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(6.r),
                  border: Border.all(color: Colors.grey[300]!, width: 0.5.w),
                ),
                child: Text(
                  'INACTIVE',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 9.sp,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
            // Name + badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          customer.name,
                          // customer.name[0].toUpperCase() + customer.name.substring(1).toLowerCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1A1A1A),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8.w),
                if (sub != null)
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 10.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Text(
                      daysLeft >= 0 ? '$daysLeft days left' : 'Expired',
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 4.h),
            // Phone + Multiple Products
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                InkWell(
                  onTap: () =>
                      AppLauncherUtils.makePhoneCall(customer.mobileNumber),
                  child: Row(
                    children: [
                      Icon(Icons.call, size: 14.sp, color: Colors.grey[400]),
                      SizedBox(width: 4.w),
                      Text(
                        customer.mobileNumber,
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 13.sp,
                        ),
                      ),
                    ],
                  ),
                ),

                if (uniqueSubs.length > 1)
                  Text(
                    '${uniqueSubs.length} Plans',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
            if (productNames.isNotEmpty) ...[
              SizedBox(height: 6.h),
              Text(
                productNames,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.textDark.withOpacity(0.7),
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
            SizedBox(height: 5.h),
            const Divider(height: 1, color: Color(0xFFF0F0F0)),
            SizedBox(height: 5.h),
            // Expiry + price
            Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 15.sp,
                  color: Colors.grey[400],
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    sub != null
                        ? 'Expires: ${formatDate(sub.endDate)}'
                        : 'No active subscription',
                    style: TextStyle(color: Colors.grey[500], fontSize: 13.sp),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      sub != null
                          ? '₹${sub.paidAmount.toStringAsFixed(0)}'
                          : '₹0',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1A1A1A),
                      ),
                    ),
                    if (sub != null && sub.balanceAmount > 0) ...[
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => _showBalanceCollectionDialog(
                          context,
                          sub,
                          customer,
                        ),
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 2.h),
                          child: Text(
                            'Bal: ₹${sub.balanceAmount.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                              //decoration: TextDecoration.underline,
                              decorationColor: Colors.red,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            // Warning banner
            if (sub != null && isWarn) ...[
              SizedBox(height: 7.h),
              WhatsappReminderBanner(
                shop: state.shop,
                customer: customer,
                sub: sub,
                daysLeft: daysLeft,
                products: state.products,
                formatDate: formatDate,
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showBalanceCollectionDialog(
    BuildContext pageContext,
    SubscriptionEntity sub,
    CustomerEntity customer,
  ) {
    if (sub.balanceAmount <= 0) return;

    final TextEditingController amountController = TextEditingController();
    String selectedPaymentMode = 'Cash';
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: pageContext,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.r),
              ),
              title: Text(
                'Collect Balance',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.sp),
              ),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Plan Amount:',
                          style: TextStyle(
                            color: AppColors.textLight,
                            fontSize: 13.sp,
                          ),
                        ),
                        Text(
                          '₹${sub.price.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14.sp,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Pending Balance:',
                          style: TextStyle(
                            color: AppColors.textLight,
                            fontSize: 13.sp,
                          ),
                        ),
                        Text(
                          '₹${sub.balanceAmount.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                            fontSize: 14.sp,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      'Received Amount *',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13.sp,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    TextFormField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*\.?\d*'),
                        ),
                      ],
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: 'Enter amount',
                        prefixIcon: const Icon(Icons.currency_rupee, size: 18),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 8.h,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Enter amount';
                        }
                        final amt = double.tryParse(value);
                        if (amt == null || amt <= 0) return 'Invalid amount';
                        if (amt > sub.balanceAmount) {
                          return 'Cannot exceed pending balance';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      'Payment Mode *',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13.sp,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    DropdownButtonFormField<String>(
                      value: selectedPaymentMode,
                      decoration: InputDecoration(
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 8.h,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      ),
                      items: ['Cash', 'UPI', 'Card', 'Bank Transfer'].map((m) {
                        return DropdownMenuItem(
                          value: m,
                          child: Text(m, style: TextStyle(fontSize: 14.sp)),
                        );
                      }).toList(),
                      onChanged: (v) =>
                          setState(() => selectedPaymentMode = v ?? 'Cash'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: AppColors.textLight),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (formKey.currentState?.validate() ?? false) {
                      final addedAmt = double.parse(amountController.text);
                      final newPaidAmount = sub.paidAmount + addedAmt;

                      final authState = pageContext.read<AuthBloc>().state;
                      final updatedByName = authState is AuthAuthenticated
                          ? authState.name
                          : 'Staff';
                      final updatedById = authState is AuthAuthenticated
                          ? authState.userId
                          : sub.updatedById;

                      pageContext.read<CustomerBloc>().add(
                        UpdateSubscription(
                          subscriptionId: sub.subscriptionId,
                          endDate: sub.endDate,
                          price: sub.price,
                          paidAmount: newPaidAmount,
                          paymentMode: selectedPaymentMode,
                          updatedById: updatedById,
                          ownerId: sub.ownerId,
                          shopId: sub.shopId,
                          updatedByName: updatedByName,
                          customerName: customer.name,
                          status: sub.status,
                        ),
                      );

                      Navigator.pop(dialogContext);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                  child: const Text(
                    'Confirm',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
