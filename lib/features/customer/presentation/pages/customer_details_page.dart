import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_colors.dart';
import 'edit_customer_page.dart';
import 'package:csms/features/subscription/presentation/pages/renew_subscription_page.dart';
import 'package:csms/features/subscription/presentation/pages/edit_subscription_page.dart';
import 'package:csms/features/subscription/presentation/pages/add_subscription_page.dart';
import 'package:csms/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:csms/features/customer/domain/entities/customer_entity.dart';
import 'package:csms/features/subscription/domain/entities/subscription_entity.dart';
import 'package:csms/features/product/domain/entities/product_entity.dart';
import 'package:csms/features/customer/presentation/bloc/customer_bloc.dart';
import 'package:csms/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:csms/features/auth/presentation/bloc/auth_state.dart';
import 'package:csms/features/subscription/presentation/pages/subscription_history_page.dart';
import 'package:csms/features/shop/presentation/bloc/shop_context_bloc.dart';
import 'package:csms/core/utils/date_utils.dart';
import 'package:csms/core/utils/launcher_utils.dart';
import 'package:csms/core/utils/terminology_helper.dart';
import 'package:csms/core/utils/loading_overlay.dart';

class CustomerDetailsPage extends StatelessWidget {
  final String customerId;

  const CustomerDetailsPage({super.key, required this.customerId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocListener<CustomerBloc, CustomerState>(
        listener: (context, state) {
          if (state is CustomerSuccess) {
            final shopState = context.read<ShopContextBloc>().state;
            final authState = context.read<AuthBloc>().state;
            if (shopState is ShopSelected && authState is AuthAuthenticated) {
              Future.delayed(const Duration(milliseconds: 300), () {
                if (context.mounted) {
                  context.read<DashboardBloc>().add(
                    LoadDashboardData(
                      shopId: shopState.selectedShop.shopId,
                      ownerId: authState.ownerId,
                    ),
                  );
                }
              });
            }
          } else if (state is CustomerError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error: ${state.message}'),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        child: BlocBuilder<DashboardBloc, DashboardState>(
          builder: (context, state) {
            if (state is DashboardLoaded) {
              final customer = state.customers
                  .where((c) => c.customerId == customerId)
                  .firstOrNull;
              final customerSubs = [
                ...state.activeSubs.where((s) => s.customerId == customerId),
                ...state.expiringSoon.where((s) => s.customerId == customerId),
              ];

              final Map<String, SubscriptionEntity> latestSubsPerProduct = {};
              for (var sub in customerSubs) {
                final current = latestSubsPerProduct[sub.productId];
                if (current == null || sub.endDate.isAfter(current.endDate)) {
                  latestSubsPerProduct[sub.productId] = sub;
                }
              }
              final uniqueSubs = latestSubsPerProduct.values.toList();
              final term = TerminologyHelper.getTerminology(
                state.shop.category,
              );

              if (customer == null) {
                return Scaffold(
                  appBar: AppBar(title: const Text('Error')),
                  body: Center(child: Text("${term.customerLabel} not found.")),
                );
              }

              return Stack(
                children: [
                  Container(
                    height: 320.h,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(30.r),
                        bottomRight: Radius.circular(30.r),
                      ),
                    ),
                  ),
                  SafeArea(
                    child: Column(
                      children: [
                        _buildAppBar(context, customer, state.products, state),
                        Expanded(
                          child: ListView(
                            padding: EdgeInsets.symmetric(
                              horizontal: 20.w,
                              vertical: 20.h,
                            ),
                            children: [
                              _buildHeaderInfo(customer),
                              SizedBox(height: 8.h),
                              _buildRegistrationFeeCard(
                                context,
                                customer,
                                uniqueSubs,
                              ),
                              SizedBox(height: 24.h),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Active ${term.planLabel}s',
                                    style: TextStyle(
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  BlocBuilder<AuthBloc, AuthState>(
                                    builder: (context, authState) {
                                      final existingProductIds = uniqueSubs
                                          .map((s) => s.productId)
                                          .toList();
                                      final availableProducts = state.products
                                          .where((p) {
                                            return p.status == 'active' &&
                                                !existingProductIds.contains(
                                                  p.productId,
                                                );
                                          })
                                          .toList();

                                      if (availableProducts.isEmpty) {
                                        return const SizedBox.shrink();
                                      }

                                      return TextButton.icon(
                                        onPressed: () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => BlocProvider.value(
                                              value: context
                                                  .read<CustomerBloc>(),
                                              child: AddSubscriptionPage(
                                                customerId: customer.customerId,
                                                customerName: customer.name,
                                                shopId: customer.shopId,
                                                ownerId: customer.ownerId,
                                                updatedById:
                                                    authState
                                                        is AuthAuthenticated
                                                    ? authState.userId
                                                    : '',
                                                updatedByName:
                                                    authState
                                                        is AuthAuthenticated
                                                    ? authState.name
                                                    : 'Staff',
                                                products: state.products,
                                                shopCategory:
                                                    state.shop.category,
                                                existingProductIds:
                                                    existingProductIds,
                                              ),
                                            ),
                                          ),
                                        ),
                                        icon: Icon(
                                          Icons.add,
                                          color: Colors.white,
                                          size: 18.sp,
                                        ),
                                        label: Text(
                                          'Add New ${term.planLabel}',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 13.sp,
                                          ),
                                        ),
                                        style: TextButton.styleFrom(
                                          backgroundColor: Colors.white
                                              .withOpacity(0.2),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12.r,
                                            ),
                                          ),
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 12.w,
                                            vertical: 8.h,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                              SizedBox(height: 5.h),
                              if (uniqueSubs.isEmpty)
                                Column(
                                  children: [
                                    SizedBox(height: 5.h),
                                    Center(
                                      child: Text(
                                        'No active ${term.planLabel.toLowerCase()}s found',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 14.sp,
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: 5.h),
                                  ],
                                )
                              else
                                ...uniqueSubs.map((sub) {
                                  final prod = state.products
                                      .where(
                                        (p) => p.productId == sub.productId,
                                      )
                                      .firstOrNull;
                                  return Padding(
                                    padding: EdgeInsets.only(bottom: 16.h),
                                    child: _buildSubscriptionCard(
                                      context,
                                      sub,
                                      prod,
                                      state,
                                      term,
                                      customer,
                                    ),
                                  );
                                }).toList(),
                              SizedBox(height: 100.h),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }
            return const LoadingOverlay();
          },
        ),
      ),
    );
  }

  String _fmt(DateTime d) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  Widget _buildSubscriptionCard(
    BuildContext context,
    SubscriptionEntity sub,
    ProductEntity? product,
    DashboardLoaded state,
    BusinessTerminology term,
    CustomerEntity customer,
  ) {
    if (product == null) return const SizedBox.shrink();
    final daysLeft = AppDateUtils.calculateDaysLeft(sub.endDate);
    final isExpired = daysLeft < 0;

    return Container(
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10.r,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          product.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                        if (sub.paymentStatus != 'paid') ...[
                          SizedBox(width: 8.w),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8.w,
                              vertical: 2.h,
                            ),
                            decoration: BoxDecoration(
                              color: sub.paymentStatus == 'unpaid'
                                  ? Colors.red.shade100
                                  : Colors.orange.shade100,
                              borderRadius: BorderRadius.circular(4.r),
                            ),
                            child: Text(
                              sub.paymentStatus.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10.sp,
                                fontWeight: FontWeight.bold,
                                color: sub.paymentStatus == 'unpaid'
                                    ? Colors.red.shade700
                                    : Colors.orange.shade700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    SizedBox(height: 4.h),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: isExpired ? Colors.red[50] : Colors.green[50],
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text(
                        isExpired ? 'Expired' : 'Active',
                        style: TextStyle(
                          color: isExpired ? Colors.red : Colors.green,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 12.w),
              BlocBuilder<AuthBloc, AuthState>(
                builder: (context, authState) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditSubscriptionPage(
                              subscription: sub,
                              productName: product.name,
                              shopCategory: state.shop.category,
                              customerName: customer.name,
                              priceType: product.priceType,
                            ),
                          ),
                        ),
                        icon: Icon(
                          Icons.edit_outlined,
                          color: Colors.grey[600],
                          size: 20.sp,
                        ),
                        tooltip: 'Correct Details',
                      ),
                      IconButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => BlocProvider.value(
                                value: context.read<CustomerBloc>(),
                                child: RenewSubscriptionPage(
                                  subscriptionId: sub.subscriptionId,
                                  shopId: sub.shopId,
                                  currentEndDate: sub.endDate,
                                  ownerId: authState is AuthAuthenticated
                                      ? authState.ownerId
                                      : '',
                                  productName: product.name,
                                  validityUnit: product.validityUnit,
                                  validityValue: product.validityValue,
                                  priceType: product.priceType,
                                  validityType: product.validityType,
                                  basePrice: product.price,
                                  shopCategory: state.shop.category,
                                  customerName: customer.name,
                                  currentBalance: sub.balanceAmount,
                                ),
                              ),
                            ),
                          );
                        },
                        icon: Icon(
                          Icons.autorenew,
                          color: AppColors.primary,
                          size: 24.sp,
                        ),
                        tooltip: 'Renew Plan',
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
          Divider(height: 32.h, color: const Color(0xFFF0F0F0)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Expiry Date',
                    style: TextStyle(
                      color: AppColors.textLight,
                      fontSize: 13.sp,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    _fmt(sub.endDate),
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                      fontSize: 15.sp,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: sub.balanceAmount > 0
                    ? () => _showBalanceCollectionDialog(context, sub, customer)
                    : null,
                borderRadius: BorderRadius.circular(8.r),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        sub.balanceAmount > 0 ? 'Paid Amount' : 'Price',
                        style: TextStyle(
                          color: sub.balanceAmount > 0
                              ? AppColors.primary
                              : AppColors.textLight,
                          fontSize: 13.sp,
                          fontWeight: sub.balanceAmount > 0
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      if (sub.balanceAmount > 0)
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: '₹${sub.paidAmount.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                  fontSize: 15.sp,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                              TextSpan(
                                text: ' / ₹${sub.price.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textLight,
                                  fontSize: 12.sp,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        Text(
                          '₹${sub.price.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                            fontSize: 15.sp,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Days Left',
                    style: TextStyle(
                      color: AppColors.textLight,
                      fontSize: 13.sp,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    isExpired ? '0 days' : '$daysLeft days',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15.sp,
                      color: isExpired ? Colors.red : AppColors.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(
    BuildContext context,
    CustomerEntity customer,
    List<ProductEntity> products,
    DashboardLoaded state,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildCircleIconButton(
            Icons.arrow_back,
            () => Navigator.pop(context),
          ),
          Expanded(
            child: Center(
              child: Text(
                "${TerminologyHelper.getTerminology(state.shop.category).customerLabel} Details",
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          Row(
            children: [
              _buildCircleIconButton(Icons.history, () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SubscriptionHistoryPage(
                      shopId: customer.shopId,
                      ownerId: customer.ownerId,
                      customerId: customer.customerId,
                      customerName: customer.name,
                      shopCategory: state.shop.category,
                    ),
                  ),
                );
              }),
              SizedBox(width: 8.w),
              _buildCircleIconButton(Icons.edit_outlined, () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BlocProvider.value(
                      value: context.read<CustomerBloc>(),
                      child: EditCustomerPage(
                        customer: customer,
                        products: products,
                        shopCategory: state.shop.category,
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCircleIconButton(IconData icon, VoidCallback onPressed) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(20.r),
      child: Container(
        padding: EdgeInsets.all(8.r),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 24.sp),
      ),
    );
  }

  Widget _buildHeaderInfo(CustomerEntity customer) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          customer.name,
          //customer.name[0].toUpperCase() + customer.name.substring(1).toLowerCase(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white,
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        //  SizedBox(height: 8.h),
        InkWell(
          onTap: () => AppLauncherUtils.makePhoneCall(customer.mobileNumber),
          child: Row(
            children: [
              Icon(
                Icons.call,
                color: Colors.white.withOpacity(0.9),
                size: 18.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                customer.mobileNumber,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 16.sp,
                ),
              ),
            ],
          ),
        ),
      ],
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

  Widget _buildRegistrationFeeCard(
    BuildContext context,
    CustomerEntity customer,
    List<SubscriptionEntity> subs,
  ) {
    final status = customer.registrationFeeStatus.toLowerCase();
    final statusColor = status == 'paid'
        ? AppColors.success
        : (status == 'partial' ? Colors.orange : Colors.red);
    final balance =
        customer.registrationFeeAmount - customer.registrationFeePaidAmount;

    return InkWell(
      onTap: balance > 0
          ? () => _showRegFeeCollectionDialog(context, customer, subs)
          : null,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  Icon(
                    Icons.assignment_ind_outlined,
                    color: Colors.white,
                    size: 20.sp,
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Registration Fee',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 13.sp,
                          ),
                        ),
                        Text(
                          '₹${customer.registrationFeePaidAmount.toStringAsFixed(0)} / ₹${customer.registrationFeeAmount.toStringAsFixed(0)}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15.sp,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (balance > 0)
                          Text(
                            'Balance: ₹${balance.toStringAsFixed(0)}',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 8.w),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(color: statusColor.withOpacity(0.5)),
              ),
              child: Text(
                status[0].toUpperCase() + status.substring(1),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRegFeeCollectionDialog(
    BuildContext pageContext,
    CustomerEntity customer,
    List<SubscriptionEntity> subs,
  ) {
    final balance =
        customer.registrationFeeAmount - customer.registrationFeePaidAmount;
    if (balance <= 0) return;

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
                'Collect Registration Fee',
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
                          'Total Fee:',
                          style: TextStyle(
                            color: AppColors.textLight,
                            fontSize: 13.sp,
                          ),
                        ),
                        Text(
                          '₹${customer.registrationFeeAmount.toStringAsFixed(0)}',
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
                          '₹${balance.toStringAsFixed(0)}',
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
                        if (amt > balance) {
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
                      final newRegPaid =
                          customer.registrationFeePaidAmount + addedAmt;

                      if (subs.isEmpty) {
                        // If no subscription, update customer only (Fallback)
                        pageContext.read<CustomerBloc>().add(
                          UpdateCustomerInfo(
                            customer: customer.copyWith(
                              registrationFeePaidAmount: newRegPaid,
                              registrationFeeStatus:
                                  newRegPaid >= customer.registrationFeeAmount
                                  ? 'paid'
                                  : 'partial',
                              registrationFeePaymentMode: selectedPaymentMode,
                            ),
                          ),
                        );
                      } else {
                        // Use latest sub to log payment
                        final sub = subs.first;
                        pageContext.read<CustomerBloc>().add(
                          UpdateSubscription(
                            subscriptionId: sub.subscriptionId,
                            endDate: sub.endDate,
                            price: sub.price,
                            registrationFeeAmount:
                                customer.registrationFeeAmount,
                            registrationFeePaid: newRegPaid,
                            paidAmount: sub.paidAmount,
                            paymentMode: selectedPaymentMode,
                            updatedById: customer.updatedById,
                            ownerId: customer.ownerId,
                            shopId: customer.shopId,
                            updatedByName: 'Staff',
                            customerName: customer.name,
                            status: sub.status,
                            customer: customer.copyWith(
                              registrationFeePaidAmount: newRegPaid,
                              registrationFeeStatus:
                                  newRegPaid >= customer.registrationFeeAmount
                                  ? 'paid'
                                  : 'partial',
                              registrationFeePaymentMode: selectedPaymentMode,
                            ),
                          ),
                        );
                      }

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
