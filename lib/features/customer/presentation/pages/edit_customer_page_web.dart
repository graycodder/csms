import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_colors.dart';
import 'package:csms/features/customer/domain/entities/customer_entity.dart';
import 'package:csms/features/product/domain/entities/product_entity.dart';
import 'package:csms/features/customer/presentation/bloc/customer_bloc.dart';
import 'package:csms/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:csms/features/subscription/domain/entities/subscription_entity.dart';
import 'package:csms/core/utils/loading_overlay.dart';
import 'package:csms/core/utils/terminology_helper.dart';
import 'package:csms/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:csms/features/auth/presentation/bloc/auth_state.dart';
import 'package:csms/core/widgets/web_sidebar.dart';

class EditCustomerPageWeb extends StatefulWidget {
  final CustomerEntity customer;
  final List<ProductEntity> products;
  final String shopCategory;
  final bool registrationFeeEnabled;

  const EditCustomerPageWeb({
    super.key,
    required this.customer,
    required this.products,
    required this.shopCategory,
    this.registrationFeeEnabled = true,
  });

  @override
  State<EditCustomerPageWeb> createState() => _EditCustomerPageWebState();
}

class _EditCustomerPageWebState extends State<EditCustomerPageWeb> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _registrationFeeController;
  late TextEditingController _registrationFeePaidController;
  late String _selectedStatus;
  late String _selectedRegStatus;
  String _selectedPaymentMode = 'Cash';
  late String _selectedRegPaymentMode;
  late TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.customer.name);
    _phoneController = TextEditingController(
      text: widget.customer.mobileNumber,
    );
    _registrationFeeController = TextEditingController(
      text: widget.customer.registrationFeeAmount.toStringAsFixed(0),
    );
    _registrationFeePaidController = TextEditingController(
      text: widget.customer.registrationFeePaidAmount.toStringAsFixed(0),
    );
    _selectedStatus = widget.customer.status;
    _selectedRegStatus = widget.customer.registrationFeeStatus;
    _selectedRegPaymentMode = widget.customer.registrationFeePaymentMode;
    _notesController = TextEditingController(text: widget.customer.notes);

    // Auto-calculate status when numbers change
    _registrationFeeController.addListener(_updateRegStatus);
    _registrationFeePaidController.addListener(_updateRegStatus);
  }

  void _updateRegStatus() {
    final total =
        double.tryParse(_registrationFeeController.text.trim()) ?? 0.0;
    final paid =
        double.tryParse(_registrationFeePaidController.text.trim()) ?? 0.0;

    String newStatus;
    if (total <= 0) {
      newStatus = 'paid';
    } else if (paid >= total) {
      newStatus = 'paid';
    } else if (paid > 0) {
      newStatus = 'partial';
    } else {
      newStatus = 'unpaid';
    }

    if (newStatus != _selectedRegStatus) {
      setState(() {
        _selectedRegStatus = newStatus;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _registrationFeeController.dispose();
    _registrationFeePaidController.dispose();
    _notesController.dispose();
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Confirm Changes',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
              style: TextStyle(color: AppColors.textLight, fontSize: 14),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              FocusManager.instance.primaryFocus?.unfocus();
              Navigator.pop(context);
              final regAmount =
                  double.tryParse(_registrationFeeController.text.trim()) ??
                  0.0;
              final regPaid =
                  double.tryParse(_registrationFeePaidController.text.trim()) ??
                  0.0;

              final updated = widget.customer.copyWith(
                name: _nameController.text.trim(),
                mobileNumber: _phoneController.text.trim(),
                status: _selectedStatus,
                registrationFeeAmount: regAmount,
                registrationFeePaidAmount: regPaid,
                registrationFeeStatus: _selectedRegStatus,
                registrationFeePaymentMode: _selectedRegPaymentMode,
                notes: _notesController.text.trim(),
                updatedAt: DateTime.now(),
              );

              // Find if there's an active subscription to log against
              final subs =
                  context.read<DashboardBloc>().state is DashboardLoaded
                  ? (context.read<DashboardBloc>().state as DashboardLoaded)
                        .activeSubs
                        .where(
                          (s) => s.customerId == widget.customer.customerId,
                        )
                        .toList()
                  : <SubscriptionEntity>[];

              if (subs.isNotEmpty) {
                // If there's an active subscription, use UpdateSubscription to sync everything
                final sub = subs.first;
                final authState = context.read<AuthBloc>().state;
                context.read<CustomerBloc>().add(
                  UpdateSubscription(
                    subscriptionId: sub.subscriptionId,
                    endDate: sub.endDate,
                    price: sub.price,
                    registrationFeeAmount: regAmount,
                    registrationFeePaid: regPaid,
                    paidAmount: sub.paidAmount,
                    paymentMode: sub.paymentMode,
                    updatedById: authState is AuthAuthenticated
                        ? authState.userId
                        : widget.customer.updatedById,
                    ownerId: widget.customer.ownerId,
                    shopId: widget.customer.shopId,
                    updatedByName:
                        authState is AuthAuthenticated &&
                            authState.name.isNotEmpty
                        ? authState.name
                        : 'Admin',
                    customerName: updated.name,
                    shopCategory: widget.shopCategory,
                    status: sub.status,
                    customer: updated,
                    // Pass the fully updated entity
                  ),
                );
              } else {
                // Standard update
                final authState = context.read<AuthBloc>().state;
                final updatedByName =
                    authState is AuthAuthenticated && authState.name.isNotEmpty
                    ? authState.name
                    : 'Admin';
                context.read<CustomerBloc>().add(
                  UpdateCustomerInfo(
                    customer: updated,
                    paymentMode: _selectedPaymentMode,
                    updatedByName: updatedByName,
                    updatedById: authState is AuthAuthenticated
                        ? authState.userId
                        : widget.customer.updatedById,
                    ownerId: widget.customer.ownerId,
                    shopId: widget.customer.shopId,
                    customerName: updated.name,
                    shopCategory: widget.shopCategory,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Confirm',
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final term = TerminologyHelper.getTerminology(widget.shopCategory);

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      body: Row(
        children: [
          const WebSidebar(selectedIndex: 2),
          Expanded(
            child: BlocConsumer<CustomerBloc, CustomerState>(
              listener: (context, state) {
                if (state is CustomerLoading) {
                  LoadingOverlayHelper.show(context);
                } else if (state is CustomerSuccess) {
                  LoadingOverlayHelper.hide();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '${term.customerLabel} updated successfully!',
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
                          borderRadius: BorderRadius.circular(16),
                        ),
                        title: const Text(
                          'Number Already Used',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        content: Text(
                          state.message,
                          style: const TextStyle(fontSize: 14),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text(
                              'OK',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(state.message),
                        backgroundColor: Colors.red,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                }
              },
              builder: (context, state) {
                return Column(
                  children: [
                    _buildHeader(term),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                          vertical: 32,
                          horizontal: 40,
                        ),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: 800.w),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildLabel('${term.customerLabel} Name *'),
                                  TextFormField(
                                    controller: _nameController,
                                    textCapitalization:
                                        TextCapitalization.words,
                                    maxLength: 20,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(
                                        RegExp(r'[a-zA-Z0-9\s]'),
                                      ),
                                    ],
                                    decoration: InputDecoration(
                                      hintText:
                                          'Enter ${term.customerLabel.toLowerCase()} name',
                                      prefixIcon: const Icon(
                                        Icons.person_outline,
                                      ),
                                      counterText: '',
                                    ),
                                    validator: (v) {
                                      if (v == null || v.trim().isEmpty) {
                                        return 'Name is required';
                                      }
                                      if (v.length > 20)
                                        return 'Maximum 20 characters';
                                      if (RegExp(
                                        r'[!@#<>?":_`~;[\]\\|=+)(*&^%/-]',
                                      ).hasMatch(v)) {
                                        return 'Special characters not allowed';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 20),

                                  _buildLabel('Phone Number *'),
                                  TextFormField(
                                    controller: _phoneController,
                                    keyboardType: TextInputType.number,
                                    maxLength: 10,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                    ],
                                    decoration: const InputDecoration(
                                      hintText: 'Enter 10-digit phone number',
                                      prefixIcon: Icon(Icons.phone_outlined),
                                      counterText: '',
                                    ),
                                    validator: (v) {
                                      if (v == null || v.isEmpty) {
                                        return 'Phone is required';
                                      }
                                      if (v.length != 10) {
                                        return 'Must be exactly 10 digits';
                                      }
                                      if (!RegExp(r'^[0-9]+$').hasMatch(v)) {
                                        return 'Numbers only';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 20),

                                  _buildLabel('Customer Notes'),
                                  TextFormField(
                                    controller: _notesController,
                                    maxLines: 3,
                                    decoration: const InputDecoration(
                                      hintText:
                                          'Enter any additional notes about the customer',
                                    ),
                                  ),
                                  const SizedBox(height: 20),

                                  // Customer Status
                                  _buildLabel('Account Status'),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _statusButton(
                                          label: 'Active',
                                          isActive:
                                              _selectedStatus.toLowerCase() ==
                                              'active',
                                          onPressed: () => setState(
                                            () => _selectedStatus = 'active',
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: _statusButton(
                                          label: 'Inactive',
                                          isActive:
                                              _selectedStatus.toLowerCase() ==
                                              'inactive',
                                          onPressed: () => setState(
                                            () => _selectedStatus = 'inactive',
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),

                                  // Registration Fee
                                  if (widget.registrationFeeEnabled) ...[
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              _buildLabel('Total Reg Fee'),
                                              TextFormField(
                                                controller:
                                                    _registrationFeeController,
                                                keyboardType:
                                                    const TextInputType.numberWithOptions(
                                                      decimal: true,
                                                    ),
                                                inputFormatters: [
                                                  FilteringTextInputFormatter.allow(
                                                    RegExp(r'^\d*\.?\d*'),
                                                  ),
                                                ],
                                                decoration:
                                                    const InputDecoration(
                                                      hintText: 'Total',
                                                      prefixIcon: Icon(
                                                        Icons.currency_rupee,
                                                      ),
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              _buildLabel('Amount Paid'),
                                              TextFormField(
                                                controller:
                                                    _registrationFeePaidController,
                                                keyboardType:
                                                    const TextInputType.numberWithOptions(
                                                      decimal: true,
                                                    ),
                                                inputFormatters: [
                                                  FilteringTextInputFormatter.allow(
                                                    RegExp(r'^\d*\.?\d*'),
                                                  ),
                                                ],
                                                decoration:
                                                    const InputDecoration(
                                                      hintText: 'Paid',
                                                      prefixIcon: Icon(
                                                        Icons.currency_rupee,
                                                      ),
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 20),
                                    _buildLabel('Payment Mode'),
                                    DropdownButtonFormField<String>(
                                      value: _selectedRegPaymentMode,
                                      decoration: const InputDecoration(
                                        prefixIcon: Icon(
                                          Icons.payment_outlined,
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
                                              child: Text(m),
                                            );
                                          }).toList(),
                                      onChanged: (v) {
                                        if (v != null) {
                                          setState(
                                            () => _selectedRegPaymentMode = v,
                                          );
                                        }
                                      },
                                    ),
                                    const SizedBox(height: 32),
                                  ],
                                  SizedBox(
                                    width: double.infinity,
                                    height: 52,
                                    child: ElevatedButton(
                                      onPressed: _submit,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primary,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                      child: const Text(
                                        'Save Changes',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BusinessTerminology term) {
    return Container(
      height: 120,
      padding: const EdgeInsets.symmetric(horizontal: 40),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(
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
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Edit ${term.customerLabel}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                'Update ${term.customerLabel.toLowerCase()} details',
                style: TextStyle(fontSize: 12, color: Colors.white70),
              ),
            ],
          ),
        ],
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
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isActive
              ? (label == 'Active'
                    ? AppColors.success.withOpacity(0.1)
                    : Colors.red.withOpacity(0.1))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
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
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: AppColors.textDark,
          fontSize: 14,
        ),
      ),
    );
  }
}
