import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:csms/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:csms/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:csms/features/auth/presentation/bloc/auth_state.dart';
import 'package:csms/features/shop/presentation/bloc/shop_context_bloc.dart';
import 'package:csms/features/customer/presentation/bloc/customer_bloc.dart';
import 'package:csms/features/customer/domain/entities/customer_entity.dart';
import 'package:csms/features/customer/presentation/pages/add_customer_page.dart';
import 'package:csms/core/utils/terminology_helper.dart';
import 'package:csms/injection_container.dart' as di;
import 'package:csms/core/theme/app_colors.dart';
import 'package:csms/core/utils/date_utils.dart';
import 'package:csms/core/utils/loading_overlay.dart';
import 'package:csms/features/settings/presentation/settings_page_web.dart';
import 'package:csms/features/notifications/presentation/pages/notifications_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:csms/features/customer/presentation/pages/customer_details_page.dart';
import 'package:csms/features/notifications/presentation/bloc/notification_bloc.dart';
import 'package:csms/core/widgets/web_sidebar.dart';

class DashboardPageWeb extends StatefulWidget {
  const DashboardPageWeb({super.key});

  @override
  State<DashboardPageWeb> createState() => _DashboardPageWebState();
}

class _DashboardPageWebState extends State<DashboardPageWeb> {
  String _selectedProductId = '';
  String _searchQuery = '';
  String? _lastLoadedShopId;
  late FocusNode _searchFocusNode;
  late TextEditingController _searchController;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _loadSelectedProduct();
    _searchFocusNode = FocusNode();
    _searchController = TextEditingController();
    _scrollController = ScrollController()..addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryLoad());
  }

  Future<void> _loadSelectedProduct() async {
    final prefs = await SharedPreferences.getInstance();
    final savedId = prefs.getString('dashboard_selected_product_id');
    if (savedId != null && mounted) {
      if (_selectedProductId.isEmpty) {
        setState(() {
          _selectedProductId = savedId;
        });
      }
    }
  }

  Future<void> _saveSelectedProduct(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('dashboard_selected_product_id', id);
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

  void _tryLoad({bool forced = false}) {
    final shopState = context.read<ShopContextBloc>().state;
    final authState = context.read<AuthBloc>().state;
    if (shopState is ShopSelected && authState is AuthAuthenticated) {
      final currentShopId = shopState.selectedShop.shopId;
      if (forced || currentShopId != _lastLoadedShopId) {
        _lastLoadedShopId = currentShopId;
        context.read<DashboardBloc>().add(
          LoadDashboardData(shopId: currentShopId, ownerId: authState.ownerId),
        );
        context.read<NotificationBloc>().add(
          StartListeningNotifications(
            authState.ownerId,
            currentShopId,
            shopState.selectedShop.category,
          ),
        );
      }
    }
  }

  String _fmt(DateTime d) => DateFormat('MMM dd, yyyy').format(d);

  @override
  Widget build(BuildContext context) {
    return BlocListener<ShopContextBloc, ShopContextState>(
      listener: (context, shopState) {
        if (shopState is ShopSelected) {
          _tryLoad();
        }
      },
      child: BlocConsumer<DashboardBloc, DashboardState>(
        listener: (context, state) {
          if (state is DashboardError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
          if (state is DashboardLoaded) {
            final activeProducts = state.products
                .where((p) => p.status == 'active')
                .toList();
            activeProducts.sort((a, b) => a.createdAt.compareTo(b.createdAt));

            if (activeProducts.isNotEmpty) {
              final isSelectedStillActive = activeProducts.any(
                (p) => p.productId == _selectedProductId,
              );
              if (_selectedProductId.isEmpty || !isSelectedStillActive) {
                setState(() {
                  _selectedProductId = activeProducts.first.productId;
                });
                _saveSelectedProduct(activeProducts.first.productId);
              }
            }
          }
        },
        builder: (context, state) {
          if (state is DashboardLoaded) {
            final term = TerminologyHelper.getTerminology(state.shop.category);
            return Scaffold(
              backgroundColor: const Color(0xFFF0F2F5),
              body: Row(
                children: [
                  const WebSidebar(selectedIndex: 0),
                  Expanded(
                    child: Stack(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildHeader(state),
                            Expanded(
                              child: SingleChildScrollView(
                                controller: _scrollController,
                                padding: const EdgeInsets.fromLTRB(
                                  40,
                                  40,
                                  40,
                                  100,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildStatsRow(state, term),
                                    const SizedBox(height: 32),
                                    _buildProductChips(state),
                                    const SizedBox(height: 16),
                                    _buildCustomerList(state, term),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        Positioned(
                          bottom: 32,
                          right: 40,
                          child: FloatingActionButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => BlocProvider(
                                    create: (_) => di.sl<CustomerBloc>(),
                                    child: AddCustomerPage(
                                      products: state.products
                                          .where((p) => p.status == 'active')
                                          .toList(),
                                      shopCategory: state.shop.category,
                                    ),
                                  ),
                                ),
                              ).then((_) => _tryLoad(forced: true));
                            },
                            backgroundColor: AppColors.primary,
                            child: const Icon(Icons.add, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        },
      ),
    );
  }

  Widget _buildHeader(DashboardLoaded state) {
    return Container(
      height: 160,
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFF1E56F0),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(40, 32, 40, 20),
            child: Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Colors.white24,
                  child: Icon(Icons.person, color: Colors.white),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Welcome back',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      Text(
                        state.shop.shopName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                BlocBuilder<NotificationBloc, NotificationState>(
                  builder: (context, notifState) {
                    int unreadCount = 0;
                    if (notifState is NotificationListening) {
                      unreadCount = notifState.unreadCount;
                    }
                    return _headerIcon(
                      Icons.notifications_outlined,
                      badge: unreadCount > 0 ? unreadCount.toString() : null,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const NotificationsPage(),
                          ),
                        );
                      },
                    );
                  },
                ),
                const SizedBox(width: 12),
                _headerIcon(
                  Icons.settings_outlined,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SettingsPageWeb(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (v) =>
                    setState(() => _searchQuery = v.toLowerCase()),
                decoration: const InputDecoration(
                  hintText: 'Search customers...',
                  prefixIcon: Icon(Icons.search, color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerIcon(IconData icon, {VoidCallback? onTap, String? badge}) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white12,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          if (badge != null)
            Positioned(
              top: -4,
              right: -4,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                child: Text(
                  badge,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(DashboardLoaded state, dynamic term) {
    return Row(
      children: [
        Expanded(
          child: _statCard('Total', state.totalCustomers.toString(), null),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: _statCard(
            'Active',
            state.activeSubscriptions.toString(),
            Colors.green,
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: _statCard(
            'Expiring',
            state.expiringSoon.length.toString(),
            Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _statCard(String label, String value, Color? color) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color ?? Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductChips(DashboardLoaded state) {
    final activeProducts = state.products
        .where((p) => p.status == 'active')
        .toList();
    activeProducts.sort((a, b) => a.createdAt.compareTo(b.createdAt));

    if (activeProducts.length <= 1) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: activeProducts.map((p) {
        final isSelected = p.productId == _selectedProductId;
        return GestureDetector(
          onTap: () {
            setState(() => _selectedProductId = p.productId);
            _saveSelectedProduct(p.productId);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF1E56F0) : Colors.white,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Text(
              p.name,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[600],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCustomerList(DashboardLoaded state, dynamic term) {
    var filtered = state.customers;

    // 1. Filter by Product
    filtered = filtered.where((c) {
      final customerSubs = [
        ...state.activeSubs.where((s) => s.customerId == c.customerId),
        ...state.expiringSoon.where((s) => s.customerId == c.customerId),
      ];
      return customerSubs.any((s) => s.productId == _selectedProductId);
    }).toList();

    // 2. Filter by Search Query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((c) {
        final matchesName = c.name.toLowerCase().contains(_searchQuery);
        final matchesPhone = c.mobileNumber.toLowerCase().contains(
          _searchQuery,
        );
        return matchesName || matchesPhone;
      }).toList();
    }

    // 3. Tiered Sorting System (Matches Mobile)
    filtered.sort((a, b) {
      int getScore(CustomerEntity c) {
        final isActiveProfile = c.status.toLowerCase().trim() == 'active';
        if (!isActiveProfile) return 1000;

        final relevantSubs = [
          ...state.activeSubs.where((s) => s.customerId == c.customerId),
          ...state.expiringSoon.where((s) => s.customerId == c.customerId),
        ].where((s) => s.productId == _selectedProductId).toList();

        if (relevantSubs.isEmpty) return 900;

        relevantSubs.sort((s1, s2) => s2.endDate.compareTo(s1.endDate));
        final sub = relevantSubs.first;
        final days = AppDateUtils.calculateDaysLeft(sub.endDate);
        final warningThreshold = state.shop.settings.expiredDaysBefore;

        if (days < 0) return 0;
        if (days <= warningThreshold) return 100;
        return 200;
      }

      final scoreA = getScore(a);
      final scoreB = getScore(b);

      if (scoreA != scoreB) return scoreA.compareTo(scoreB);

      int getDays(CustomerEntity c) {
        final subs = [
          ...state.activeSubs.where((s) => s.customerId == c.customerId),
          ...state.expiringSoon.where((s) => s.customerId == c.customerId),
        ].where((s) => s.productId == _selectedProductId).toList();
        if (subs.isEmpty) return 9999;
        subs.sort((s1, s2) => s2.endDate.compareTo(s1.endDate));
        return AppDateUtils.calculateDaysLeft(subs.first.endDate);
      }

      return getDays(a).compareTo(getDays(b));
    });

    if (filtered.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 60),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.search_off, size: 48, color: Colors.grey[300]),
              const SizedBox(height: 16),
              Text(
                'No ${term.customerLabel.toLowerCase()}s found',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filtered.length + (state.hasMore ? 1 : 0),
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        if (index >= filtered.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: LoadingOverlay(size: 24),
            ),
          );
        }
        final c = filtered[index];

        final allSubs = [
          ...state.activeSubs.where((s) => s.customerId == c.customerId),
          ...state.expiringSoon.where((s) => s.customerId == c.customerId),
        ];

        final Map<String, dynamic> latestSubsPerProduct = {};
        for (var sub in allSubs) {
          final current = latestSubsPerProduct[sub.productId];
          if (current == null || sub.endDate.isAfter(current.endDate)) {
            latestSubsPerProduct[sub.productId] = sub;
          }
        }
        final uniqueSubs = latestSubsPerProduct.values.toList();
        uniqueSubs.sort((a, b) => a.endDate.compareTo(b.endDate));

        final sub =
            uniqueSubs
                .where((s) => s.productId == _selectedProductId)
                .firstOrNull ??
            uniqueSubs.firstOrNull;

        final daysLeft = sub != null
            ? AppDateUtils.calculateDaysLeft(sub.endDate)
            : null;
        final isExpired = daysLeft != null && daysLeft < 0;
        final isWarn =
            daysLeft != null &&
            !isExpired &&
            daysLeft <= state.shop.settings.expiredDaysBefore;

        final productNames = uniqueSubs
            .map((s) {
              final p = state.products
                  .where((prod) => prod.productId == s.productId)
                  .firstOrNull;
              return p?.name ?? s.productId;
            })
            .join(', ');

        return InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CustomerDetailsPage(customerId: c.customerId),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                      child: Text(
                        c.name[0].toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                c.name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (c.status.toLowerCase().trim() ==
                                  'inactive') ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'INACTIVE',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            c.mobileNumber,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (sub != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isExpired
                              ? Colors.red.withOpacity(0.1)
                              : (isWarn
                                    ? Colors.orange.withOpacity(0.1)
                                    : Colors.green.withOpacity(0.1)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isExpired ? 'Expired' : '$daysLeft days left',
                          style: TextStyle(
                            color: isExpired
                                ? Colors.red
                                : (isWarn ? Colors.orange : Colors.green),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Divider(height: 1),
                ),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Plans',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            productNames.isEmpty
                                ? 'No active plan'
                                : productNames,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Expiry Date',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            sub != null ? _fmt(sub.endDate) : '—',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Amount Paid',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          sub != null
                              ? '₹${sub.paidAmount.toStringAsFixed(0)}'
                              : '₹0',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        if (sub != null && sub.balanceAmount > 0)
                          Text(
                            'Bal: ₹${sub.balanceAmount.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
