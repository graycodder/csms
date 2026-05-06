import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:csms/features/notifications/presentation/bloc/notification_bloc.dart';
import 'package:csms/features/notifications/domain/entities/notification_entity.dart';
import 'package:csms/core/utils/terminology_helper.dart';
import 'package:csms/features/shop/presentation/bloc/shop_context_bloc.dart';
import 'package:csms/features/reports/presentation/pages/report_page.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class NotificationsPageWeb extends StatefulWidget {
  final List<NotificationEntity> notifications;
  final String shopCategory;
  final String ownerId;

  const NotificationsPageWeb({
    super.key,
    required this.notifications,
    required this.shopCategory,
    required this.ownerId,
  });

  @override
  State<NotificationsPageWeb> createState() => _NotificationsPageWebState();
}

class _NotificationsPageWebState extends State<NotificationsPageWeb> {
  int _selectedTab = 0; // 0: All, 1: Expired, 2: Expiring
  final int _selectedNavIndex = 5; // Notifications is typically at index 5

  @override
  Widget build(BuildContext context) {
    final term = TerminologyHelper.getTerminology(widget.shopCategory);
    final shopState = context.watch<ShopContextBloc>().state;
    String shopName = 'Downtown Boutique';
    if (shopState is ShopSelected) {
      shopName = shopState.selectedShop.shopName;
    }

    // Filter logic
    List<NotificationEntity> filteredList = widget.notifications;
    if (_selectedTab == 1) {
      filteredList = widget.notifications
          .where((n) => n.type == 'expired')
          .toList();
    } else if (_selectedTab == 2) {
      filteredList = widget.notifications
          .where((n) => n.type == 'expiring')
          .toList();
    }

    return Row(
      children: [
        _buildSidebar(shopName),
        Expanded(
          child: Column(
            children: [
              _buildHeader(widget.notifications),
              Expanded(
                child: Container(
                  color: const Color(0xFFF0F2F5),
                  width: double.infinity,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(40),
                    child: _buildNotificationContent(filteredList, term),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSidebar(String shopName) {
    return Container(
      width: 250,
      color: Colors.white,
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
                const Text(
                  'Shop Management',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _sidebarItem(
            0,
            Icons.home_outlined,
            'Dashboard',
            onTap: () {
              Navigator.popUntil(context, (route) => route.isFirst);
            },
          ),
          _sidebarItem(
            1,
            Icons.bar_chart_outlined,
            'Reports',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ReportPage()),
              );
            },
          ),
          _sidebarItem(2, Icons.people_outline, 'Customers'),
          // const Spacer(),
          // const Divider(height: 1),
          // Padding(
          //   padding: const EdgeInsets.all(24.0),
          //   child: Column(
          //     crossAxisAlignment: CrossAxisAlignment.start,
          //     children: [
          //       const Text(
          //         'Current Shop',
          //         style: TextStyle(fontSize: 10, color: Colors.grey),
          //       ),
          //       const SizedBox(height: 4),
          //       Text(
          //         shopName,
          //         style: const TextStyle(
          //           fontSize: 14,
          //           fontWeight: FontWeight.bold,
          //         ),
          //         overflow: TextOverflow.ellipsis,
          //       ),
          //       const SizedBox(height: 2),
          //       const Text(
          //         'ID: 1',
          //         style: TextStyle(fontSize: 10, color: Colors.grey),
          //       ),
          //     ],
          //   ),
          // ),
        ],
      ),
    );
  }

  Widget _sidebarItem(
    int index,
    IconData icon,
    String title, {
    VoidCallback? onTap,
  }) {
    final isSelected = _selectedNavIndex == index;
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
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(List<NotificationEntity> notifications) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFF1E56F0),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(32, 48, 32, 24),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Colors.white12,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Notifications',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        '${notifications.length} alerts',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
            child: _buildTabSwitcher(notifications),
          ),
        ],
      ),
    );
  }

  Widget _buildTabSwitcher(List<NotificationEntity> notifications) {
    int allCount = notifications.length;
    int unreadCount = notifications.where((n) => !n.isRead).length;

    return Row(
      children: [
        Expanded(child: _tabItem(0, 'All', allCount)),
        const SizedBox(width: 12),
        Expanded(child: _tabItem(1, 'Unread', unreadCount)),
      ],
    );
  }

  Widget _tabItem(int index, String label, int count) {
    bool isSelected = _selectedTab == index;

    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Text(
          '$label ($count)',
          style: TextStyle(
            color: isSelected ? const Color(0xFF1E56F0) : Colors.white,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationContent(
    List<NotificationEntity> notifications,
    dynamic term,
  ) {
    if (notifications.isEmpty) {
      return _buildEmptyState(term);
    }

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 800.w),
        child: ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: notifications.length,
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemBuilder: (context, index) =>
              _buildNotificationCard(notifications[index], term),
        ),
      ),
    );
  }

  Widget _buildEmptyState(dynamic term) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 80),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFFE8F5E9),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.error_outline,
              color: Color(0xFF4CAF50),
              size: 40,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'All Clear!',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No ${term.subscriptionLabel.toLowerCase()} alerts at this time',
            style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(NotificationEntity n, dynamic term) {
    bool isUnread = !n.isRead;
    Color statusColor = n.type == 'expired'
        ? const Color(0xFFEF4444)
        : (n.type == 'expiring'
              ? const Color(0xFFF59E0B)
              : const Color(0xFF1E56F0));

    // Apply terminology replacements
    final displayTitle = n.title
        .replaceAll('Subscription', term.subscriptionLabel)
        .replaceAll('subscription', term.subscriptionLabel.toLowerCase())
        .replaceAll('Customer', term.customerLabel)
        .replaceAll('customer', term.customerLabel.toLowerCase());

    final displayBody = n.body
        .replaceAll('Subscription', term.subscriptionLabel)
        .replaceAll('subscription', term.subscriptionLabel.toLowerCase())
        .replaceAll('Customer', term.customerLabel)
        .replaceAll('customer', term.customerLabel.toLowerCase());

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          if (isUnread && widget.ownerId.isNotEmpty) {
            context.read<NotificationBloc>().add(
              MarkNotificationAsRead(widget.ownerId, n.id),
            );
          }
        },
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isUnread ? const Color(0xFFF8FAFF) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isUnread
                  ? const Color(0xFF1E56F0).withOpacity(0.1)
                  : const Color(0xFFE5E7EB),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isUnread ? 0.04 : 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  n.type == 'expired'
                      ? Icons.error_outline
                      : Icons.notifications_none,
                  color: statusColor,
                  size: 24,
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
                          displayTitle,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: isUnread
                                ? FontWeight.bold
                                : FontWeight.w600,
                            color: const Color(0xFF111827),
                          ),
                        ),
                        if (isUnread) ...[
                          const SizedBox(width: 8),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFF1E56F0),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      displayBody,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6B7280),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _fmtRelative(n.createdAt),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      n.type.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _fmtRelative(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }
}
