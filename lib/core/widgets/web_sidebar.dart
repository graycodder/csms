import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:csms/core/theme/app_colors.dart';
import 'package:csms/core/utils/terminology_helper.dart';
import 'package:csms/features/shop/presentation/bloc/shop_context_bloc.dart';
import 'package:csms/features/reports/presentation/pages/report_page.dart';
import 'package:csms/features/customer/presentation/pages/customer_list_page.dart';
import 'package:csms/features/shop/presentation/pages/shop_management_page.dart';

class WebSidebar extends StatelessWidget {
  final int selectedIndex;

  const WebSidebar({super.key, required this.selectedIndex});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ShopContextBloc, ShopContextState>(
      builder: (context, state) {
        final shopName = state is ShopSelected
            ? state.selectedShop.shopName
            : 'Shop Details';
        final term = state is ShopSelected
            ? TerminologyHelper.getTerminology(state.selectedShop.category)
            : TerminologyHelper.getTerminology('default');

        return Container(
          width: 250,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              right: BorderSide(color: Colors.grey.withOpacity(0.1)),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
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
                      'Shop Management',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _sidebarItem(
                context,
                0,
                Icons.home_outlined,
                'Dashboard',
                isSelected: selectedIndex == 0,
                onTap: () {
                  if (selectedIndex != 0) {
                    Navigator.popUntil(context, (r) => r.isFirst);
                  }
                },
              ),
              _sidebarItem(
                context,
                1,
                Icons.bar_chart_outlined,
                'Reports',
                isSelected: selectedIndex == 1,
                onTap: () {
                  if (selectedIndex != 1) {
                    if (selectedIndex == 0) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ReportPage()),
                      );
                    } else {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const ReportPage()),
                      );
                    }
                  }
                },
              ),
              _sidebarItem(
                context,
                2,
                Icons.people_outline,
                '${term.customerLabel}s',
                isSelected: selectedIndex == 2,
                onTap: () {
                  if (selectedIndex != 2) {
                    if (selectedIndex == 0) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              CustomerListPage(term: term, onReturn: () {}),
                        ),
                      );
                    } else {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              CustomerListPage(term: term, onReturn: () {}),
                        ),
                      );
                    }
                  }
                },
              ),
              _sidebarItem(
                context,
                3,
                Icons.settings_outlined,
                'Shop Settings',
                isSelected: selectedIndex == 3,
                onTap: () {
                  if (selectedIndex != 3) {
                    if (selectedIndex == 0) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ShopManagementPage(),
                        ),
                      );
                    } else {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ShopManagementPage(),
                        ),
                      );
                    }
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _sidebarItem(
    BuildContext context,
    int index,
    IconData icon,
    String title, {
    required bool isSelected,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primary : Colors.grey[600],
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? AppColors.primary : Colors.grey[800],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
