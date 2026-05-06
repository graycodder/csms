import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:csms/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:csms/features/customer/domain/entities/customer_entity.dart';
import 'package:csms/core/utils/terminology_helper.dart';
import 'package:csms/core/theme/app_colors.dart';
import 'package:csms/core/utils/date_utils.dart';
import 'package:csms/features/customer/presentation/pages/customer_details_page.dart';
import 'package:csms/core/widgets/web_sidebar.dart';

class CustomerListPageWeb extends StatefulWidget {
  final BusinessTerminology term;
  final VoidCallback onReturn;
  final DashboardLoaded state;

  const CustomerListPageWeb({
    super.key,
    required this.term,
    required this.onReturn,
    required this.state,
  });

  @override
  State<CustomerListPageWeb> createState() => _CustomerListPageWebState();
}

class _CustomerListPageWebState extends State<CustomerListPageWeb> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _fmt(DateTime date) => DateFormat('MMM dd, yyyy').format(date);

  @override
  Widget build(BuildContext context) {
    List<CustomerEntity> filteredCustomers = List.from(widget.state.customers);
    if (_searchQuery.isNotEmpty) {
      filteredCustomers = filteredCustomers.where((c) {
        final matchesName = c.name.toLowerCase().contains(_searchQuery);
        final matchesPhone = c.mobileNumber.toLowerCase().contains(
          _searchQuery,
        );
        return matchesName || matchesPhone;
      }).toList();
    }

    filteredCustomers.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      body: Row(
        children: [
          const WebSidebar(selectedIndex: 2),
          Expanded(
            child: Column(
              children: [
                _buildHeader(filteredCustomers.length),
                Expanded(
                  child: Container(
                    color: const Color(0xFFF0F2F5),
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(40),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: 800.w),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [_buildCustomerList(filteredCustomers)],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(int count) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFF1E56F0),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(32, 48, 32, 15),
        child: Row(
          children: [
            // GestureDetector(
            //   onTap: () => Navigator.pop(context),
            //   child: Container(
            //     padding: const EdgeInsets.all(8),
            //     decoration: const BoxDecoration(
            //       color: Colors.white12,
            //       shape: BoxShape.circle,
            //     ),
            //     child: const Icon(
            //       Icons.arrow_back,
            //       color: Colors.white,
            //       size: 20,
            //     ),
            //   ),
            // ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${widget.term.customerLabel} Directory',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Managing $count total ${widget.term.customerLabel.toLowerCase()} records',
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                  const SizedBox(height: 14),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 0),
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerList(List<CustomerEntity> customers) {
    if (customers.isEmpty) {
      return Center(
        child: Column(
          children: [
            Icon(
              Icons.person_search_outlined,
              size: 64,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              'No ${widget.term.customerLabel.toLowerCase()}s match your search',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: customers.length,
      separatorBuilder: (_, __) => SizedBox(height: 16),
      itemBuilder: (context, index) {
        final c = customers[index];

        final allSubs = [
          ...widget.state.activeSubs.where((s) => s.customerId == c.customerId),
          ...widget.state.expiringSoon.where(
            (s) => s.customerId == c.customerId,
          ),
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

        final sub = uniqueSubs.firstOrNull;
        final daysLeft = sub != null
            ? AppDateUtils.calculateDaysLeft(sub.endDate)
            : null;
        final isExpired = daysLeft != null && daysLeft < 0;
        final isWarn =
            daysLeft != null &&
            !isExpired &&
            daysLeft <= widget.state.shop.settings.expiredDaysBefore;

        final productNames = uniqueSubs
            .map((s) {
              final p = widget.state.products
                  .where((prod) => prod.productId == s.productId)
                  .firstOrNull;
              return p?.name ?? s.productId;
            })
            .join(', ');

        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 800.w),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        CustomerDetailsPage(customerId: c.customerId),
                  ),
                );
              },
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
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
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
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
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
            ),
          ),
        );
      },
    );
  }
}
