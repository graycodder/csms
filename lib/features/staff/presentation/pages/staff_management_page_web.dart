import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:csms/core/theme/app_colors.dart';
import 'package:csms/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:csms/features/auth/presentation/bloc/auth_state.dart';
import 'package:csms/features/shop/presentation/bloc/shop_context_bloc.dart';
import 'package:csms/features/staff/domain/entities/staff_entity.dart';
import 'package:csms/features/staff/presentation/bloc/staff_bloc.dart';
import 'package:csms/features/staff/presentation/pages/add_staff_page.dart';
import 'package:csms/features/staff/presentation/pages/edit_staff_page.dart';
import 'package:csms/core/utils/loading_overlay.dart';

class StaffManagementPageWeb extends StatefulWidget {
  const StaffManagementPageWeb({super.key});

  @override
  State<StaffManagementPageWeb> createState() => _StaffManagementPageWebState();
}

class _StaffManagementPageWebState extends State<StaffManagementPageWeb> {
  ({String shopId, String ownerId})? _shopContext(BuildContext context) {
    final shopState = context.read<ShopContextBloc>().state;
    if (shopState is ShopSelected) {
      return (
        shopId: shopState.selectedShop.shopId,
        ownerId: shopState.selectedShop.ownerId,
      );
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final shop = _shopContext(context);
      if (shop != null) {
        context.read<StaffBloc>().add(LoadStaff(shop.shopId, shop.ownerId));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      body: Row(
        children: [
          _buildSidebar(context),
          Expanded(
            child: Column(
              children: [
                _buildHeader(context),
                Expanded(
                  child: BlocConsumer<StaffBloc, StaffState>(
                    listener: (context, state) {
                      if (state is StaffLoading) {
                        // handled by builder, or we could show overlay if it's a toggle operation
                      } else if (state is StaffLoaded) {
                        LoadingOverlayHelper.hide();
                      } else if (state is StaffError) {
                        LoadingOverlayHelper.hide();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(state.message),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    builder: (context, state) {
                      final authState = context.read<AuthBloc>().state;
                      final currentUserId = authState is AuthAuthenticated
                          ? authState.userId
                          : null;
                      final currentUserRole = authState is AuthAuthenticated
                          ? authState.role
                          : 'staff';

                      List<StaffEntity> filteredList = [];
                      if (state is StaffLoaded) {
                        filteredList = state.staffList.where((s) {
                          if (currentUserRole != 'owner' &&
                              s.staffId == currentUserId) {
                            return false;
                          }
                          return true;
                        }).toList();
                      }

                      return ListView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 32,
                        ),
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Team Members',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              TextButton.icon(
                                onPressed: () {
                                  final shop = _shopContext(context);
                                  if (shop != null) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => AddStaffPage(
                                          shopId: shop.shopId,
                                          ownerId: shop.ownerId,
                                        ),
                                      ),
                                    );
                                  }
                                },
                                icon: const Icon(
                                  Icons.person_add_alt_1_outlined,
                                  size: 20,
                                ),
                                label: const Text(
                                  'Add Staff',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                                style: TextButton.styleFrom(
                                  foregroundColor: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          if (state is StaffLoading)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.all(32.0),
                                child: CircularProgressIndicator(),
                              ),
                            )
                          else if (state is StaffError)
                            _buildError(state.message)
                          else if (state is StaffLoaded)
                            if (filteredList.isEmpty)
                              _buildEmptyState()
                            else
                              ...filteredList.map(
                                (s) => _buildStaffCard(context, s),
                              )
                          else
                            _buildEmptyState(),
                        ],
                      );
                    },
                  ),
                ),
              ],
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
                      'Shop Management',
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
            0,
            Icons.grid_view_outlined,
            'Dashboard',
            onTap: () => Navigator.popUntil(context, (r) => r.isFirst),
          ),
          _sidebarItem(context, 1, Icons.bar_chart_outlined, 'Reports'),
          _sidebarItem(context, 2, Icons.people_outline, 'Customers'),
          // const Spacer(),
          // const Divider(height: 1),
          // BlocBuilder<ShopContextBloc, ShopContextState>(
          //   builder: (context, state) {
          //     final shopName = state is ShopSelected
          //         ? state.selectedShop.shopName
          //         : 'Shop Details';
          //     return Padding(
          //       padding: const EdgeInsets.all(24.0),
          //       child: Column(
          //         crossAxisAlignment: CrossAxisAlignment.start,
          //         children: [
          //           Text(
          //             'Current Shop',
          //             style: TextStyle(fontSize: 10, color: Colors.grey[500]),
          //           ),
          //           const SizedBox(height: 4),
          //           Text(
          //             shopName,
          //             style: const TextStyle(
          //               fontSize: 14,
          //               fontWeight: FontWeight.bold,
          //             ),
          //             overflow: TextOverflow.ellipsis,
          //           ),
          //           const SizedBox(height: 2),
          //           Text(
          //             'ID: 1',
          //             style: TextStyle(fontSize: 10, color: Colors.grey[500]),
          //           ),
          //         ],
          //       ),
          //     );
          //   },
          // ),
        ],
      ),
    );
  }

  Widget _sidebarItem(
    BuildContext context,
    int index,
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
            const SizedBox(width: 16),
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

  Widget _buildHeader(BuildContext context) {
    return Container(
      height: 120,
      padding: const EdgeInsets.symmetric(horizontal: 40),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          InkWell(
            onTap: () => Navigator.pop(context),
            borderRadius: BorderRadius.circular(24),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_back,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 24),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Staff Management',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Configure and manage',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStaffCard(BuildContext context, StaffEntity staff) {
    final bool isInactive = staff.status == 'inactive';
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    staff.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isInactive ? Colors.grey : Colors.black87,
                      decoration: isInactive
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: !isInactive ? Colors.green[50] : Colors.red[50],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      !isInactive ? 'Active' : 'Inactive',
                      style: TextStyle(
                        color: !isInactive
                            ? Colors.green[700]
                            : Colors.red[700],
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  // if (staff.role == 'admin') ...[
                  //   const SizedBox(width: 8),
                  //   Container(
                  //     padding: const EdgeInsets.symmetric(
                  //       horizontal: 8,
                  //       vertical: 2,
                  //     ),
                  //     decoration: BoxDecoration(
                  //       color: Colors.blue.withOpacity(0.1),
                  //       borderRadius: BorderRadius.circular(8),
                  //     ),
                  //     child: const Text(
                  //       'Admin',
                  //       style: TextStyle(
                  //         color: Colors.blue,
                  //         fontSize: 10,
                  //         fontWeight: FontWeight.bold,
                  //       ),
                  //     ),
                  //   ),
                  // ],
                ],
              ),
              const SizedBox(height: 8),
              Text(
                staff.role,
                style: TextStyle(
                  color: !isInactive
                      ? const Color(0xFF6B7280)
                      : Colors.grey[400],
                  fontSize: 13,
                ),
              ),
              SizedBox(width: 2),
              Text(
                'Phone: ${staff.phone}',
                style: TextStyle(fontSize: 13, color: Colors.grey[500]),
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditStaffPage(staff: staff),
                    ),
                  );
                },
                icon: const Icon(
                  Icons.edit_outlined,
                  color: AppColors.primary,
                  size: 20,
                ),
                tooltip: 'Edit',
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () {
                  _showToggleConfirmation(context, staff);
                },
                icon: Icon(
                  !isInactive ? Icons.toggle_on : Icons.toggle_off,
                  color: !isInactive
                      ? const Color(0xFF10B981)
                      : Colors.redAccent,
                  size: 40,
                ),
                tooltip: !isInactive ? 'Activate' : 'Deactivate',
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showToggleConfirmation(BuildContext context, StaffEntity staff) {
    final isActive = staff.status == 'active';
    final actionText = isActive ? 'Deactivate' : 'Activate';
    final color = isActive ? Colors.redAccent : const Color(0xFF10B981);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          '$actionText Staff Member?',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to ${actionText.toLowerCase()} ${staff.name}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              final shop = _shopContext(context);
              if (shop != null) {
                LoadingOverlayHelper.show(context);
                context.read<StaffBloc>().add(
                  ToggleStaffStatus(
                    shopId: shop.shopId,
                    ownerId: shop.ownerId,
                    staff: staff,
                  ),
                );
              }
            },
            child: Text(
              actionText,
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 80),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.group_outlined, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No staff members yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Add your first team member to get started',
            style: TextStyle(fontSize: 13, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_off_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(message, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: () {
              final shop = _shopContext(context);
              if (shop != null) {
                context.read<StaffBloc>().add(
                  LoadStaff(shop.shopId, shop.ownerId),
                );
              }
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
