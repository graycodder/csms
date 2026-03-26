import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import 'package:csms/features/product/domain/entities/product_entity.dart';
import 'package:csms/features/customer/presentation/bloc/customer_bloc.dart';
import 'package:csms/core/utils/loading_overlay.dart';
import 'package:csms/core/utils/terminology_helper.dart';

void showAddSubscriptionSheet(
  BuildContext context, {
  required String customerId,
  required String customerName,
  required String shopId,
  required String ownerId,
  required String updatedById,
  required String updatedByName,
  required List<ProductEntity> products,
  required String shopCategory,
  List<String> existingProductIds = const [],
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _AddSubscriptionSheet(
      customerId: customerId,
      customerName: customerName,
      shopId: shopId,
      ownerId: ownerId,
      updatedById: updatedById,
      updatedByName: updatedByName,
      products: products,
      shopCategory: shopCategory,
      existingProductIds: existingProductIds,
    ),
  );
}

class _AddSubscriptionSheet extends StatefulWidget {
  final String customerId;
  final String customerName;
  final String shopId;
  final String ownerId;
  final String updatedById;
  final String updatedByName;
  final List<ProductEntity> products;
  final String shopCategory;
  final List<String> existingProductIds;

  const _AddSubscriptionSheet({
    required this.customerId,
    required this.customerName,
    required this.shopId,
    required this.ownerId,
    required this.updatedById,
    required this.updatedByName,
    required this.products,
    required this.shopCategory,
    this.existingProductIds = const [],
  });

  @override
  State<_AddSubscriptionSheet> createState() => _AddSubscriptionSheetState();
}

class _AddSubscriptionSheetState extends State<_AddSubscriptionSheet> {
  ProductEntity? _selectedProduct;
  final List<String> _units = ['days', 'months', 'years'];
  late String _selectedUnit;
  final _validityController = TextEditingController(text: '1');
  final _priceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedUnit = _units[1]; // months default
    final activeProducts = widget.products.where((p) {
      return p.status == 'active' && !widget.existingProductIds.contains(p.productId);
    }).toList();
    if (activeProducts.isNotEmpty) {
      _selectedProduct = activeProducts.first;
      _updateControllers(_selectedProduct!);
    }
  }

  void _updateControllers(ProductEntity p) {
    _priceController.text = p.price.toStringAsFixed(0);
    _validityController.text = p.validityValue.toString();
    final unit = p.validityUnit.toLowerCase();
    if (_units.contains(unit)) {
      _selectedUnit = unit;
    } else {
      _selectedUnit = _units[1];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 32,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Add New ${TerminologyHelper.getTerminology(widget.shopCategory).planLabel}',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Assign a new product to ${widget.customerName}',
              style: const TextStyle(color: AppColors.textLight, fontSize: 15),
            ),
            const SizedBox(height: 32),
            
            const Text('Select Product', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 12),
            DropdownButtonFormField<ProductEntity>(
              value: _selectedProduct,
              hint: const Text('Select a product'),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.inventory_2_outlined),
              ),
              items: widget.products.where((p) {
                return p.status == 'active' && !widget.existingProductIds.contains(p.productId);
              }).map((p) {
                return DropdownMenuItem(
                  value: p,
                  child: Text(p.name),
                );
              }).toList(),
              onChanged: (v) {
                if (v != null) {
                  setState(() {
                    _selectedProduct = v;
                    _updateControllers(v);
                  });
                }
              },
            ),
            const SizedBox(height: 24),

            if (_selectedProduct?.priceType == 'flexible') ...[
              const Text('Price', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 12),
              TextField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.attach_money),
                  hintText: 'Enter price',
                ),
              ),
              const SizedBox(height: 24),
            ],

            if (_selectedProduct?.validityType == 'flexible') ...[
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Validity', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _validityController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.timer_outlined),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Unit', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: _selectedUnit,
                          items: _units.map((u) => DropdownMenuItem(
                            value: u, 
                            child: Text(u[0].toUpperCase() + u.substring(1))
                          )).toList(),
                          onChanged: (v) => setState(() => _selectedUnit = v!),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ] else if (_selectedProduct != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: AppColors.primary, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'This ${TerminologyHelper.getTerminology(widget.shopCategory).planLabel.toLowerCase()} is fixed at ₹${_selectedProduct!.price.toStringAsFixed(0)} for ${_selectedProduct!.validityValue} ${_selectedProduct!.validityUnit}.',
                        style: const TextStyle(color: AppColors.textDark, fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 40),
            
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  if (_selectedProduct == null) return;
                  _showConfirmDialog();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(
                  'Add ${TerminologyHelper.getTerminology(widget.shopCategory).planLabel}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showConfirmDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Confirm New ${TerminologyHelper.getTerminology(widget.shopCategory).planLabel}'),
        content: Text(
          'Are you sure you want to add the "${_selectedProduct?.name}" ${TerminologyHelper.getTerminology(widget.shopCategory).planLabel.toLowerCase()} to ${widget.customerName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textLight)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close bottom sheet
              
              final val = int.tryParse(_validityController.text) ?? 1;
              context.read<CustomerBloc>().add(AddSubscription(
                    shopId: widget.shopId,
                    customerId: widget.customerId,
                    productId: _selectedProduct!.productId,
                    ownerId: widget.ownerId,
                    updatedById: widget.updatedById,
                    updatedByName: widget.updatedByName,
                    validityValue: val,
                    validityUnit: _selectedUnit,
                    price: double.tryParse(_priceController.text) ??
                        (_selectedProduct?.price ?? 0.0),
                    customerName: widget.customerName,
                    productName: _selectedProduct!.name,
                  ));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Confirm', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
