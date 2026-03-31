import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import 'package:csms/features/product/domain/entities/product_entity.dart';
import 'package:csms/features/customer/presentation/bloc/customer_bloc.dart';
import 'package:csms/core/utils/loading_overlay.dart';
import 'package:csms/core/utils/terminology_helper.dart';

class AddSubscriptionPage extends StatefulWidget {
  final String customerId;
  final String customerName;
  final String shopId;
  final String ownerId;
  final String updatedById;
  final String updatedByName;
  final List<ProductEntity> products;
  final String shopCategory;
  final List<String> existingProductIds;

  const AddSubscriptionPage({
    super.key,
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
  State<AddSubscriptionPage> createState() => _AddSubscriptionPageState();
}

class _AddSubscriptionPageState extends State<AddSubscriptionPage> {
  ProductEntity? _selectedProduct;
  final List<String> _units = ['days', 'months', 'years'];
  late String _selectedUnit;
  final _validityController = TextEditingController(text: '1');
  final _priceController = TextEditingController();
  final _paidAmountController = TextEditingController();
  String _selectedPaymentMode = 'Cash';

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
    _paidAmountController.text = p.price.toStringAsFixed(0);
    _validityController.text = p.validityValue.toString();
    final unit = p.validityUnit.toLowerCase();
    if (_units.contains(unit)) {
      _selectedUnit = unit;
    } else {
      _selectedUnit = _units[1];
    }
  }

  @override
  void dispose() {
    _validityController.dispose();
    _priceController.dispose();
    _paidAmountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final terminology = TerminologyHelper.getTerminology(widget.shopCategory);
    
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      appBar: AppBar(
        title: Text(
          'Add New ${terminology.planLabel}',
          style: const TextStyle(
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
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${terminology.planLabel} assigned successfully!'),
                  backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          } else if (state is CustomerError) {
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
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      FilteringTextInputFormatter.deny(RegExp(r'^0')),
                    ],
                    decoration: const InputDecoration(
                      hintText: 'Enter price',
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                if (_selectedProduct?.validityType == 'flexible') ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                FilteringTextInputFormatter.deny(RegExp(r'^0')),
                              ],
                              decoration: const InputDecoration(
                                hintText: 'Validity',
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
                            'This ${terminology.planLabel.toLowerCase()} is fixed at ₹${_selectedProduct!.price.toStringAsFixed(0)} for ${_selectedProduct!.validityValue} ${_selectedProduct!.validityUnit}.',
                            style: const TextStyle(color: AppColors.textDark, fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Amount Paid', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _paidAmountController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              hintText: '0',
                              prefixIcon: Icon(Icons.currency_rupee),
                            ),
                            onChanged: (_) => setState(() {}),
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
                          const Text('Payment Mode', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            value: _selectedPaymentMode,
                            items: ['Cash', 'UPI', 'Card', 'Bank Transfer'].map((m) {
                              return DropdownMenuItem(value: m, child: Text(m));
                            }).toList(),
                            onChanged: (v) => setState(() => _selectedPaymentMode = v ?? 'Cash'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if ((double.tryParse(_priceController.text) ?? 0) - (double.tryParse(_paidAmountController.text) ?? 0) > 0) ...[
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Pending Balance:', style: TextStyle(color: Colors.red.shade700, fontSize: 14, fontWeight: FontWeight.w600)),
                      Text('₹${((double.tryParse(_priceController.text) ?? 0) - (double.tryParse(_paidAmountController.text) ?? 0)).toStringAsFixed(0)}', style: TextStyle(color: Colors.red.shade700, fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
                const SizedBox(height: 40),
                
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _onAddPlanPressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text(
                      'Add ${terminology.planLabel}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
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

  void _onAddPlanPressed() {
    if (_selectedProduct == null) return;
    
    // Check flexible price
    if (_selectedProduct!.priceType == 'flexible') {
      final p = double.tryParse(_priceController.text.trim()) ?? 0;
      if (p <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a price greater than 0')),
        );
        return;
      }
    }
    
    // Check flexible validity
    if (_selectedProduct!.validityType == 'flexible') {
      final v = int.tryParse(_validityController.text.trim()) ?? 0;
      if (v <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a validity greater than 0')),
        );
        return;
      }
    }
    
    FocusManager.instance.primaryFocus?.unfocus();
    _showConfirmDialog();
  }

  void _showConfirmDialog() {
    final terminology = TerminologyHelper.getTerminology(widget.shopCategory);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Confirm New ${terminology.planLabel}'),
        content: Text(
          'Are you sure you want to add the "${_selectedProduct?.name}" ${terminology.planLabel.toLowerCase()} to ${widget.customerName}?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              FocusManager.instance.primaryFocus?.unfocus();
              Navigator.pop(context);
            },
            child: const Text('Cancel', style: TextStyle(color: AppColors.textLight)),
          ),
          ElevatedButton(
            onPressed: () {
              FocusManager.instance.primaryFocus?.unfocus();
              Navigator.pop(context); // Close dialog
              
              final val = int.tryParse(_validityController.text) ?? 1;
              final price = double.tryParse(_priceController.text) ?? (_selectedProduct?.price ?? 0.0);
              final paidAmt = double.tryParse(_paidAmountController.text) ?? price;

              context.read<CustomerBloc>().add(AddSubscription(
                    shopId: widget.shopId,
                    customerId: widget.customerId,
                    productId: _selectedProduct!.productId,
                    ownerId: widget.ownerId,
                    updatedById: widget.updatedById,
                    updatedByName: widget.updatedByName,
                    validityValue: val,
                    validityUnit: _selectedUnit,
                    price: price,
                    paidAmount: paidAmt,
                    paymentMode: _selectedPaymentMode,
                    customerName: widget.customerName,
                    productName: _selectedProduct!.name,
                  ));
              
              // Navigator.pop(context); // REMOVED: Wait for Bloc state
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
