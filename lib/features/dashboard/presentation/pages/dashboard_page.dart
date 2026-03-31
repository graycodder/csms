import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:csms/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:csms/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:csms/features/auth/presentation/bloc/auth_state.dart';
import 'package:csms/features/shop/presentation/bloc/shop_context_bloc.dart';
import 'package:csms/features/settings/presentation/settings_page.dart';
import 'package:csms/features/customer/presentation/bloc/customer_bloc.dart';
import 'package:csms/features/customer/domain/entities/customer_entity.dart';
import 'package:csms/features/customer/presentation/pages/add_customer_page.dart';
import 'package:csms/features/customer/presentation/pages/customer_details_page.dart';
import 'package:csms/features/notifications/presentation/pages/notifications_page.dart';
import 'package:csms/features/notifications/presentation/bloc/notification_bloc.dart';
import 'package:csms/features/subscription/domain/entities/subscription_entity.dart';
import 'package:csms/core/utils/terminology_helper.dart';
import 'package:csms/features/dashboard/presentation/widgets/whatsapp_reminder_banner.dart';
import 'package:csms/injection_container.dart' as di;
import 'package:lottie/lottie.dart';
import 'package:csms/core/theme/app_colors.dart';
import 'package:csms/features/shop/domain/entities/shop_entity.dart';
import 'package:csms/core/utils/date_utils.dart';
import 'package:csms/core/utils/launcher_utils.dart';
import 'package:csms/features/shop_subscription/presentation/bloc/shop_subscription_bloc.dart';
import 'package:csms/features/shop_subscription/domain/entities/shop_subscription_entity.dart';

import 'package:csms/core/utils/loading_overlay.dart';
import 'package:csms/features/dashboard/presentation/widgets/customer_card.dart';
import 'package:csms/features/customer/presentation/pages/customer_list_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  String _selectedProductId = '';
  String _searchQuery = '';
  late FocusNode _searchFocusNode;
  late TextEditingController _searchController;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _searchFocusNode = FocusNode();
    _searchController = TextEditingController();
    _scrollController = ScrollController()..addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryLoad());
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final state = context.read<DashboardBloc>().state;
      if (state is DashboardLoaded && state.hasMore) {
        final shopState = context.read<ShopContextBloc>().state;
        final authState = context.read<AuthBloc>().state;
        if (shopState is ShopSelected && authState is AuthAuthenticated) {
          context.read<DashboardBloc>().add(
                LoadMoreCustomers(
                  shopId: shopState.selectedShop.shopId,
                  ownerId: authState.ownerId,
                ),
              );
        }
      }
    }
  }

  @override
  void dispose() {
    _searchFocusNode.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _tryLoad() {
    final shopState = context.read<ShopContextBloc>().state;
    final authState = context.read<AuthBloc>().state;
    if (shopState is ShopSelected && authState is AuthAuthenticated) {
      print('DEBUG: DashboardPage _tryLoad - Triggering LoadDashboardData for shopId: ${shopState.selectedShop.shopId}');
      context.read<DashboardBloc>().add(
        LoadDashboardData(shopId: shopState.selectedShop.shopId, ownerId: authState.ownerId),
      );
      context.read<NotificationBloc>().add(
        StartListeningNotifications(authState.ownerId, shopState.selectedShop.shopId, shopState.selectedShop.category),
      );
      context.read<ShopSubscriptionBloc>().add(
        ListenToShopSubscriptionStatus(shopState.selectedShop.shopId),
      );
    } else if (authState is AuthAuthenticated && shopState is! ShopSelected) {
       context.read<ShopContextBloc>().add(
             LoadShops(
               ownerId: authState.ownerId,
               shopId: authState.shopId,
               role: authState.role,
             ),
           );
    }
  }


  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<ShopContextBloc, ShopContextState>(
          listener: (context, shopState) {
            if (shopState is ShopSelected) {
              final authState = context.read<AuthBloc>().state;
              if (authState is AuthAuthenticated) {
                context.read<DashboardBloc>().add(
                  LoadDashboardData(shopId: shopState.selectedShop.shopId, ownerId: authState.ownerId),
                );
                context.read<NotificationBloc>().add(
                  StartListeningNotifications(authState.ownerId, shopState.selectedShop.shopId, shopState.selectedShop.category),
                );
                context.read<ShopSubscriptionBloc>().add(
                  ListenToShopSubscriptionStatus(shopState.selectedShop.shopId),
                );
              }
            }
          },
        ),
        BlocListener<CustomerBloc, CustomerState>(
          listener: (context, state) {
            if (state is CustomerError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message, style: TextStyle(fontSize: 14.sp)), backgroundColor: Colors.red),
              );
            }
          },
        ),
        BlocListener<DashboardBloc, DashboardState>(
          listener: (context, state) {
            if (state is DashboardLoaded) {
              final activeProducts = state.products.where((p) => p.status == 'active').toList();
              if (activeProducts.isNotEmpty) {
                final isSelectedStillActive = activeProducts.any((p) => p.productId == _selectedProductId);
                if (_selectedProductId.isEmpty || !isSelectedStillActive) {
                  setState(() {
                    _selectedProductId = activeProducts.first.productId;
                  });
                }
              }
            }
          },
        ),
      ],
      child: BlocBuilder<DashboardBloc, DashboardState>(
        builder: (context, state) {
          if (state is DashboardLoaded) {
            final term = TerminologyHelper.getTerminology(state.shop.category);
            return Scaffold(
              backgroundColor: const Color(0xFFF0F2F5),
              body: Stack(
                children: [
                  Container(
                    height: 210.h,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E56F0),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(36.r),
                        bottomRight: Radius.circular(36.r),
                      ),
                    ),
                  ),
                  SafeArea(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _topBar(state),
                        SizedBox(height: 15.h),
                        _searchBar(term),
                        SizedBox(height: 15.h),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.w),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _statsRow(state, term),
                              state.products.where((p) => p.status == 'active').length <= 1
                                  ? SizedBox(height: 5.h)
                                  : SizedBox(height: 18.h),
                              _productChips(state),
                              SizedBox(height: 5.h),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16.w),
                            child: _customerList(state, term),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              floatingActionButton: FloatingActionButton(
                heroTag: null,
                onPressed: () {
                  FocusScope.of(context).unfocus();
                  _searchFocusNode.unfocus();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BlocProvider(
                        create: (_) => di.sl<CustomerBloc>(),
                        child: AddCustomerPage(
                          products: state.products.where((p) => p.status == 'active').toList(),
                          shopCategory: state.shop.category,
                        ),
                      ),
                    ),
                  ).then((_) {
                    _tryLoad();
                  });
                },
                backgroundColor: const Color(0xFF1E56F0),
                elevation: 6,
                shape: const CircleBorder(),
                child: Icon(Icons.add, color: Colors.white, size: 32.sp),
              ),
            );
          } else if (state is DashboardError) {
            return Scaffold(body: _errorBox(state.message));
          }
          return const Scaffold(
            body: LoadingOverlay(),
          );
        },
      ),
    );
  }

  Widget _topBar(DashboardState state) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Row(
        children: [
          BlocBuilder<ShopContextBloc, ShopContextState>(
            builder: (context, shopState) {
              return InkWell(
                onTap: () {
                  if (shopState is ShopSelected && shopState.shops.length > 1) {
                    _showShopSwitcher(context, shopState);
                  }
                },
                borderRadius: BorderRadius.circular(22.r),
                child: Container(
                  width: 40.w,
                  height: 40.w,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.person, color: AppColors.primary, size: 28.sp),
                ),
              );
            },
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Welcome back',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12.sp,
                  ),
                ),
                BlocBuilder<ShopContextBloc, ShopContextState>(
                  builder: (_, s) {
                    final name = s is ShopSelected ? s.selectedShop.shopName : 'My Business';
                    return Text(
                      name,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                        height: 1.1,
                      ),
                      overflow: TextOverflow.ellipsis,
                    );
                  },
                ),
              ],
            ),
          ),
          BlocBuilder<NotificationBloc, NotificationState>(
            builder: (context, notifState) {
              int unreadCount = 0;
              if (notifState is NotificationListening) {
                unreadCount = notifState.unreadCount;
              }
              return _headerBtn(
                Icons.notifications_none_outlined,
                badge: unreadCount > 0 ? unreadCount.toString() : null,
                onTap: () {
                  FocusScope.of(context).unfocus();
                  _searchFocusNode.unfocus();
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const NotificationsPage()),
                  ).then((_) => _tryLoad());
                },
              );
            },
          ),
          SizedBox(width: 8.w),
          _headerBtn(
            Icons.settings_outlined,
            onTap: () {
              FocusScope.of(context).unfocus();
              _searchFocusNode.unfocus();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsPage()),
              ).then((_) => _tryLoad());
            },
          ),
        ],
      ),
    );
  }

  void _showShopSwitcher(BuildContext context, ShopSelected state) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.all(24.r),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Switch Business',
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                SizedBox(height: 20.h),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: state.shops.length,
                    separatorBuilder: (_, __) => SizedBox(height: 12.h),
                    itemBuilder: (context, index) {
                      final shop = state.shops[index];
                      final isSelected = shop.shopId == state.selectedShop.shopId;
                      
                      return ListTile(
                        onTap: () {
                          Navigator.pop(context);
                          context.read<ShopContextBloc>().add(
                            SelectShop(shop, state.shops),
                          );
                        },
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 4.h,
                        ),
                        tileColor: isSelected 
                            ? AppColors.primary.withOpacity(0.1) 
                            : Colors.grey[50]!.withOpacity(0.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.r),
                          side: BorderSide(
                            color: isSelected 
                                ? AppColors.primary.withOpacity(0.2) 
                                : Colors.transparent,
                          ),
                        ),
                        leading: CircleAvatar(
                          backgroundColor: isSelected ? AppColors.primary : Colors.grey[300],
                          child: Icon(Icons.store, color: Colors.white, size: 20.sp),
                        ),
                        title: Text(
                          shop.shopName,
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected ? AppColors.primary : AppColors.textDark,
                            fontSize: 14.sp,
                          ),
                        ),
                        trailing: isSelected 
                            ? Icon(Icons.check_circle, color: AppColors.primary, size: 20.sp) 
                            : null,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _headerBtn(IconData icon, {String? badge, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40.w, height: 40.w,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
        child: Stack(alignment: Alignment.center, children: [
          Icon(icon, color: Colors.white, size: 24.sp),
          if (badge != null)
            Positioned(
              top: 7.h, right: 7.w,
              child: Container(
                width: 16.r, height: 16.r,
                decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                child: Center(
                  child: Text(badge, style: TextStyle(color: Colors.white, fontSize: 9.sp, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
        ]),
      ),
    );
  }

  Widget _searchBar(BusinessTerminology term) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Container(
        height: 45.h,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10.r,
              offset: Offset(0, 4.h),
            )
          ],
        ),
        child: TextField(
          controller: _searchController,
          focusNode: _searchFocusNode,
          onChanged: (value) {
            setState(() {
              _searchQuery = value.toLowerCase().trim();
            });
          },
          decoration: InputDecoration(
            hintText: 'Search ${term.customerLabel.toLowerCase()}s by name or number...',
            hintStyle: TextStyle(
              color: Colors.grey[400],
              fontSize: 14.sp,
            ),
            prefixIcon: Icon(Icons.search, color: Colors.grey[400], size: 22.sp),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.close, color: Colors.grey[400], size: 20.sp),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _searchQuery = '';
                      });
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: 14.h),
          ),
        ),
      ),
    );
  }

  Widget _statsRow(DashboardLoaded state, BusinessTerminology term) {
    return Row(children: [
      Expanded(
        child: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CustomerListPage(
                  state: state,
                  term: term,
                  onReturn: _tryLoad,
                ),
              ),
            );
          },
          child: _statCard('Total', term.customerLabel, state.totalCustomers.toString(), Colors.black),
        ),
      ),
      SizedBox(width: 10.w),
      Expanded(child: _statCard('Active', term.subscriptionLabel, state.activeSubscriptions.toString(), const Color(0xFF27AE60))),
      SizedBox(width: 10.w),
      Expanded(child: _statCard('Expiring', term.subscriptionLabel, state.expiringSoon.length.toString(), const Color(0xFFE67E22))),
    ]);
  }

  Widget _statCard(String label,String subLabel, String value, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10.r,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
           Text(
            subLabel,
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 8.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            value,
            maxLines:1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _productChips(DashboardLoaded state) {
    final activeProducts = state.products.where((p) => p.status == 'active').toList();
    if (activeProducts.length <= 1) {
      return const SizedBox.shrink();
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ...activeProducts.map((product) {
            return Padding(
              padding: EdgeInsets.only(right: 12.w),
              child: _chip(product.name, _selectedProductId == product.productId, onTap: () {
                setState(() => _selectedProductId = product.productId);
              }),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _chip(String label, bool selected, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF1E56F0) : Colors.white,
          borderRadius: BorderRadius.circular(22.r),
        ),
        child: Text(label,
            style: TextStyle(
              color: selected ? Colors.white : Colors.grey[600],
              fontWeight: selected ? FontWeight.bold : FontWeight.w500,
              fontSize: 13.sp,
            )),
      ),
    );
  }

  Widget _customerList(DashboardLoaded state, BusinessTerminology term) {
    var filteredCustomers = state.customers;
    
    filteredCustomers = filteredCustomers.where((c) {
      final customerSubs = [
        ...state.activeSubs.where((s) => s.customerId == c.customerId),
        ...state.expiringSoon.where((s) => s.customerId == c.customerId),
      ];
      return customerSubs.any((s) => s.productId == _selectedProductId);
    }).toList();

    if (_searchQuery.isNotEmpty) {
      filteredCustomers = filteredCustomers.where((c) {
        final matchesName = c.name.toLowerCase().contains(_searchQuery);
        final matchesPhone = c.mobileNumber.toLowerCase().contains(_searchQuery);
        return matchesName || matchesPhone;
      }).toList();
    }

    filteredCustomers.sort((a, b) {
      // 1. Calculate a numeric score for each customer's urgency
      int getScore(CustomerEntity c) {
        final isActiveProfile = c.status.toLowerCase().trim() == 'active';
        if (!isActiveProfile) return 1000; // Final Group: Inactive profile

        final relevantSubs = [
          ...state.activeSubs.where((s) => s.customerId == c.customerId),
          ...state.expiringSoon.where((s) => s.customerId == c.customerId),
        ].where((s) => s.productId == _selectedProductId).toList();

        if (relevantSubs.isEmpty) return 900; // Penultimate Group: Active profile but no sub

        // Select the LATEST expiration date for this product (handles renewals correctly)
        relevantSubs.sort((s1, s2) => s2.endDate.compareTo(s1.endDate));
        final sub = relevantSubs.first;
        final days = AppDateUtils.calculateDaysLeft(sub.endDate);
        final warningThreshold = state.shop.settings.expiredDaysBefore;

        if (days < 0) return 0;       // Top Group: Already Expired
        if (days <= warningThreshold) return 100;  // Middle Group: Soon (0-X days)
        return 200;                  // Bottom Group: Safe (>X days)
      }

      final scoreA = getScore(a);
      final scoreB = getScore(b);

      if (scoreA != scoreB) return scoreA.compareTo(scoreB);

      // 2. Tertiary sort: Exact days left within the same score group
      int getDays(CustomerEntity c) {
        final subs = [
          ...state.activeSubs.where((s) => s.customerId == c.customerId),
          ...state.expiringSoon.where((s) => s.customerId == c.customerId),
        ].where((s) => s.productId == _selectedProductId).toList();
        if (subs.isEmpty) return 9999;
        // Again, pick the latest sub for this product to match display
        subs.sort((s1, s2) => s2.endDate.compareTo(s1.endDate));
        return AppDateUtils.calculateDaysLeft(subs.first.endDate);
      }

      return getDays(a).compareTo(getDays(b));
    });

    if (filteredCustomers.isEmpty) {
      return Center(
        child: Text(
          'No ${term.customerLabel.toLowerCase()}s found',
          style: TextStyle(
            color: Colors.grey[500],
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }
    
    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.only(bottom: 100.h, top: 12.h),
      physics: const BouncingScrollPhysics(),
      itemCount: filteredCustomers.length + (state.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= filteredCustomers.length) {
          return Padding(
            padding: EdgeInsets.symmetric(vertical: 24.h),
            child: const Center(
              child: LoadingOverlay(size: 24),
            ),
          );
        }
        return CustomerCard(
          customer: filteredCustomers[index],
          state: state,
          term: term,
          selectedProductId: _selectedProductId,
          formatDate: _fmt,
          onReturn: _tryLoad,
        );
      },
    );
  }

  Widget _errorBox(String msg) => Center(
        child: Padding(
          padding: EdgeInsets.all(24.r),
          child: Column(children: [
            Icon(Icons.cloud_off_outlined, size: 48.sp, color: Colors.grey),
            SizedBox(height: 12.h),
            Text(msg, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 14.sp)),
            SizedBox(height: 12.h),
            TextButton.icon(
              onPressed: _tryLoad, 
              icon: const Icon(Icons.refresh), 
              label: Text('Retry', style: TextStyle(fontSize: 14.sp)),
            ),
          ]),
        ),
      );

  String _fmt(DateTime d) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[d.month - 1]} ${d.day.toString().padLeft(2, '0')}, ${d.year}';
  }
}
