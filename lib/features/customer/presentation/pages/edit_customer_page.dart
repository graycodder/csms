import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_colors.dart';
import 'package:csms/features/customer/domain/entities/customer_entity.dart';
import 'package:csms/features/product/domain/entities/product_entity.dart';
import 'package:csms/features/customer/presentation/bloc/customer_bloc.dart';
import 'package:csms/core/utils/loading_overlay.dart';
import 'package:csms/core/utils/terminology_helper.dart';

class EditCustomerPage extends StatefulWidget {
  final CustomerEntity customer;
  final List<ProductEntity> products;
  final String shopCategory;

  const EditCustomerPage({
    super.key,
    required this.customer,
    required this.products,
    required this.shopCategory,
  });

  @override
  State<EditCustomerPage> createState() => _EditCustomerPageState();
}

class _EditCustomerPageState extends State<EditCustomerPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _registrationFeeController;
  late String _selectedStatus;
  late String _selectedRegStatus;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.customer.name);
    _phoneController = TextEditingController(
      text: widget.customer.mobileNumber,
    );
    _registrationFeeController = TextEditingController(
      text: widget.customer.registrationFeePaidAmount.toStringAsFixed(0),
    );
    _selectedStatus = widget.customer.status;
    _selectedRegStatus = widget.customer.registrationFeeStatus;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _registrationFeeController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      FocusManager.instance.primaryFocus?.unfocus();
      _showConfirmDialog();
    }
  }

  void _showConfirmDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Text(
          'Confirm Changes',
          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to save the changes for "${_nameController.text.trim()}"?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              FocusManager.instance.primaryFocus?.unfocus();
              Navigator.pop(context);
            },
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.textLight, fontSize: 14.sp),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              FocusManager.instance.primaryFocus?.unfocus();
              Navigator.pop(context);
              final regAmount =
                  double.tryParse(_registrationFeeController.text.trim()) ??
                  0.0;
              double newRegPaid = widget.customer.registrationFeePaidAmount;

              if (_selectedRegStatus == 'paid') {
                newRegPaid = regAmount;
              } else if (_selectedRegStatus == 'unpaid') {
                newRegPaid = 0.0;
              }

              final updated = widget.customer.copyWith(
                name: _nameController.text.trim(),
                mobileNumber: _phoneController.text.trim(),
                status: _selectedStatus,
                registrationFeeAmount: regAmount,
                registrationFeePaidAmount: newRegPaid,
                registrationFeeStatus: _selectedRegStatus,
                updatedAt: DateTime.now(),
              );

              context.read<CustomerBloc>().add(
                UpdateCustomerInfo(customer: updated),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            child: Text(
              'Confirm',
              style: TextStyle(color: Colors.white, fontSize: 14.sp),
            ),
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
        leadingWidth: 48.w,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Edit ${TerminologyHelper.getTerminology(widget.shopCategory).customerLabel}',
              style: TextStyle(
                color: AppColors.textDark,
                fontWeight: FontWeight.bold,
                fontSize: 18.sp,
              ),
            ),
            Text(
              'Update ${TerminologyHelper.getTerminology(widget.shopCategory).customerLabel.toLowerCase()} details',
              style: TextStyle(
                color: AppColors.textLight.withOpacity(0.8),
                fontSize: 13.sp,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1.0.h),
          child: Container(color: AppColors.border, height: 1.0.h),
        ),
      ),
      body: BlocConsumer<CustomerBloc, CustomerState>(
        listener: (context, state) {
          if (state is CustomerLoading) {
            LoadingOverlayHelper.show(context);
          } else if (state is CustomerSuccess) {
            LoadingOverlayHelper.hide();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '${TerminologyHelper.getTerminology(widget.shopCategory).customerLabel} updated successfully!',
                ),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
              ),
            );
            Navigator.pop(context);
          } else if (state is CustomerError) {
            LoadingOverlayHelper.hide();
            if (state.message.contains('already used')) {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  title: Text(
                    'Number Already Used',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  content: Text(
                    state.message,
                    style: TextStyle(fontSize: 14.sp),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(
                        'OK',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14.sp,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${state.message}'),
                  backgroundColor: Colors.red,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          }
        },
        builder: (context, state) {
          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel(
                    '${TerminologyHelper.getTerminology(widget.shopCategory).customerLabel} Name *',
                  ),
                  TextFormField(
                    controller: _nameController,
                    maxLength: 20,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'[a-zA-Z0-9\s]'),
                      ),
                    ],
                    decoration: InputDecoration(
                      hintText:
                          'Enter ${TerminologyHelper.getTerminology(widget.shopCategory).customerLabel.toLowerCase()} name',
                      prefixIcon: const Icon(Icons.person_outline),
                      counterText: '',
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty)
                        return 'Name is required';
                      if (v.length > 20) return 'Maximum 20 characters';
                      if (RegExp(
                        r'[!@#<>?":_`~;[\]\\|=+)(*&^%/-]',
                      ).hasMatch(v)) {
                        return 'Special characters not allowed';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 20.h),

                  _buildLabel('Phone Number *'),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.number,
                    maxLength: 10,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      hintText: 'Enter 10-digit phone number',
                      prefixIcon: Icon(Icons.phone_outlined),
                      counterText: '',
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Phone is required';
                      if (v.length != 10) return 'Must be exactly 10 digits';
                      if (!RegExp(r'^[0-9]+$').hasMatch(v))
                        return 'Numbers only';
                      return null;
                    },
                  ),
                  SizedBox(height: 20.h),

                  // Customer Status
                  _buildLabel('Account Status'),
                  Row(
                    children: [
                      Expanded(
                        child: _statusButton(
                          label: 'Active',
                          isActive: _selectedStatus.toLowerCase() == 'active',
                          onPressed: () =>
                              setState(() => _selectedStatus = 'active'),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: _statusButton(
                          label: 'Inactive',
                          isActive: _selectedStatus.toLowerCase() == 'inactive',
                          onPressed: () =>
                              setState(() => _selectedStatus = 'inactive'),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20.h),

                  // Registration Fee
                  _buildLabel('Registration Fee'),
                  TextFormField(
                    controller: _registrationFeeController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                    ],
                    decoration: const InputDecoration(
                      hintText: 'Enter registration fee',
                      prefixIcon: Icon(Icons.currency_rupee),
                    ),
                  ),
                  SizedBox(height: 20.h),

                  _buildLabel('Registration Status'),
                  DropdownButtonFormField<String>(
                    value: _selectedRegStatus,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.assignment_turned_in_outlined),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'paid', child: Text('Paid')),
                      DropdownMenuItem(
                        value: 'partial',
                        child: Text('Partial'),
                      ),
                      DropdownMenuItem(value: 'unpaid', child: Text('Unpaid')),
                    ],
                    onChanged: (v) {
                      if (v != null) setState(() => _selectedRegStatus = v);
                    },
                  ),
                  SizedBox(height: 32.h),

                  SizedBox(
                    width: double.infinity,
                    height: 52.h,
                    child: ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      child: Text(
                        'Save Changes',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 20.h),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _statusButton({
    required String label,
    required bool isActive,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        decoration: BoxDecoration(
          color: isActive
              ? (label == 'Active'
                    ? AppColors.success.withOpacity(0.1)
                    : Colors.red.withOpacity(0.1))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isActive
                ? (label == 'Active' ? AppColors.success : Colors.red)
                : AppColors.border,
            width: 1.5,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isActive
                  ? (label == 'Active' ? AppColors.success : Colors.red)
                  : AppColors.textLight,
              fontWeight: FontWeight.bold,
              fontSize: 14.sp,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: AppColors.textDark,
          fontSize: 14.sp,
        ),
      ),
    );
  }
}
