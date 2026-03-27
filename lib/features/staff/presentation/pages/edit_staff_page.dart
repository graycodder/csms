import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:csms/core/theme/app_colors.dart';
import 'package:csms/features/staff/domain/entities/staff_entity.dart';
import 'package:csms/features/staff/presentation/bloc/staff_bloc.dart';
import 'package:csms/core/utils/loading_overlay.dart';

class EditStaffPage extends StatefulWidget {
  final StaffEntity staff;

  const EditStaffPage({
    super.key,
    required this.staff,
  });

  @override
  State<EditStaffPage> createState() => _EditStaffPageState();
}

class _EditStaffPageState extends State<EditStaffPage> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  final _formKey = GlobalKey<FormState>();

  late String? _selectedRole;
  late List<String> _roles;

  @override
  void initState() {
    super.initState();
    final sanitizedName = widget.staff.name.replaceAll(RegExp(r'[^a-zA-Z\s]'), '');
    final sanitizedPhone = widget.staff.phone.replaceAll(RegExp(r'[^0-9]'), '');
    
    _nameController = TextEditingController(text: sanitizedName);
    _phoneController = TextEditingController(text: sanitizedPhone);
    _emailController = TextEditingController(text: widget.staff.email);
    
    _roles = ['Admin', 'Staff', 'Sales'];
    if (widget.staff.role.isNotEmpty && !_roles.contains(widget.staff.role)) {
      _roles.add(widget.staff.role);
    }
    _selectedRole = widget.staff.role.isEmpty ? null : widget.staff.role;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      FocusManager.instance.primaryFocus?.unfocus();
      _showConfirmDialog();
    }
  }

  void _showConfirmDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: Text('Confirm Changes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.sp)),
        content: Text('Are you sure you want to save the changes to this staff member?', style: TextStyle(fontSize: 14.sp)),
        actions: [
          TextButton(
            onPressed: () {
              FocusManager.instance.primaryFocus?.unfocus();
              Navigator.pop(ctx);
            },
            child: Text('Cancel', style: TextStyle(color: AppColors.textLight, fontSize: 14.sp)),
          ),
          ElevatedButton(
            onPressed: () {
              FocusManager.instance.primaryFocus?.unfocus();
              Navigator.pop(ctx); // Close dialog
              context.read<StaffBloc>().add(
                    UpdateStaff(
                      shopId: widget.staff.shopId,
                      ownerId: widget.staff.ownerId,
                      staff: StaffEntity(
                        staffId: widget.staff.staffId,
                        shopId: widget.staff.shopId,
                        ownerId: widget.staff.ownerId,
                        name: _nameController.text.trim(),
                        phone: _phoneController.text.trim(),
                        email: _emailController.text.trim(),
                        role: _selectedRole ?? 'Staff',
                        status: widget.staff.status,
                        createdAt: widget.staff.createdAt,
                      ),
                    ),
                  );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
            ),
            child: Text('Confirm', style: TextStyle(color: Colors.white, fontSize: 14.sp)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
        ),
        title: Text(
          'Edit Staff Member',
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
            fontSize: 18.sp,
          ),
        ),
      ),
      body: BlocConsumer<StaffBloc, StaffState>(
        listener: (context, state) {
          if (state is StaffLoading) {
            LoadingOverlay.show(context);
          } else if (state is StaffLoaded) {
            LoadingOverlay.hide();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Staff updated successfully!', style: TextStyle(fontSize: 14.sp)),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
              ),
            );
            Navigator.pop(context);
          } else if (state is StaffError) {
            LoadingOverlay.hide();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message, style: TextStyle(fontSize: 14.sp)),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        builder: (context, state) {
          return SingleChildScrollView(
            padding: EdgeInsets.all(24.r),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel('Full Name *'),
                  TextFormField(
                    controller: _nameController,
                    decoration: _inputDecoration('Enter full name'),
                    validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                  ),
                  SizedBox(height: 16.h),
                  _buildLabel('Phone Number *'),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: _inputDecoration('Enter phone number'),
                    validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                  ),
                  SizedBox(height: 16.h),
                  _buildLabel('Email Address *'),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: _inputDecoration('Enter email address'),
                    validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                  ),
                  SizedBox(height: 16.h),
                  _buildLabel('Role *'),
                  DropdownButtonFormField<String>(
                    value: _selectedRole,
                    items: _roles.map((r) => DropdownMenuItem(value: r, child: Text(r, style: TextStyle(fontSize: 14.sp)))).toList(),
                    onChanged: (v) => setState(() => _selectedRole = v),
                    decoration: _inputDecoration('Select role'),
                    validator: (v) => v == null ? 'Required' : null,
                  ),
                  SizedBox(height: 32.h),
                  SizedBox(
                    width: double.infinity,
                    height: 52.h,
                    child: ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                        elevation: 0,
                      ),
                      child: Text(
                        'Save Changes',
                        style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14.sp,
          color: AppColors.textDark,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      counterText: '',
      hintStyle: TextStyle(color: const Color(0xFFBDBDBD), fontSize: 14.sp),
      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: BorderSide(color: AppColors.primary, width: 1.5.w),
      ),
    );
  }
}
