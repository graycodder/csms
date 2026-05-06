import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_colors.dart';
import '../bloc/profile_bloc.dart';
import '../bloc/profile_state.dart';
import '../bloc/profile_event.dart';
import 'edit_profile_page.dart';

class ProfilePageMobile extends StatelessWidget {
  final String userId;
  final ProfileLoaded state;

  const ProfilePageMobile({
    super.key,
    required this.userId,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final p = state.profile;
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'My Profile',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18.sp,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            onPressed: () async {
              final updated = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EditProfilePage(profile: p),
                ),
              );
              if (updated == true) {
                if (context.mounted) {
                  context.read<ProfileBloc>().add(LoadProfile(userId));
                }
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24.r),
        child: Column(
          children: [
            _buildAvatar(p.fullName),
            SizedBox(height: 16.h),
            Text(
              p.fullName,
              style: TextStyle(
                fontSize: 22.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            Text(
              p.role.toUpperCase(),
              style: TextStyle(
                fontSize: 14.sp,
                color: AppColors.primary.withOpacity(0.8),
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2.w,
              ),
            ),
            SizedBox(height: 32.h),
            _buildInfoCard(p),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(String name) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Container(
      width: 100.w,
      height: 100.w,
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.primary, width: 2),
      ),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            fontSize: 40.sp,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(dynamic p) {
    return Container(
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10.r,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildInfoRow(Icons.person_outline, 'Name', p.fullName),
          Divider(height: 32.h),
          _buildInfoRow(Icons.email_outlined, 'Email', p.email),
          Divider(height: 32.h),
          _buildInfoRow(
            Icons.phone_outlined,
            'Phone',
            p.phone.isEmpty ? 'Not set' : p.phone,
          ),
          Divider(height: 32.h),
          _buildInfoRow(
            Icons.calendar_today_outlined,
            'Member Since',
            '${p.createdAt.day}/${p.createdAt.month}/${p.createdAt.year}',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: AppColors.textLight, size: 22.sp),
        SizedBox(width: 16.w),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(color: AppColors.textLight, fontSize: 13.sp),
            ),
            SizedBox(height: 2.h),
            Text(
              value,
              style: TextStyle(
                color: AppColors.textDark,
                fontSize: 15.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
