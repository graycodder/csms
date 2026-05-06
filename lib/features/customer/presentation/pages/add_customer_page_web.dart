import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:csms/core/widgets/web_sidebar.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:csms/core/theme/app_colors.dart';
import 'package:csms/core/utils/loading_overlay.dart';
import 'package:csms/features/customer/presentation/bloc/customer_bloc.dart';
import 'package:csms/features/customer/domain/entities/customer_entity.dart';
import 'package:csms/features/product/domain/entities/product_entity.dart';
import 'package:csms/features/shop/presentation/bloc/shop_context_bloc.dart';
import 'package:csms/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:csms/features/auth/presentation/bloc/auth_state.dart';
import 'package:csms/core/utils/terminology_helper.dart';

class AddCustomerPageWeb extends StatefulWidget {
  final List<ProductEntity> products;
  final String shopCategory;
  final BusinessTerminology term;

  const AddCustomerPageWeb({
    super.key,
    required this.products,
    required this.shopCategory,
    required this.term,
  });

  @override
  State<AddCustomerPageWeb> createState() => _AddCustomerPageWebState();
}

class _AddCustomerPageWebState extends State<AddCustomerPageWeb> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _priceController = TextEditingController();
  final _registrationFeeController = TextEditingController();
  final _validityController = TextEditingController();
  final _paidAmountController = TextEditingController();
  final _notesController = TextEditingController();
  final _subNotesController = TextEditingController();

  ProductEntity? _selectedProduct;
  DateTime _startDate = DateTime.now();
  late String _customValidityUnit;
  String _selectedRegPaymentMode = 'Cash';

  @override
  void initState() {
    super.initState();
    _customValidityUnit = 'months';
    final activeProducts = widget.products
        .where((p) => p.status.toLowerCase() == 'active')
        .toList();
    if (activeProducts.isNotEmpty) {
      _selectedProduct = activeProducts.first;
      _updateControllers(_selectedProduct!);
    }
  }

  void _updateControllers(ProductEntity p) {
    setState(() {
      _priceController.text = p.price.toStringAsFixed(0);
      _validityController.text = p.validityValue.toString();
      _customValidityUnit = p.validityUnit;
      _paidAmountController.text = _computedAmount.toStringAsFixed(0);
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _priceController.dispose();
    _registrationFeeController.dispose();
    _validityController.dispose();
    _paidAmountController.dispose();
    _notesController.dispose();
    _subNotesController.dispose();
    super.dispose();
  }

  double get _computedAmount {
    double baseAmt = 0.0;
    if (_selectedProduct != null) {
      if (_selectedProduct!.priceType == 'flexible') {
        baseAmt = double.tryParse(_priceController.text.trim()) ?? 0.0;
      } else {
        baseAmt = _selectedProduct!.price;
      }
    }

    final shopState = context.read<ShopContextBloc>().state;
    if (shopState is ShopSelected &&
        shopState.selectedShop.settings.registrationFeeEnabled) {
      baseAmt += double.tryParse(_registrationFeeController.text.trim()) ?? 0.0;
    }

    return baseAmt;
  }

  DateTime get _computedExpiryDate {
    if (_selectedProduct == null) return DateTime.now();
    final val = _selectedProduct!.validityType == 'flexible'
        ? (int.tryParse(_validityController.text.trim()) ?? 0)
        : _selectedProduct!.validityValue;

    final unit = _selectedProduct!.validityType == 'flexible'
        ? _customValidityUnit
        : _selectedProduct!.validityUnit;

    return _calculateNewExpiryDate(_startDate, val, unit);
  }

  DateTime _calculateNewExpiryDate(DateTime start, int value, String unit) {
    if (unit.toLowerCase().contains('month')) {
      final destMonth = (start.month + value - 1) % 12 + 1;
      final destYear = start.year + (start.month + value - 1) ~/ 12;
      final tmp = DateTime(
        destYear,
        destMonth,
        start.day,
        start.hour,
        start.minute,
        start.second,
      );
      if (tmp.month != destMonth) {
        return DateTime(
          destYear,
          destMonth + 1,
          0,
          start.hour,
          start.minute,
          start.second,
        );
      }
      return tmp;
    } else {
      return start.add(Duration(days: value));
    }
  }

  String _fmt(DateTime d) => DateFormat('MMM dd, yyyy').format(d);

  @override
  Widget build(BuildContext context) {
    final shopState = context.watch<ShopContextBloc>().state;
    // ignore: unused_local_variable
    String shopName = 'Shop Name';
    bool regFeeEnabled = false;
    if (shopState is ShopSelected) {
      shopName = shopState.selectedShop.shopName;
      regFeeEnabled = shopState.selectedShop.settings.registrationFeeEnabled;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      body: BlocConsumer<CustomerBloc, CustomerState>(
        listener: (context, state) {
          if (state is CustomerLoading) {
            LoadingOverlayHelper.show(context);
          } else if (state is CustomerSuccess) {
            LoadingOverlayHelper.hide();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Customer added successfully!'),
                backgroundColor: AppColors.success,
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
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  content: Text(state.message),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text(
                        'OK',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error: ${state.message}'),
                  backgroundColor: AppColors.errorText,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          }
        },
        builder: (context, state) {
          return Row(
            children: [
              const WebSidebar(selectedIndex: 2),
              Expanded(
                child: Column(
                  children: [
                    _buildHeader(context),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                          vertical: 32,
                          horizontal: 40,
                        ),
                        child: Center(
                          child: Container(
                            constraints: BoxConstraints(maxWidth: 800.w),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            _buildFieldLabel(
                                              '${widget.term.customerLabel} Name *',
                                            ),
                                            _buildTextField(
                                              controller: _nameController,
                                              hint: 'Enter name',
                                              icon: Icons.person_outline,
                                              maxLength: 20,
                                              inputFormatters: [
                                                FilteringTextInputFormatter.allow(
                                                  RegExp(r'[a-zA-Z0-9\s]'),
                                                ),
                                              ],
                                              validator: (v) {
                                                if (v == null ||
                                                    v.trim().isEmpty) {
                                                  return 'Name is required';
                                                }
                                                if (v.length > 20) {
                                                  return 'Maximum 20 characters';
                                                }
                                                if (RegExp(
                                                  r'[!@#<>?":_`~;[\]\\|=+)(*&^%/-]',
                                                ).hasMatch(v)) {
                                                  return 'Special characters not allowed';
                                                }
                                                return null;
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 24),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            _buildFieldLabel('Phone Number *'),
                                            _buildTextField(
                                              controller: _phoneController,
                                              hint: 'Enter 10-digit number',
                                              icon: Icons.phone_outlined,
                                              keyboardType: TextInputType.phone,
                                              maxLength: 10,
                                              validator: (v) {
                                                if (v == null || v.isEmpty) {
                                                  return 'Phone is required';
                                                }
                                                if (v.length != 10) {
                                                  return 'Must be exactly 10 digits';
                                                }
                                                if (!RegExp(
                                                  r'^[0-9]+$',
                                                ).hasMatch(v)) {
                                                  return 'Numbers only';
                                                }
                                                return null;
                                              },
                                              inputFormatters: [
                                                FilteringTextInputFormatter
                                                    .digitsOnly,
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 24),

                                  _buildFieldLabel('Product *'),
                                  _buildDropdownField<ProductEntity>(
                                    value: _selectedProduct,
                                    icon: Icons.inventory_2_outlined,
                                    items: widget.products
                                        .where(
                                          (p) =>
                                              p.status.toLowerCase() ==
                                              'active',
                                        )
                                        .map(
                                          (p) => DropdownMenuItem(
                                            value: p,
                                            child: Text(p.name),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (p) {
                                      if (p != null) {
                                        setState(() {
                                          _selectedProduct = p;
                                          _updateControllers(p);
                                        });
                                      }
                                    },
                                    validator: (v) => v == null
                                        ? 'Please select a product'
                                        : null,
                                  ),
                                  const SizedBox(height: 24),

                                  if (_selectedProduct?.priceType ==
                                      'flexible') ...[
                                    _buildFieldLabel('Price *'),
                                    _buildTextField(
                                      controller: _priceController,
                                      hint: 'Enter price',
                                      icon: Icons.currency_rupee,
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                        FilteringTextInputFormatter.deny(
                                          RegExp(r'^0'),
                                        ),
                                      ],
                                      onChanged: (_) => setState(() {
                                        _paidAmountController.text =
                                            _computedAmount.toStringAsFixed(0);
                                      }),
                                      validator: (v) {
                                        if (v == null || v.trim().isEmpty) {
                                          return 'Price is required';
                                        }
                                        final p =
                                            double.tryParse(v.trim()) ?? 0;
                                        if (p <= 0) {
                                          return 'Price must be greater than 0';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 24),
                                  ],

                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _buildFieldLabel('Plan Validity *'),
                                      if (_selectedProduct?.validityType ==
                                          'flexible')
                                        Row(
                                          children: [
                                            Expanded(
                                              flex: 2,
                                              child: _buildTextField(
                                                controller: _validityController,
                                                hint: 'Value',
                                                icon: Icons.timer_outlined,
                                                keyboardType:
                                                    TextInputType.number,
                                                inputFormatters: [
                                                  FilteringTextInputFormatter
                                                      .digitsOnly,
                                                  FilteringTextInputFormatter.deny(
                                                    RegExp(r'^0'),
                                                  ),
                                                ],
                                                onChanged: (_) =>
                                                    setState(() {}),
                                                validator: (v) {
                                                  if (v == null ||
                                                      v.trim().isEmpty) {
                                                    return 'Required';
                                                  }
                                                  final val =
                                                      int.tryParse(v.trim()) ??
                                                      0;
                                                  if (val <= 0) {
                                                    return 'Must be > 0';
                                                  }
                                                  return null;
                                                },
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              flex: 3,
                                              child: _buildDropdownField<String>(
                                                value: _customValidityUnit,
                                                icon: Icons.unfold_more,
                                                items: const [
                                                  DropdownMenuItem(
                                                    value: 'days',
                                                    child: Text('Days'),
                                                  ),
                                                  DropdownMenuItem(
                                                    value: 'months',
                                                    child: Text('Months'),
                                                  ),
                                                ],
                                                onChanged: (v) {
                                                  if (v != null) {
                                                    setState(
                                                      () =>
                                                          _customValidityUnit =
                                                              v,
                                                    );
                                                  }
                                                },
                                              ),
                                            ),
                                          ],
                                        )
                                      else
                                        Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 16,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            border: Border.all(
                                              color: const Color(0xFFE5E7EB),
                                            ),
                                          ),
                                          child: Text(
                                            _selectedProduct != null
                                                ? '${_selectedProduct!.validityValue} ${_selectedProduct!.validityUnit}'
                                                : 'Select product',
                                            style: const TextStyle(
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 24),
                                  if (regFeeEnabled) ...[
                                    _buildFieldLabel('Registration Fee *'),
                                    _buildTextField(
                                      controller: _registrationFeeController,
                                      hint: '0',
                                      icon: Icons.currency_rupee,
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.allow(
                                          RegExp(r'^\d*\.?\d*'),
                                        ),
                                      ],
                                      onChanged: (_) => setState(() {
                                        _paidAmountController.text =
                                            _computedAmount.toStringAsFixed(0);
                                      }),
                                      validator: (v) {
                                        if (v == null || v.trim().isEmpty) {
                                          return 'Registration fee is required';
                                        }
                                        final fee =
                                            double.tryParse(v.trim()) ?? 0;
                                        if (fee <= 0) {
                                          return 'Fee must be greater than 0';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 24),
                                  ],

                                  _buildFieldLabel('Customer Notes'),
                                  _buildTextField(
                                    controller: _notesController,
                                    hint: 'Add notes about the customer...',
                                    icon: Icons.note_add_outlined,
                                    maxLines: 2,
                                  ),
                                  const SizedBox(height: 24),

                                  _buildFieldLabel('Subscription Notes'),
                                  _buildTextField(
                                    controller: _subNotesController,
                                    hint:
                                        'Add notes about this subscription...',
                                    icon: Icons.assignment_outlined,
                                    maxLines: 2,
                                  ),
                                  const SizedBox(height: 32),

                                  _buildSummaryCard(),
                                  const SizedBox(height: 32),

                                  _buildAddButton(),
                                  const SizedBox(height: 40),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
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
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Add ${widget.term.customerLabel}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                'Fill in ${widget.term.customerLabel.toLowerCase()} details',
                style: TextStyle(fontSize: 12, color: Colors.white70),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textDark,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    int? maxLines = 1,
    int? maxLength,
    String? Function(String?)? validator,
    List<TextInputFormatter>? inputFormatters,
    void Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      maxLength: maxLength,
      validator: validator,
      inputFormatters: inputFormatters,
      onChanged: onChanged,
      decoration: InputDecoration(
        counterText: '',
        hintText: hint,
        prefixIcon: Icon(icon, size: 20, color: Colors.grey),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
    );
  }

  Widget _buildDropdownField<T>({
    required T? value,
    required IconData icon,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
    String? Function(T?)? validator,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      items: items,
      onChanged: onChanged,
      validator: validator,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, size: 20, color: Colors.grey),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    double totalAmt = _computedAmount;
    double paidAmt = double.tryParse(_paidAmountController.text) ?? 0;
    double balance = totalAmt - paidAmt;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F7FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD1E5FF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Summary',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          _summaryRow('Expiry Date:', _fmt(_computedExpiryDate)),
          const SizedBox(height: 12),
          _summaryRow('Total Price:', '₹${totalAmt.toStringAsFixed(0)}'),
          const Divider(height: 24),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('Payment Mode *'),
                    _buildDropdownField<String>(
                      value: _selectedRegPaymentMode,
                      icon: Icons.payments_outlined,
                      items: ['Cash', 'UPI', 'Card', 'Bank Transfer']
                          .map(
                            (m) => DropdownMenuItem(value: m, child: Text(m)),
                          )
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _selectedRegPaymentMode = v ?? 'Cash'),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('Amount Paid *'),
                    _buildTextField(
                      controller: _paidAmountController,
                      hint: '0',
                      icon: Icons.currency_rupee,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: (_) => setState(() {}),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Required';
                        }
                        final paid = double.tryParse(v.trim()) ?? 0;
                        if (paid <= 0) {
                          return 'Must be > 0';
                        }
                        if (paid > _computedAmount) {
                          return 'Cannot exceed ₹${_computedAmount.toStringAsFixed(0)}';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (balance > 0) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Pending Balance:',
                  style: TextStyle(
                    color: Colors.red[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '₹${balance.toStringAsFixed(0)}',
                  style: TextStyle(
                    color: Colors.red[700],
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF6B7280))),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildAddButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(vertical: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: Text(
          'Add ${widget.term.customerLabel}',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  void _submit() {
    if (_formKey.currentState!.validate() && _selectedProduct != null) {
      _showConfirmDialog();
    }
  }

  void _showConfirmDialog() {
    final pageContext = context;
    showDialog(
      context: pageContext,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Confirm Addition'),
        content: Text(
          'Are you sure you want to add "${_nameController.text.trim()}" as a new ${widget.term.customerLabel.toLowerCase()} with the selected ${widget.term.planLabel.toLowerCase()}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textLight),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              final shopState = pageContext.read<ShopContextBloc>().state;
              final authState = pageContext.read<AuthBloc>().state;

              if (shopState is ShopSelected && authState is AuthAuthenticated) {
                final regAmount =
                    double.tryParse(_registrationFeeController.text.trim()) ??
                    0.0;
                final paidAmt =
                    double.tryParse(_paidAmountController.text.trim()) ?? 0.0;

                pageContext.read<CustomerBloc>().add(
                  AddCustomerWithSubscription(
                    customer: CustomerEntity(
                      customerId: '',
                      shopId: shopState.selectedShop.shopId,
                      name: _nameController.text.trim(),
                      mobileNumber: _phoneController.text.trim(),
                      email: '',
                      assignedProductIds: {},
                      createdAt: DateTime.now(),
                      updatedAt: DateTime.now(),
                      updatedById: authState.userId,
                      ownerId: authState.ownerId,
                      registrationFeeAmount: regAmount,
                      registrationFeePaidAmount: 0.0,
                      registrationFeeStatus: 'unpaid',
                      registrationFeePaymentMode: _selectedRegPaymentMode,
                      notes: _notesController.text.trim(),
                    ),
                    productId: _selectedProduct!.productId,
                    validityValue: _selectedProduct!.validityType == 'flexible'
                        ? (int.tryParse(_validityController.text.trim()) ?? 0)
                        : _selectedProduct!.validityValue,
                    validityUnit: _selectedProduct!.validityType == 'flexible'
                        ? _customValidityUnit
                        : _selectedProduct!.validityUnit,
                    price: _selectedProduct!.priceType == 'flexible'
                        ? (double.tryParse(_priceController.text.trim()) ?? 0.0)
                        : _selectedProduct!.price,
                    registrationFeeAmount: regAmount,
                    paidAmount: paidAmt,
                    paymentMode: _selectedRegPaymentMode,
                    productName: _selectedProduct!.name,
                    updatedByName: authState.name,
                    shopCategory: widget.shopCategory,
                    notes: _subNotesController.text.trim().isEmpty
                        ? null
                        : _subNotesController.text.trim(),
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
            child: const Text('Confirm', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
