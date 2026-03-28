import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:csms/core/theme/app_colors.dart';
import 'package:csms/features/product/domain/entities/product_entity.dart';
import 'package:csms/features/product/presentation/bloc/product_bloc.dart';
import 'package:csms/core/utils/loading_overlay.dart';

class EditProductPage extends StatefulWidget {
  final ProductEntity product;
  final String ownerId;

  const EditProductPage({
    super.key,
    required this.product,
    required this.ownerId,
  });

  @override
  State<EditProductPage> createState() => _EditProductPageState();
}

class _EditProductPageState extends State<EditProductPage> {
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _validityController;
  late String _validityUnit;
  late String _priceType;
  late String _validityType;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    final sanitizedName = widget.product.name.replaceAll(RegExp(r'[^a-zA-Z\s]'), '');
    _nameController = TextEditingController(text: sanitizedName);
    _priceController = TextEditingController(
      text: widget.product.price.toStringAsFixed(0),
    );
    _validityController = TextEditingController(
      text: widget.product.validityValue.toString(),
    );
    _validityUnit = widget.product.validityUnit;
    _priceType = widget.product.priceType;
    _validityType = widget.product.validityType;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _validityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      appBar: AppBar(
        title: Text(
          'Edit Product',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
            fontSize: 18.sp,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: BlocConsumer<ProductBloc, ProductState>(
        listener: (context, state) {
          if (state is ProductLoading || state is ProductOperationInProgress) {
            LoadingOverlay.show(context);
          } else if (state is ProductLoaded) {
            LoadingOverlay.hide();
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Product updated successfully!'),
                  backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          } else if (state is ProductError) {
            LoadingOverlay.hide();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
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
                  _buildLabel('Product Name *'),
                  TextFormField(
                    controller: _nameController,
                    maxLength: 20,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')),
                    ],
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Required';
                      if (v.trim().length > 20) return 'Max 20 chars';
                      return null;
                    },
                    decoration: const InputDecoration(
                      hintText: 'Product name',
                      counterText: '',
                    ),
                  ),
                  SizedBox(height: 24.h),
                  
                  _buildLabel('Price Type'),
                  Row(
                    children: [
                      _priceTypeChip('fixed', 'Fixed'),
                      SizedBox(width: 12.w),
                      _priceTypeChip('flexible', 'Flexible'),
                    ],
                  ),
                  SizedBox(height: 24.h),
                  
                  if (_priceType == 'fixed') ...[
                    _buildLabel('Price *'),
                    TextFormField(
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        FilteringTextInputFormatter.deny(RegExp(r'^0')),
                      ],
                      validator: (v) {
                        if (_priceType == 'fixed') {
                          if (v == null || v.trim().isEmpty) return 'Required';
                          final price = int.tryParse(v.trim()) ?? 0;
                          if (price <= 0) return 'Price must be > 0';
                          if (price > 100000) return 'Max 100k';
                        }
                        return null;
                      },
                      decoration: const InputDecoration(
                        hintText: 'Enter price',
                      ),
                    ),
                    SizedBox(height: 24.h),
                  ],
                  
                  _buildLabel('Validity Type'),
                  Row(
                    children: [
                      _validityTypeChip('fixed', 'Fixed'),
                      SizedBox(width: 12.w),
                      _validityTypeChip('flexible', 'Flexible'),
                    ],
                  ),
                  SizedBox(height: 24.h),
                  
                  if (_validityType == 'fixed') ...[
                    _buildLabel('Validity Value *'),
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
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'Required';
                              final val = int.tryParse(v.trim()) ?? 0;
                              if (val <= 0) return 'Must be > 0';
                              if (val > 5000) return 'Max 5000';
                              return null;
                            },
                            decoration: const InputDecoration(
                              hintText: 'Validity',
                            ),
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          flex: 1,
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 12.w),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12.r),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _validityUnit,
                                isExpanded: true,
                                items: ['days', 'months'].map((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(
                                      value[0].toUpperCase() + value.substring(1),
                                      style: TextStyle(fontSize: 14.sp),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (String? newValue) {
                                  if (newValue != null) {
                                    setState(() => _validityUnit = newValue);
                                  }
                                },
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 40.h),
                  ],
                  
                  SizedBox(
                    width: double.infinity,
                    height: 56.h,
                    child: ElevatedButton(
                      onPressed: _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                      ),
                      child: Text(
                        'Save Changes',
                        style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: Colors.white),
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

  void _submitForm() {
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
        content: Text('Are you sure you want to save the changes to this product?', style: TextStyle(fontSize: 14.sp)),
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
              Navigator.pop(ctx);
              final name = _nameController.text.trim();
              final price = _priceType == 'fixed' 
                  ? (int.tryParse(_priceController.text.trim()) ?? 0)
                  : 0;
              final valdVal = _validityType == 'fixed'
                  ? (int.tryParse(_validityController.text.trim()) ?? 30)
                  : 0;
              
              final updatedProduct = ProductEntity(
                productId: widget.product.productId,
                shopId: widget.product.shopId,
                name: name,
                price: price.toDouble(),
                validityValue: valdVal,
                validityUnit: _validityUnit,
                validityDays: _validityUnit == 'months' ? valdVal * 30 : valdVal,
                createdAt: widget.product.createdAt,
                updatedAt: DateTime.now(),
                updatedById: widget.ownerId,
                ownerId: widget.product.ownerId,
                priceType: _priceType,
                validityType: _validityType,
                status: widget.product.status,
              );
              
              context.read<ProductBloc>().add(UpdateProduct(
                ownerId: widget.ownerId,
                product: updatedProduct,
              ));
              
              // Navigator.pop(context); // REMOVED: Wait for Bloc state
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

  Widget _validityTypeChip(String type, String label) {
    final isSelected = _validityType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _validityType = type),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12.h),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.white,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : AppColors.textDark,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              fontSize: 14.sp,
            ),
          ),
        ),
      ),
    );
  }

  Widget _priceTypeChip(String type, String label) {
    final isSelected = _priceType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _priceType = type),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12.h),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.white,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : AppColors.textDark,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              fontSize: 14.sp,
            ),
          ),
        ),
      ),
    );
  }
}
