import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:csms/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:csms/features/customer/domain/entities/customer_entity.dart';
import 'package:csms/core/utils/terminology_helper.dart';
import 'package:csms/core/theme/app_colors.dart';
import 'package:csms/features/dashboard/presentation/widgets/customer_card.dart';

class CustomerListPage extends StatefulWidget {
  final DashboardLoaded state;
  final BusinessTerminology term;
  final VoidCallback onReturn;

  const CustomerListPage({
    super.key,
    required this.state,
    required this.term,
    required this.onReturn,
  });

  @override
  State<CustomerListPage> createState() => _CustomerListPageState();
}

class _CustomerListPageState extends State<CustomerListPage> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    List<CustomerEntity> filteredCustomers = List.from(widget.state.customers);

    if (_searchQuery.isNotEmpty) {
      filteredCustomers = filteredCustomers.where((c) {
        final matchesName = c.name.toLowerCase().contains(_searchQuery);
        final matchesPhone = c.mobileNumber.toLowerCase().contains(_searchQuery);
        return matchesName || matchesPhone;
      }).toList();
    }

    // Sort: Inactive (no subs) customers at the bottom, then by name
    filteredCustomers.sort((a, b) {
      final aHasSubs = _hasAnySubscription(a);
      final bHasSubs = _hasAnySubscription(b);
      
      if (aHasSubs != bHasSubs) {
        return aHasSubs ? -1 : 1;
      }
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: Text(
          'All ${widget.term.customerLabel}s',
          style: TextStyle(color: Colors.white, fontSize: 18.sp, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          _buildSearchBox(),
          Expanded(
            child: filteredCustomers.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: EdgeInsets.all(16.r),
                    itemCount: filteredCustomers.length,
                    itemBuilder: (context, index) {
                      return CustomerCard(
                        customer: filteredCustomers[index],
                        state: widget.state,
                        term: widget.term,
                        selectedProductId: '', // Show most urgent or first
                        formatDate: _formatDate,
                        onReturn: widget.onReturn,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  bool _hasAnySubscription(CustomerEntity customer) {
    return widget.state.activeSubs.any((s) => s.customerId == customer.customerId) ||
           widget.state.expiringSoon.any((s) => s.customerId == customer.customerId);
  }

  Widget _buildSearchBox() {
    return  Container(
                    height: 80.h,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(36.r),
                        bottomRight: Radius.circular(36.r),
                      ),
                    ),
                    child: Container(
      padding: EdgeInsets.all(16.r),
      child: Container(
        height: 45.h,
        child: TextField(
          controller: _searchController,
          focusNode: _searchFocusNode,
          onChanged: (value) {
            setState(() {
              _searchQuery = value.toLowerCase().trim();
            });
          },
          decoration: InputDecoration(
            hintText: 'Search by name or mobile...',
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14.sp),
            prefixIcon: Icon(Icons.search, color: Colors.grey[400], size: 20.sp),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear, color: Colors.grey[400], size: 20.sp),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: 12.h),
          ),
        ),
      ),
    ),
                  );

  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_search_outlined, size: 64.sp, color: Colors.grey[300]),
          SizedBox(height: 16.h),
          Text(
            'No ${widget.term.customerLabel.toLowerCase()}s found',
            style: TextStyle(color: Colors.grey[500], fontSize: 16.sp),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[d.month - 1]} ${d.day.toString().padLeft(2, '0')}, ${d.year}';
  }
}
