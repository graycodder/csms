import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:csms/core/theme/app_colors.dart';
import 'package:csms/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:csms/features/customer/presentation/pages/customer_details_page.dart';
import 'package:csms/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:csms/features/auth/presentation/bloc/auth_state.dart';
import 'package:csms/features/shop/presentation/bloc/shop_context_bloc.dart';
import 'package:csms/features/notifications/presentation/bloc/notification_bloc.dart';
import 'package:csms/features/notifications/domain/entities/notification_entity.dart';
import 'package:csms/core/utils/terminology_helper.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  int _selectedTab = 0; // 0: All, 1: Expired, 2: Expiring

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocBuilder<NotificationBloc, NotificationState>(
        builder: (context, state) {
          if (state is NotificationListening) {
            final notifications = state.notifications;
            final shopState = context.watch<ShopContextBloc>().state;
            final category = shopState is ShopSelected ? shopState.selectedShop.category : '';
            final term = TerminologyHelper.getTerminology(category);
            
            return Column(
              children: [
                _buildHeader(notifications),
                Expanded(child: _buildBody(notifications, term)),
              ],
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  String _fmt(DateTime d) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[d.month - 1]} ${d.day}';
  }

  Widget _buildHeader(List<NotificationEntity> notifications) {
    int allCount = notifications.length;
    int unreadCount = notifications.where((n) => !n.isRead).length;
    int readCount = allCount - unreadCount;

    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16.h,
        left: 20.w,
        right: 20.w,
        bottom: 24.h,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24.r),
          bottomRight: Radius.circular(24.r),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              InkWell(
                onTap: () => Navigator.pop(context),
                borderRadius: BorderRadius.circular(20.r),
                child: Container(
                  padding: EdgeInsets.all(8.r),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                    size: 24.sp,
                  ),
                ),
              ),
              SizedBox(width: 16.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Notifications',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${notifications.length} alert${notifications.length == 1 ? '' : 's'}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14.sp,
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 24.h),
          Row(
            children: [
              Expanded(
                child: _buildTabButton(
                  index: 0,
                  label: 'All ($allCount)',
                  activeColor: AppColors.primary,
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: _buildTabButton(
                  index: 1,
                  label: 'Unread ($unreadCount)',
                  activeColor: const Color(0xFFDC2626),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton({
    required int index,
    required String label,
    required Color activeColor,
  }) {
    final isSelected = _selectedTab == index;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedTab = index;
        });
      },
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12.r),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? activeColor : Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14.sp,
          ),
        ),
      ),
    );
  }

  Widget _buildBody(List<NotificationEntity> notifications, BusinessTerminology term) {
    List<NotificationEntity> filteredList;
    if (_selectedTab == 1) {
      filteredList = notifications.where((n) => !n.isRead).toList();
    } else {
      filteredList = notifications;
    }

    if (filteredList.isEmpty) {
      return Center(
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 40.w),
          padding: EdgeInsets.all(32.r),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(12.r),
                decoration: const BoxDecoration(
                  color: AppColors.successBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.error_outline,
                  color: AppColors.successText,
                  size: 24.sp,
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                'All Clear!',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18.sp,
                  color: AppColors.textDark,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                _selectedTab == 1
                    ? 'No unread notifications'
                    : 'Your notification inbox is empty',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textLight,
                  fontSize: 14.sp,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: EdgeInsets.all(20.r),
      children: [
        ...filteredList.map((notification) => _buildNotificationCard(notification, term)).toList(),
      ],
    );
  }

  Widget _buildNotificationCard(NotificationEntity notification, BusinessTerminology term) {
    bool isUnread = !notification.isRead;
    Color statusColor = isUnread ? AppColors.primary : AppColors.textLight;
    Color cardBgColor = isUnread ? const Color(0xFFEFF6FF) : Colors.white;

    return GestureDetector(
      onTap: () {
        final authState = context.read<AuthBloc>().state;
        if (authState is AuthAuthenticated) {
          context.read<NotificationBloc>().add(MarkNotificationAsRead(authState.ownerId, notification.id));
        }
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: cardBgColor,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: statusColor.withOpacity(0.1)),
          boxShadow: [
            if (isUnread)
              BoxShadow(
                color: AppColors.primary.withOpacity(0.05),
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
                color: isUnread ? AppColors.primary.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                notification.type == 'subscription' ? Icons.person_add_outlined : Icons.notifications_none_outlined,
                color: statusColor,
                size: 20.sp,
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          notification.title
                              .replaceAll('Subscription', term.subscriptionLabel)
                              .replaceAll('subscription', term.subscriptionLabel.toLowerCase())
                              .replaceAll('Customer', term.customerLabel)
                              .replaceAll('customer', term.customerLabel.toLowerCase()),
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                            fontSize: 16.sp,
                            color: AppColors.textDark,
                          ),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        _fmtRelative(notification.createdAt),
                        style: TextStyle(
                          color: AppColors.textLight,
                          fontSize: 12.sp,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    notification.body
                      .replaceAll('customer', term.customerLabel.toLowerCase()),
                    style: TextStyle(
                      color: AppColors.textLight,
                      fontSize: 14.sp,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            if (isUnread)
              Container(
                width: 8.r,
                height: 8.r,
                margin: EdgeInsets.only(top: 6.h, left: 8.w),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
          ],
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
