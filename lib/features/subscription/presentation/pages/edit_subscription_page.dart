import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import 'package:csms/features/subscription/domain/entities/subscription_entity.dart';
import 'package:csms/features/customer/presentation/bloc/customer_bloc.dart';
import 'package:csms/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:csms/features/auth/presentation/bloc/auth_state.dart';
import 'package:intl/intl.dart';
import 'package:csms/core/utils/terminology_helper.dart';
import 'package:csms/core/utils/loading_overlay.dart';

class EditSubscriptionPage extends StatefulWidget {
  final SubscriptionEntity subscription;
  final String productName;
  final String shopCategory;
  final String customerName;
  final String? priceType;

  const EditSubscriptionPage({
    super.key,
    required this.subscription,
    required this.productName,
    required this.shopCategory,
    required this.customerName,
    this.priceType,
  });

  @override
  State<EditSubscriptionPage> createState() => _EditSubscriptionPageState();
}

class _EditSubscriptionPageState extends State<EditSubscriptionPage> {
  late TextEditingController _planAmountController;
  late TextEditingController _paidAmountController;
  late DateTime _selectedDate;
  final _formKey = GlobalKey<FormState>();
  final _df = DateFormat('MMM dd, yyyy');
  late String _selectedStatus;
  String _selectedPaymentMode = 'Cash';

  @override
  void initState() {
    super.initState();
    _planAmountController = TextEditingController(
      text: widget.subscription.price.toStringAsFixed(0),
    );
    _paidAmountController = TextEditingController(
      text: widget.subscription.paidAmount.toStringAsFixed(0),
    );
    _selectedDate = widget.subscription.endDate;
    _selectedStatus = widget.subscription.status;
    _selectedPaymentMode = widget.subscription.paymentMode;
  }

  @override
  void dispose() {
    _planAmountController.dispose();
    _paidAmountController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      appBar: AppBar(
        title: Text(
          'Edit ${TerminologyHelper.getTerminology(widget.shopCategory).planLabel}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: BlocConsumer<CustomerBloc, CustomerState>(
        listener: (context, state) {
          if (state is CustomerLoading) {
            LoadingOverlayHelper.show(context);
          } else if (state is CustomerSuccess) {
            LoadingOverlayHelper.hide();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Membership updated successfully!'),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
              ),
            );
            Navigator.pop(context); // Close Edit Page
          } else if (state is CustomerError) {
            LoadingOverlayHelper.hide();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error: ${state.message}'),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        builder: (context, state) {
          return SingleChildScrollView(
            padding: EdgeInsets.all(24.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Plan Amount *',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14.sp,
                  ),
                ),
                SizedBox(height: 5.h),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _planAmountController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d*'),
                          ),
                          LengthLimitingTextInputFormatter(6),
                        ],
                        readOnly: widget.priceType == 'fixed',
                        decoration: InputDecoration(
                          hintText: 'Enter plan amount',
                          prefixIcon: Icon(Icons.currency_rupee, size: 18.sp),
                          filled: widget.priceType == 'fixed',
                          fillColor: widget.priceType == 'fixed'
                              ? Colors.grey[100]
                              : null,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter an amount';
                          }
                          final price = double.tryParse(value) ?? 0;
                          if (price <= 0) {
                            return 'Amount must be greater than 0';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 12.h),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Amount Paid *',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14.sp,
                                  ),
                                ),
                                SizedBox(height: 5.h),
                                TextFormField(
                                  controller: _paidAmountController,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                      RegExp(r'^\d*\.?\d*'),
                                    ),
                                  ],
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Enter amount';
                                    }
                                    final paidAmt = double.tryParse(value) ?? 0;
                                    final planAmt =
                                        double.tryParse(
                                          _planAmountController.text,
                                        ) ??
                                        0;
                                    if (paidAmt <= 0) {
                                      return 'Must be greater than 0';
                                    }
                                    if (paidAmt > planAmt) {
                                      return 'Cannot exceed plan amount';
                                    }
                                    return null;
                                  },
                                  decoration: InputDecoration(
                                    hintText: '0',
                                    prefixIcon: Icon(
                                      Icons.currency_rupee,
                                      size: 18.sp,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Payment Mode *',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14.sp,
                                  ),
                                ),
                                SizedBox(height: 5.h),
                                DropdownButtonFormField<String>(
                                  value: _selectedPaymentMode,
                                  decoration: InputDecoration(
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 12.w,
                                      vertical: 12.h,
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12.r),
                                      borderSide: const BorderSide(
                                        color: AppColors.border,
                                      ),
                                    ),
                                  ),
                                  items:
                                      [
                                        'Cash',
                                        'UPI',
                                        'Card',
                                        'Bank Transfer',
                                      ].map((m) {
                                        return DropdownMenuItem(
                                          value: m,
                                          child: Text(
                                            m,
                                            style: TextStyle(fontSize: 14.sp),
                                          ),
                                        );
                                      }).toList(),
                                  onChanged: (v) => setState(
                                    () => _selectedPaymentMode = v ?? 'Cash',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 12.h),
                Text(
                  'Expiry Date *',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14.sp,
                  ),
                ),
                SizedBox(height: 5.h),
                InkWell(
                  onTap: _pickDate,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 14.h,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 20.sp,
                          color: AppColors.textLight,
                        ),
                        SizedBox(width: 12.w),
                        Text(
                          _df.format(_selectedDate),
                          style: TextStyle(
                            fontSize: 16.sp,
                            color: AppColors.textDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 12.h),

                Text(
                  'Status *',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14.sp,
                  ),
                ),
                SizedBox(height: 5.h),
                DropdownButtonFormField<String>(
                  value: _selectedStatus,
                  decoration: InputDecoration(
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 14.h,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'active', child: Text('Active')),
                    DropdownMenuItem(
                      value: 'inactive',
                      child: Text('Inactive'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedStatus = value);
                    }
                  },
                ),

                SizedBox(height: 40.h),

                SizedBox(
                  width: double.infinity,
                  height: 56.h,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState?.validate() ?? false) {
                        FocusManager.instance.primaryFocus?.unfocus();
                        _showConfirmDialog();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Save Changes',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showConfirmDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: const Text('Confirm Changes'),
        content: Text(
          'Are you sure you want to save the changes for the "${widget.productName}" plan?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              FocusManager.instance.primaryFocus?.unfocus();
              Navigator.pop(context);
            },
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textLight),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              FocusManager.instance.primaryFocus?.unfocus();
              Navigator.pop(context); // Close dialog

              final planAmt =
                  double.tryParse(_planAmountController.text) ??
                  widget.subscription.price;
              final paidAmt =
                  double.tryParse(_paidAmountController.text) ??
                  widget.subscription.paidAmount;

              final authState = context.read<AuthBloc>().state;
              final name = authState is AuthAuthenticated
                  ? authState.name
                  : 'Staff';

              context.read<CustomerBloc>().add(
                UpdateSubscription(
                  subscriptionId: widget.subscription.subscriptionId,
                  endDate: _selectedDate,
                  price: planAmt,
                  paidAmount: paidAmt,
                  paymentMode: _selectedPaymentMode,
                  updatedById: authState is AuthAuthenticated
                      ? authState.userId
                      : widget.subscription.updatedById,
                  ownerId: widget.subscription.ownerId,
                  shopId: widget.subscription.shopId,
                  updatedByName: name,
                  customerName: widget.customerName,
                  status: _selectedStatus,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            child: const Text('Confirm', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
