import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:csms/core/theme/app_colors.dart';
import 'package:csms/features/product/domain/entities/product_entity.dart';
import 'package:csms/features/product/presentation/bloc/product_bloc.dart';
import 'package:csms/core/utils/loading_overlay.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class EditProductPageWeb extends StatefulWidget {
  final ProductEntity product;
  final String ownerId;

  const EditProductPageWeb({
    super.key,
    required this.product,
    required this.ownerId,
  });

  @override
  State<EditProductPageWeb> createState() => _EditProductPageWebState();
}

class _EditProductPageWebState extends State<EditProductPageWeb> {
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
    final sanitizedName = widget.product.name.replaceAll(
      RegExp(r'[^a-zA-Z0-9\s]'),
      '',
    );
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
      backgroundColor: const Color(0xFFF0F2F5),
      body: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(context),
                Expanded(
                  child: BlocConsumer<ProductBloc, ProductState>(
                    listener: (context, state) {
                      if (state is ProductLoading ||
                          state is ProductOperationInProgress) {
                        LoadingOverlayHelper.show(context);
                      } else if (state is ProductActionSuccess) {
                        LoadingOverlayHelper.hide();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(state.message),
                            backgroundColor: Colors.green,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        Navigator.pop(context);
                      } else if (state is ProductError) {
                        LoadingOverlayHelper.hide();
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 32,
                        ),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: 800.w),
                            child: _buildFormCard(),
                          ),
                        ),
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

  Widget _buildHeader(BuildContext context) {
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
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Edit Product',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Modify details for this product or service',
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

  Widget _buildFormCard() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLabel('Product Name *'),
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              maxLength: 20,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9\s]')),
              ],
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Required';
                if (v.trim().length > 20) return 'Max 20 chars';
                return null;
              },
              decoration: InputDecoration(
                hintText: 'Product name',
                counterText: '',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
              ),
            ),
            const SizedBox(height: 24),

            _buildLabel('Price Type'),
            Row(
              children: [
                _priceTypeChip('fixed', 'Fixed'),
                const SizedBox(width: 16),
                _priceTypeChip('flexible', 'Flexible'),
              ],
            ),
            const SizedBox(height: 24),

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
                decoration: InputDecoration(
                  hintText: 'Enter price',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            _buildLabel('Validity Type'),
            Row(
              children: [
                _validityTypeChip('fixed', 'Fixed'),
                const SizedBox(width: 16),
                _validityTypeChip('flexible', 'Flexible'),
              ],
            ),
            const SizedBox(height: 24),

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
                      decoration: InputDecoration(
                        hintText: 'Validity',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 1,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
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
                                style: const TextStyle(fontSize: 16),
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
              const SizedBox(height: 48),
            ],

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Save Changes',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Confirm Changes',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        content: const Text(
          'Are you sure you want to save the changes to this product?',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () {
              FocusManager.instance.primaryFocus?.unfocus();
              Navigator.pop(ctx);
            },
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textLight, fontSize: 14),
            ),
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
                validityDays: _validityUnit == 'months'
                    ? valdVal * 30
                    : valdVal,
                createdAt: widget.product.createdAt,
                updatedAt: DateTime.now(),
                updatedById: widget.ownerId,
                ownerId: widget.product.ownerId,
                priceType: _priceType,
                validityType: _validityType,
                status: widget.product.status,
              );

              context.read<ProductBloc>().add(
                UpdateProduct(ownerId: widget.ownerId, product: updatedProduct),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Confirm',
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
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
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.white,
            borderRadius: BorderRadius.circular(8),
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
              fontSize: 14,
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
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.white,
            borderRadius: BorderRadius.circular(8),
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
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}
