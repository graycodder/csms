import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:csms/core/theme/app_colors.dart';
import 'package:csms/features/customer/presentation/bloc/customer_bloc.dart';
import 'package:csms/features/customer/domain/entities/customer_entity.dart';
import 'package:csms/features/product/domain/entities/product_entity.dart';
import 'package:csms/features/shop/presentation/bloc/shop_context_bloc.dart';
import 'package:csms/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:csms/features/auth/presentation/bloc/auth_state.dart';
import 'package:csms/core/utils/loading_overlay.dart';
import 'package:csms/core/utils/terminology_helper.dart';

class AddCustomerPage extends StatefulWidget {
  final List<ProductEntity> products;
  final String shopCategory;
  const AddCustomerPage({super.key, required this.products, required this.shopCategory});

  @override
  State<AddCustomerPage> createState() => _AddCustomerPageState();
}

class _AddCustomerPageState extends State<AddCustomerPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _priceController = TextEditingController();
  final _validityController = TextEditingController();
  late String _customValidityUnit;

  ProductEntity? _selectedProduct;

  @override
  void initState() {
    super.initState();
    // Ensure we only work with active products
    final activeProducts = widget.products
        .where((p) => p.status.toLowerCase() == 'active')
        .toList();
    if (activeProducts.isNotEmpty) {
      _selectedProduct = activeProducts.first;
      _updateControllers(_selectedProduct!);
    }
  }

  void _updateControllers(ProductEntity p) {
    _priceController.text = p.price.toStringAsFixed(0);
    _validityController.text = p.validityValue.toString();
    _customValidityUnit = p.validityUnit;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _priceController.dispose();
    _validityController.dispose();
    super.dispose();
  }

  double get _computedAmount {
    if (_selectedProduct == null) return 0.0;
    if (_selectedProduct!.priceType == 'flexible') {
      return double.tryParse(_priceController.text.trim()) ?? 0.0;
    }
    return _selectedProduct!.price;
  }

  DateTime get _computedExpiryDate {
    if (_selectedProduct == null) return DateTime.now();
    final now = DateTime.now();
    final val = _selectedProduct!.validityType == 'flexible'
        ? (int.tryParse(_validityController.text.trim()) ?? 0)
        : _selectedProduct!.validityValue;
    
    final unit = _selectedProduct!.validityType == 'flexible'
        ? _customValidityUnit
        : _selectedProduct!.validityUnit;
        
    return _calculateNewExpiryDate(now, val, unit);
  }

  DateTime _calculateNewExpiryDate(DateTime start, int value, String unit) {
    if (unit.toLowerCase().contains('month')) {
      final destMonth = (start.month + value - 1) % 12 + 1;
      final destYear = start.year + (start.month + value - 1) ~/ 12;
      final tmp = DateTime(destYear, destMonth, start.day, start.hour, start.minute, start.second);
      if (tmp.month != destMonth) {
        return DateTime(destYear, destMonth + 1, 0, start.hour, start.minute, start.second);
      }
      return tmp;
    } else {
      return start.add(Duration(days: value));
    }
  }

  String _fmt(DateTime d) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  void _submit() {
    if (_formKey.currentState!.validate() && _selectedProduct != null) {
      _showConfirmDialog();
    }
  }

  void _showConfirmDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: Text('Confirm Addition'),
        content: Text(
          'Are you sure you want to add "${_nameController.text.trim()}" as a new ${TerminologyHelper.getTerminology(widget.shopCategory).customerLabel.toLowerCase()} with the selected ${TerminologyHelper.getTerminology(widget.shopCategory).planLabel.toLowerCase()}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: AppColors.textLight, fontSize: 14.sp)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              final shopState = context.read<ShopContextBloc>().state;
              final authState = context.read<AuthBloc>().state;
              
              if (shopState is ShopSelected && authState is AuthAuthenticated) {
                final customer = CustomerEntity(
                  customerId: '', // Generated by repo
                  shopId: shopState.selectedShop.shopId,
                  name: _nameController.text.trim(),
                  mobileNumber: _phoneController.text.trim(),
                  email: '', // Optional
                  assignedProductIds: {},
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                  updatedById: authState.userId,
                  ownerId: authState.ownerId,
                );

                context.read<CustomerBloc>().add(AddCustomerWithSubscription(
                  customer: customer,
                  productId: _selectedProduct!.productId,
                  validityValue: _selectedProduct!.validityType == 'flexible'
                      ? (int.tryParse(_validityController.text.trim()) ?? 0)
                      : _selectedProduct!.validityValue,
                  validityUnit: _selectedProduct!.validityType == 'flexible'
                      ? _customValidityUnit
                      : _selectedProduct!.validityUnit,
                  price: _computedAmount,
                  productName: _selectedProduct!.name,
                  updatedByName: authState.name,
                ));

                // Clear form data as requested
                _nameController.clear();
                _phoneController.clear();
                if (_selectedProduct?.priceType == 'flexible') {
                   _priceController.clear();
                }
                if (_selectedProduct?.validityType == 'flexible') {
                   _validityController.clear();
                }
              }
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
        leadingWidth: 48,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add ${TerminologyHelper.getTerminology(widget.shopCategory).customerLabel}',
              style: TextStyle(
                color: AppColors.textDark,
                fontWeight: FontWeight.bold,
                fontSize: 18.sp,
              ),
            ),
            Text(
              'Fill in ${TerminologyHelper.getTerminology(widget.shopCategory).customerLabel.toLowerCase()} details',
              style: TextStyle(
                color: AppColors.textLight.withOpacity(0.8),
                fontSize: 13.sp,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: AppColors.border, height: 1.0),
        ),
      ),
      body: BlocConsumer<CustomerBloc, CustomerState>(
        listener: (context, state) {
          if (state is CustomerLoading) {
            LoadingOverlay.show(context);
          } else if (state is CustomerSuccess) {
            LoadingOverlay.hide();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Customer added successfully!'),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
              ),
            );
            Navigator.pop(context);
          } else if (state is CustomerError) {
            LoadingOverlay.hide();
            if (state.message.contains('already used')) {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                  title: Text('Number Already Used', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
                  content: Text(state.message),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text('OK', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp)),
                    ),
                  ],
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error: ${state.message}'), 
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
                  _buildLabel('${TerminologyHelper.getTerminology(widget.shopCategory).customerLabel} Name *'),
                  TextFormField(
                    controller: _nameController,
                    maxLength: 20,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9\s]')),
                    ],
                    decoration: InputDecoration(
                      hintText: 'Enter ${TerminologyHelper.getTerminology(widget.shopCategory).customerLabel.toLowerCase()} name',
                      prefixIcon: Icon(Icons.person_outline),
                      counterText: '',
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Name is required';
                      if (v.length > 20) return 'Maximum 20 characters';
                      if (RegExp(r'[!@#<>?":_`~;[\]\\|=+)(*&^%/-]').hasMatch(v)) {
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
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    decoration: const InputDecoration(
                      hintText: 'Enter 10-digit phone number',
                      prefixIcon: Icon(Icons.phone_outlined),
                      counterText: '',
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Phone is required';
                      if (v.length != 10) return 'Must be exactly 10 digits';
                      if (!RegExp(r'^[0-9]+$').hasMatch(v)) return 'Numbers only';
                      return null;
                    },
                  ),
                  SizedBox(height: 20.h),

                  _buildLabel('Product *'),
                  DropdownButtonFormField<ProductEntity>(
                    value: _selectedProduct,
                    focusColor: Colors.transparent,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.inventory_2_outlined),
                    ),
                    items: widget.products
                        .where((p) => p.status.toLowerCase() == 'active')
                        .map((p) {
                      return DropdownMenuItem<ProductEntity>(
                        value: p,
                        child: Text(p.name),
                      );
                    }).toList(),
                    onChanged: (ProductEntity? p) {
                      if (p != null) {
                        setState(() {
                          _selectedProduct = p;
                          _updateControllers(p);
                        });
                      }
                    },
                    validator: (v) => v == null ? 'Please select a product' : null,
                  ),
                  SizedBox(height: 20.h),

                  if (_selectedProduct?.priceType == 'flexible') ...[
                    _buildLabel('Price *'),
                    TextFormField(
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        FilteringTextInputFormatter.deny(RegExp(r'^0')),
                      ],
                      decoration: const InputDecoration(
                        hintText: 'Enter price',
                      ),
                      onChanged: (_) => setState(() {}),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Price is required';
                        final p = double.tryParse(v.trim()) ?? 0;
                        if (p <= 0) return 'Price must be greater than 0';
                        return null;
                      },
                    ),
                    SizedBox(height: 20.h),
                  ],

                  // Plan Details
                  _buildLabel('Plan Validity'),
                  if (_selectedProduct?.validityType == 'flexible')
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _validityController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              FilteringTextInputFormatter.deny(RegExp(r'^0')),
                            ],
                            decoration: InputDecoration(
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 15.h),
                              hintText: 'No leading 0',
                            ),
                            onChanged: (_) => setState(() {}),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'Required';
                              final val = int.tryParse(v.trim()) ?? 0;
                              if (val <= 0) return 'Must be > 0';
                              return null;
                            },
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          flex: 3,
                          child: DropdownButtonFormField<String>(
                            value: ['days', 'months'].contains(_customValidityUnit.toLowerCase()) 
                                ? _customValidityUnit.toLowerCase() 
                                : 'days',
                            decoration: InputDecoration(
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 15.h),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'days', child: Text('Days')),
                              DropdownMenuItem(value: 'months', child: Text('Months')),
                            ],
                            onChanged: (v) {
                              if (v != null) {
                                setState(() {
                                  _customValidityUnit = v;
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    )
                  else
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(
                        _selectedProduct != null 
                          ? '${_selectedProduct!.validityValue} ${_selectedProduct!.validityUnit[0].toUpperCase()}${_selectedProduct!.validityUnit.substring(1)}'
                          : 'Select a product',
                        style: TextStyle(
                          color: _selectedProduct != null ? AppColors.textDark : AppColors.textLight,
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  SizedBox(height: 24.h),

                  // Summary Box
                  Container(
                    padding: EdgeInsets.all(20.r),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F7FF),
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(color: AppColors.primary.withOpacity(0.1)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Summary',
                          style: TextStyle(
                            color: AppColors.textDark,
                            fontWeight: FontWeight.w600,
                            fontSize: 15.sp,
                          ),
                        ),
                        SizedBox(height: 12.h),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Expiry Date:', style: TextStyle(color: AppColors.textLight)),
                            Text(
                              _fmt(_computedExpiryDate),
                              style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold, fontSize: 14.sp),
                            ),
                          ],
                        ),
                        SizedBox(height: 8.h),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total Amount:', style: TextStyle(color: AppColors.textLight)),
                            Text(
                              '${_computedAmount.toStringAsFixed(0)}',
                              style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 14.sp),
                            ),
                          ],
                        ),
                      ],
                    ),
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
                        'Add ${TerminologyHelper.getTerminology(widget.shopCategory).customerLabel}',
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

  Widget _buildLabel(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.0.h),
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
