import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:csms/core/theme/app_colors.dart';
import 'package:csms/features/shop/presentation/bloc/shop_context_bloc.dart';
import 'package:csms/features/staff/domain/entities/staff_entity.dart';
import 'package:csms/features/staff/presentation/bloc/staff_bloc.dart';
import 'package:csms/features/staff/presentation/widgets/staff_item_card.dart';
import 'package:csms/features/staff/presentation/pages/add_staff_page.dart';
import 'package:csms/features/staff/presentation/pages/edit_staff_page.dart';
import 'package:csms/core/utils/loading_overlay.dart';
import 'package:lottie/lottie.dart';
import 'package:csms/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:csms/features/auth/presentation/bloc/auth_state.dart';

class StaffManagementPage extends StatefulWidget {
  const StaffManagementPage({super.key});

  @override
  State<StaffManagementPage> createState() => _StaffManagementPageState();
}

class _StaffManagementPageState extends State<StaffManagementPage> {

  ({String shopId, String ownerId})? _shopContext(BuildContext context) {
    final shopState = context.read<ShopContextBloc>().state;
    if (shopState is ShopSelected) return (shopId: shopState.selectedShop.shopId, ownerId: shopState.selectedShop.ownerId);
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
      backgroundColor: const Color(0xFFF2F4F7),
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: BlocConsumer<StaffBloc, StaffState>(
              listener: (context, state) {
                if (state is StaffLoaded) {
                  LoadingOverlayHelper.hide();
                } else if (state is StaffError) {
                  LoadingOverlayHelper.hide();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message, style: TextStyle(fontSize: 14.sp)),
                      backgroundColor: Colors.redAccent,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              builder: (context, state) {
                final authState = context.read<AuthBloc>().state;
                final currentUserId =
                    authState is AuthAuthenticated ? authState.userId : null;
                final currentUserRole =
                    authState is AuthAuthenticated ? authState.role : 'staff';

                List<StaffEntity> filteredList = [];
                if (state is StaffLoaded) {
                  filteredList = state.staffList.where((s) {
                    if (currentUserRole != 'owner' && s.staffId == currentUserId) {
                      return false;
                    }
                    return true;
                  }).toList();
                }

                return ListView(
                  padding: EdgeInsets.fromLTRB(16.w, 20.h, 16.w, 24.h),
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Team Members',
                            style: TextStyle(
                              fontSize: 17.sp,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1A1A2E),
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            final shop = _shopContext(context);
                            final staffBloc = context.read<StaffBloc>();
                            if (shop != null) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => BlocProvider.value(
                                    value: staffBloc,
                                    child: AddStaffPage(
                                      shopId: shop.shopId,
                                      ownerId: shop.ownerId,
                                    ),
                                  ),
                                ),
                              );
                            }
                          },
                          child: Row(
                            children: [
                              Icon(Icons.person_add_alt_1_outlined,
                                  size: 16.sp, color: AppColors.primary),
                              SizedBox(width: 4.w),
                              Text(
                                'Add Staff',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14.sp,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16.h),

                    if (state is StaffLoading)
                      Center(
                        child: Padding(
                          padding: EdgeInsets.all(32.r),
                          child: Lottie.asset(
                            'assets/animations/loading.json',
                            width: 80.w,
                            height: 80.w,
                          ),
                        ),
                      )
                    else if (state is StaffError)
                      _buildError(state.message)
                    else if (state is StaffLoaded && filteredList.isEmpty)
                      _buildEmptyState()
                    else if (state is StaffLoaded)
                      ...filteredList.map((s) {
                        return StaffItemCard(
                          key: ValueKey(s.staffId),
                          staff: s,
                          onEdit: () {
                            final staffBloc = context.read<StaffBloc>();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => BlocProvider.value(
                                  value: staffBloc,
                                  child: EditStaffPage(staff: s),
                                ),
                              ),
                            );
                          },
                          onToggleStatus: () {
                            _showToggleConfirmation(context, s);
                          },
                        );
                      })
                    else if (state is StaffInitial)
                      _buildEmptyState(),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16.h,
        left: 20.w,
        right: 20.w,
        bottom: 28.h,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28.r),
          bottomRight: Radius.circular(28.r),
        ),
      ),
      child: Row(
        children: [
          InkWell(
            onTap: () => Navigator.pop(context),
            borderRadius: BorderRadius.circular(20.r),
            child: Container(
              padding: EdgeInsets.all(8.r),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.arrow_back, color: Colors.white, size: 22.sp),
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Staff Management',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22.sp,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.2,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  'Configure and manage',
                  style: TextStyle(color: Colors.white70, fontSize: 13.sp),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      margin: EdgeInsets.only(top: 4.h),
      padding: EdgeInsets.symmetric(vertical: 40.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFE0E0E0).withOpacity(0.6)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.group_outlined, size: 52.sp, color: const Color(0xFFBDBDBD)),
          SizedBox(height: 12.h),
          Text(
            'No staff members yet',
            style: TextStyle(
              fontSize: 15.sp,
              color: const Color(0xFF9E9E9E),
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            'Add your first team member to get started',
            style: TextStyle(fontSize: 13.sp, color: const Color(0xFFBDBDBD)),
          ),
        ],
      ),
    );
  }

  Widget _buildError(String message) {
    return Padding(
      padding: EdgeInsets.all(24.r),
      child: Column(
        children: [
          Icon(Icons.cloud_off_outlined, size: 48.sp, color: Colors.grey),
          SizedBox(height: 12.h),
          Text(message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 14.sp)),
          SizedBox(height: 12.h),
          TextButton.icon(
            onPressed: () {
              final shop = _shopContext(context);
              if (shop != null) {
                context
                    .read<StaffBloc>()
                    .add(LoadStaff(shop.shopId, shop.ownerId));
              }
            },
            icon: const Icon(Icons.refresh),
            label: Text('Retry', style: TextStyle(fontSize: 14.sp)),
          ),
        ],
      ),
    );
  }

  void _showToggleConfirmation(BuildContext context, StaffEntity staff) {
    final isActive = staff.status == 'active';
    final actionText = isActive ? 'Deactivate' : 'Activate';
    final color = isActive ? Colors.redAccent : Colors.green;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: Text(
          '$actionText Staff Member?',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.sp),
        ),
        content: Text(
          'Are you sure you want to ${actionText.toLowerCase()} ${staff.name}?',
          style: TextStyle(color: AppColors.textLight, fontSize: 14.sp),
        ),
        actionsPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        actions: [
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFFF2F4F7),
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: const Color(0xFF1F2937),
                      fontWeight: FontWeight.bold,
                      fontSize: 14.sp,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    final shop = _shopContext(this.context);
                    if (shop != null) {
                      LoadingOverlayHelper.show(this.context);
                      this.context.read<StaffBloc>().add(
                            ToggleStaffStatus(
                                shopId: shop.shopId,
                                ownerId: shop.ownerId,
                                staff: staff),
                          );
                    }
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    actionText,
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14.sp),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
