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

class CustomerDetailsPageWeb extends StatelessWidget {
  final String customerId;

  const CustomerDetailsPageWeb({super.key, required this.customerId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          _buildSidebar(context),
          Expanded(
            child: BlocListener<CustomerBloc, CustomerState>(
              listener: (context, state) {
                if (state is CustomerSuccess) {
                  final shopState = context.read<ShopContextBloc>().state;
                  final authState = context.read<AuthBloc>().state;
                  if (shopState is ShopSelected &&
                      authState is AuthAuthenticated) {
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
                      ...state.activeSubs.where(
                        (s) => s.customerId == customerId,
                      ),
                      ...state.expiringSoon.where(
                        (s) => s.customerId == customerId,
                      ),
                    ];

                    final Map<String, SubscriptionEntity> latestSubsPerProduct =
                        {};
                    for (var sub in customerSubs) {
                      final current = latestSubsPerProduct[sub.productId];
                      if (current == null ||
                          sub.endDate.isAfter(current.endDate)) {
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
                        body: Center(
                          child: Text("${term.customerLabel} not found."),
                        ),
                      );
                    }

                    return Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: 800.w),
                        child: Stack(
                          children: [
                            Container(
                              height:
                                  state.shop.settings.registrationFeeEnabled &&
                                      customer.notes.isEmpty
                                  ? 325
                                  : state
                                            .shop
                                            .settings
                                            .registrationFeeEnabled &&
                                        customer.notes.isNotEmpty
                                  ? 420
                                  : customer.notes.isNotEmpty
                                  ? 370
                                  : 280,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.only(
                                  bottomLeft: Radius.circular(30),
                                  bottomRight: Radius.circular(30),
                                ),
                              ),
                            ),
                            SafeArea(
                              child: Column(
                                children: [
                                  _buildAppBar(
                                    context,
                                    customer,
                                    state.products,
                                    state,
                                  ),
                                  Expanded(
                                    child: ListView(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 20,
                                      ),
                                      children: [
                                        _buildHeaderInfo(customer),
                                        if (state
                                            .shop
                                            .settings
                                            .registrationFeeEnabled) ...[
                                          SizedBox(height: 8),
                                          _buildRegistrationFeeCard(
                                            context,
                                            customer,
                                            uniqueSubs,
                                          ),
                                          SizedBox(height: 13),
                                        ],
                                        if (!state
                                                .shop
                                                .settings
                                                .registrationFeeEnabled &&
                                            customer.notes.isEmpty) ...[
                                          SizedBox(height: 35),
                                        ],
                                        if (customer.notes.isNotEmpty) ...[
                                          SizedBox(height: 8),
                                          _buildNotesCard(customer),
                                          SizedBox(height: 25),
                                        ],
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'Active ${term.planLabel}s',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                            BlocBuilder<AuthBloc, AuthState>(
                                              builder: (context, authState) {
                                                final existingProductIds =
                                                    uniqueSubs
                                                        .map((s) => s.productId)
                                                        .toList();
                                                final availableProducts = state
                                                    .products
                                                    .where((p) {
                                                      return p.status ==
                                                              'active' &&
                                                          !existingProductIds
                                                              .contains(
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
                                                            .read<
                                                              CustomerBloc
                                                            >(),
                                                        child: AddSubscriptionPage(
                                                          customerId: customer
                                                              .customerId,
                                                          customerName:
                                                              customer.name,
                                                          shopId:
                                                              customer.shopId,
                                                          ownerId:
                                                              customer.ownerId,
                                                          updatedById:
                                                              authState
                                                                  is AuthAuthenticated
                                                              ? authState.userId
                                                              : '',
                                                          updatedByName:
                                                              authState
                                                                      is AuthAuthenticated &&
                                                                  authState
                                                                      .name
                                                                      .isNotEmpty
                                                              ? authState.name
                                                              : 'Admin',
                                                          products:
                                                              state.products,
                                                          shopCategory: state
                                                              .shop
                                                              .category,
                                                          existingProductIds:
                                                              existingProductIds,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  icon: Icon(
                                                    Icons.add,
                                                    color: Colors.white,
                                                    size: 18,
                                                  ),
                                                  label: Text(
                                                    'Add New ${term.planLabel}',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                  style: TextButton.styleFrom(
                                                    backgroundColor: Colors
                                                        .white
                                                        .withOpacity(0.2),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12,
                                                          ),
                                                    ),
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                          horizontal: 12,
                                                          vertical: 8,
                                                        ),
                                                  ),
                                                );
                                              },
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 5),
                                        if (uniqueSubs.isEmpty)
                                          Column(
                                            children: [
                                              SizedBox(height: 5),
                                              Center(
                                                child: Text(
                                                  'No active ${term.planLabel.toLowerCase()}s found',
                                                  style: TextStyle(
                                                    color: Colors.white70,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ),
                                              SizedBox(height: 5),
                                            ],
                                          )
                                        else
                                          ...uniqueSubs.map((sub) {
                                            final prod = state.products
                                                .where(
                                                  (p) =>
                                                      p.productId ==
                                                      sub.productId,
                                                )
                                                .firstOrNull;
                                            return Padding(
                                              padding: EdgeInsets.only(
                                                bottom: 16,
                                              ),
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
                                        SizedBox(height: 100),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  return const LoadingOverlay();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(BuildContext context) {
    return Container(
      width: 250,
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BlocBuilder<ShopContextBloc, ShopContextState>(
            builder: (context, state) {
              final shopName = state is ShopSelected
                  ? state.selectedShop.shopName
                  : 'Shop Details';
              return Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      shopName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Executive Portal',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          _sidebarItem(
            context,
            Icons.home_outlined,
            'Dashboard',
            onTap: () => Navigator.popUntil(context, (r) => r.isFirst),
          ),
          _sidebarItem(
            context,
            Icons.people_outline,
            'Customers',
            isSelected: true,
            onTap: () => Navigator.pop(context),
          ),
          // const Spacer(),
          // const Divider(height: 1),
          // Padding(
          //   padding: const EdgeInsets.all(24.0),
          //   child: Column(
          //     crossAxisAlignment: CrossAxisAlignment.start,
          //     children: [
          //       Text(
          //         'Current Shop',
          //         style: TextStyle(fontSize: 10, color: Colors.grey),
          //       ),
          //       SizedBox(height: 4),
          //       Text(
          //         shopName,
          //         style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          //       ),
          //     ],
          //   ),
          // ),
        ],
      ),
    );
  }

  Widget _sidebarItem(
    BuildContext context,
    IconData icon,
    String title, {
    bool isSelected = false,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF1F5FE) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFF1E56F0) : Colors.grey,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? const Color(0xFF1E56F0) : Colors.grey[700],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ],
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
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
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
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                        if (sub.paymentStatus != 'paid') ...[
                          SizedBox(width: 8),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: sub.paymentStatus == 'unpaid'
                                  ? Colors.red.shade100
                                  : Colors.orange.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              sub.paymentStatus.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
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
                    SizedBox(height: 4),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isExpired ? Colors.red[50] : Colors.green[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isExpired ? 'Expired' : 'Active',
                        style: TextStyle(
                          color: isExpired ? Colors.red : Colors.green,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 12),
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
                          size: 20,
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
                          size: 24,
                        ),
                        tooltip: 'Renew Plan',
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
          Divider(height: 32, color: const Color(0xFFF0F0F0)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Expiry Date',
                    style: TextStyle(color: AppColors.textLight, fontSize: 13),
                  ),
                  SizedBox(height: 4),
                  Text(
                    _fmt(sub.endDate),
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: sub.balanceAmount > 0
                    ? () => _showBalanceCollectionDialog(context, sub, customer)
                    : null,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        sub.balanceAmount > 0 ? 'Paid Amount' : 'Price',
                        style: TextStyle(
                          color: sub.balanceAmount > 0
                              ? AppColors.primary
                              : AppColors.textLight,
                          fontSize: 13,
                          fontWeight: sub.balanceAmount > 0
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      SizedBox(height: 4),
                      if (sub.balanceAmount > 0)
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: '₹${sub.paidAmount.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                  fontSize: 15,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                              TextSpan(
                                text: ' / ₹${sub.price.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textLight,
                                  fontSize: 12,
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
                            fontSize: 15,
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
                    style: TextStyle(color: AppColors.textLight, fontSize: 13),
                  ),
                  SizedBox(height: 4),
                  Text(
                    isExpired ? '0 days' : '$daysLeft days',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: isExpired ? Colors.red : AppColors.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (sub.notes != null && sub.notes!.isNotEmpty) ...[
            Divider(height: 24, color: const Color(0xFFF0F0F0)),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.note_alt_outlined,
                  color: AppColors.textLight,
                  size: 14,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    sub.notes!,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textDark.withOpacity(0.8),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ],
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
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
                  fontSize: 18,
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
              SizedBox(width: 8),
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
                        registrationFeeEnabled:
                            state.shop.settings.registrationFeeEnabled,
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
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 24),
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
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        //  SizedBox(height: 8),
        InkWell(
          onTap: () => AppLauncherUtils.makePhoneCall(customer.mobileNumber),
          child: Row(
            children: [
              Icon(Icons.call, color: Colors.white.withOpacity(0.9), size: 18),
              SizedBox(width: 8),
              Text(
                customer.mobileNumber,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 16,
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
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(
                'Collect Balance',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
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
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          '₹${sub.price.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Pending Balance:',
                          style: TextStyle(
                            color: AppColors.textLight,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          '₹${sub.balanceAmount.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Received Amount *',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    SizedBox(height: 4),
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
                          horizontal: 12,
                          vertical: 8,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
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
                    SizedBox(height: 16),
                    Text(
                      'Payment Mode *',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    SizedBox(height: 4),
                    DropdownButtonFormField<String>(
                      value: selectedPaymentMode,
                      decoration: InputDecoration(
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      items: ['Cash', 'UPI', 'Card', 'Bank Transfer'].map((m) {
                        return DropdownMenuItem(
                          value: m,
                          child: Text(m, style: TextStyle(fontSize: 14)),
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

                      final shopState = pageContext
                          .read<ShopContextBloc>()
                          .state;
                      final authState = pageContext.read<AuthBloc>().state;
                      final updatedByName =
                          authState is AuthAuthenticated &&
                              authState.name.isNotEmpty
                          ? authState.name
                          : 'Admin';
                      final updatedById = authState is AuthAuthenticated
                          ? authState.userId
                          : sub.updatedById;
                      final shopCategory = shopState is ShopSelected
                          ? shopState.selectedShop.category
                          : 'Other';

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
                          shopCategory: shopCategory,
                          status: sub.status,
                        ),
                      );

                      Navigator.pop(dialogContext);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
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
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
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
                    size: 20,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Registration Fee',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          '₹${customer.registrationFeePaidAmount.toStringAsFixed(0)} / ₹${customer.registrationFeeAmount.toStringAsFixed(0)}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (balance > 0)
                          Text(
                            'Balance: ₹${balance.toStringAsFixed(0)}',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 12,
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
            SizedBox(width: 8),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: statusColor.withOpacity(0.5)),
              ),
              child: Text(
                status[0].toUpperCase() + status.substring(1),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
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
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(
                'Collect Registration Fee',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
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
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          '₹${customer.registrationFeeAmount.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Pending Balance:',
                          style: TextStyle(
                            color: AppColors.textLight,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          '₹${balance.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Received Amount *',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    SizedBox(height: 4),
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
                          horizontal: 12,
                          vertical: 8,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
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
                    SizedBox(height: 16),
                    Text(
                      'Payment Mode *',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    SizedBox(height: 4),
                    DropdownButtonFormField<String>(
                      value: selectedPaymentMode,
                      decoration: InputDecoration(
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      items: ['Cash', 'UPI', 'Card', 'Bank Transfer'].map((m) {
                        return DropdownMenuItem(
                          value: m,
                          child: Text(m, style: TextStyle(fontSize: 14)),
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

                      final shopState = pageContext
                          .read<ShopContextBloc>()
                          .state;
                      final authState = pageContext.read<AuthBloc>().state;
                      final updatedByName =
                          authState is AuthAuthenticated &&
                              authState.name.isNotEmpty
                          ? authState.name
                          : 'Admin';
                      final shopCategory = shopState is ShopSelected
                          ? shopState.selectedShop.category
                          : 'Other';

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
                            updatedByName: updatedByName,
                            updatedById: authState is AuthAuthenticated
                                ? authState.userId
                                : customer.updatedById,
                            ownerId: customer.ownerId,
                            shopId: customer.shopId,
                            customerName: customer.name,
                            shopCategory: shopCategory,
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
                            updatedByName: updatedByName,
                            customerName: customer.name,
                            shopCategory: shopCategory,
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
                      borderRadius: BorderRadius.circular(8),
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

  Widget _buildNotesCard(CustomerEntity customer) {
    return Container(
      padding: EdgeInsets.only(top: 10, left: 16, right: 16, bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.note_alt_outlined, color: AppColors.primary, size: 16),
              SizedBox(width: 8),
              Text(
                'Customer Notes',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          SizedBox(height: 5),
          Text(
            customer.notes,
            overflow: TextOverflow.ellipsis,
            maxLines: 3,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textDark.withOpacity(0.8),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
