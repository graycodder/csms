import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:csms/core/theme/app_colors.dart';
import 'package:csms/features/product/domain/entities/product_entity.dart';
import 'package:csms/features/product/presentation/bloc/product_bloc.dart';

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
        title: const Text(
          'Edit Product',
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
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
                decoration: InputDecoration(
                  hintText: 'Product name',
                  counterText: '',
                ),
              ),
              const SizedBox(height: 24),
              
              _buildLabel('Price Type'),
              Row(
                children: [
                  _priceTypeChip('fixed', 'Fixed'),
                  const SizedBox(width: 12),
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
                  decoration: const InputDecoration(
                    hintText: 'Enter price',
                  ),
                ),
                const SizedBox(height: 24),
              ],
              
              _buildLabel('Validity Type'),
              Row(
                children: [
                  _validityTypeChip('fixed', 'Fixed'),
                  const SizedBox(width: 12),
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
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 1,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
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
                                  style: const TextStyle(fontSize: 14),
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
                const SizedBox(height: 40),
              ],
              
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text(
                    'Save Changes',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submitForm() {
    if (_formKey.currentState?.validate() ?? false) {
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
      
      Navigator.pop(context);
    }
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
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.white,
            borderRadius: BorderRadius.circular(12),
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
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.white,
            borderRadius: BorderRadius.circular(12),
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
            ),
          ),
        ),
      ),
    );
  }
}
