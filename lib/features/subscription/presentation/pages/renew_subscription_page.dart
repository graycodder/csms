import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import 'package:csms/features/customer/presentation/bloc/customer_bloc.dart';
import 'package:csms/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:csms/features/auth/presentation/bloc/auth_state.dart';
import 'package:csms/injection_container.dart' as di;
import 'package:csms/core/utils/terminology_helper.dart';
import 'package:csms/core/utils/loading_overlay.dart';

class RenewSubscriptionPage extends StatefulWidget {
  final String subscriptionId;
  final String shopId;
  final String ownerId;
  final DateTime currentEndDate;
  final String productName;
  final String validityUnit;
  final int validityValue;
  final String priceType;
  final String validityType;
  final double basePrice;
  final String shopCategory;
  final String customerName;

  const RenewSubscriptionPage({
    super.key,
    required this.subscriptionId,
    required this.shopId,
    required this.ownerId,
    required this.currentEndDate,
    required this.productName,
    required this.validityUnit,
    required this.validityValue,
    this.priceType = 'fixed',
    this.validityType = 'fixed',
    this.basePrice = 0.0,
    required this.shopCategory,
    required this.customerName,
  });

  @override
  State<RenewSubscriptionPage> createState() => _RenewSubscriptionPageState();
}

class _RenewSubscriptionPageState extends State<RenewSubscriptionPage> {
  int? _selectedValue;
  String? _selectedUnit;
  String? _selectedLabel;
  late TextEditingController _priceController;
  late TextEditingController _validityController;

  @override
  void initState() {
    super.initState();
    _priceController = TextEditingController(text: widget.basePrice.toStringAsFixed(0));
    _validityController = TextEditingController(text: widget.validityValue.toString());
    
    if (widget.validityType == 'fixed') {
      _selectedValue = null;
      _selectedUnit = null;
    } else {
      _selectedValue = widget.validityValue;
      _selectedUnit = widget.validityUnit.toLowerCase();
      _selectedLabel = 'Custom Duration';
    }
  }

  @override
  void dispose() {
    _priceController.dispose();
    _validityController.dispose();
    super.dispose();
  }

  String _fmt(DateTime d) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  void _selectDuration(int value, String unit, String label) {
    setState(() {
      _selectedValue = value;
      _selectedUnit = unit;
      _selectedLabel = label;
      if (label != 'Custom Duration') {
        _validityController.text = value.toString();
      }
    });
  }

  Future<void> _confirm(BuildContext context) async {
    if (_selectedValue == null || _selectedUnit == null) return;

    final newEndDate = _calculateNewEndDate(widget.currentEndDate, _selectedValue!, _selectedUnit!);
    final isActive = widget.currentEndDate.isAfter(DateTime.now());

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Confirm ${TerminologyHelper.getTerminology(widget.shopCategory).renewActionLabel}', style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Duration: $_selectedLabel', style: const TextStyle(fontSize: 15)),
            const SizedBox(height: 8),
            if (isActive) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: AppColors.primary, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Active ${TerminologyHelper.getTerminology(widget.shopCategory).subscriptionLabel.toLowerCase()} found — new period will be queued after current expiry.',
                        style: const TextStyle(color: AppColors.primary, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text('Current expiry: ${_fmt(widget.currentEndDate)}',
                  style: const TextStyle(color: AppColors.textLight, fontSize: 13)),
            ],
            const SizedBox(height: 4),
            Text('New expiry: ${_fmt(newEndDate)}',
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                    fontSize: 14)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textLight)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Confirm', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final authState = context.read<AuthBloc>().state;
      if (authState is AuthAuthenticated) {
          final price = double.tryParse(_priceController.text);
          context.read<CustomerBloc>().add(
            RenewCustomerSubscription(
              subscriptionId: widget.subscriptionId,
              shopId: widget.shopId,
              validityValue: _selectedValue!,
              validityUnit: _selectedUnit!,
              updatedById: authState.userId,
              ownerId: widget.ownerId,
              productName: widget.productName,
              price: price,
              updatedByName: authState.name,
              customerName: widget.customerName,
            ),
          );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isActive = widget.currentEndDate.isAfter(DateTime.now());
    final newEndDate = (_selectedValue != null && _selectedUnit != null)
        ? _calculateNewEndDate(widget.currentEndDate, _selectedValue!, _selectedUnit!)
        : null;

    return BlocListener<CustomerBloc, CustomerState>(
      listener: (context, state) {
        if (state is CustomerLoading) {
          LoadingOverlay.show(context);
        } else if (state is CustomerSuccess) {
          LoadingOverlay.hide();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Membership renewed successfully!'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.pop(context); // Close Renew Page
        } else if (state is CustomerError) {
          LoadingOverlay.hide();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${state.message}'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: AppColors.textDark),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            TerminologyHelper.getTerminology(widget.shopCategory).renewActionLabel,
            style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title & Info
                Text(widget.productName,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                const SizedBox(height: 4),
                Text('Current ${TerminologyHelper.getTerminology(widget.shopCategory).planLabel.toLowerCase()}: ${widget.validityValue} ${widget.validityUnit}',
                    style: TextStyle(fontSize: 16, color: AppColors.textLight.withOpacity(0.7))),
                const SizedBox(height: 24),

                // Queue info banner
                if (isActive) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.queue, size: 16, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Currently active until ${_fmt(widget.currentEndDate)} — new period will be queued.',
                            style: const TextStyle(color: AppColors.primary, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  Text('Expired on ${_fmt(widget.currentEndDate)}',
                      style: const TextStyle(color: Colors.red, fontSize: 13)),
                ],

                const SizedBox(height: 20),
                
                if (widget.priceType == 'flexible') ...[
                  const Text('Custom Price', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _priceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      hintText: 'Enter price',
                    ),
                    onChanged: (v) => setState(() {}),
                  ),
                  const SizedBox(height: 20),
                ],

                if (widget.validityType == 'flexible') ...[
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
                              onChanged: (v) {
                                setState(() {
                                  _selectedValue = int.tryParse(v);
                                  _selectedLabel = 'Custom Duration';
                                });
                              },
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
                              value: (_selectedUnit ?? 'months').toLowerCase(),
                              items: const [
                                DropdownMenuItem(value: 'days', child: Text('Days')),
                                DropdownMenuItem(value: 'months', child: Text('Months')),
                              ],
                              onChanged: (v) {
                                setState(() {
                                  _selectedUnit = v;
                                  _selectedLabel = 'Custom Duration';
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],

                if (widget.validityType != 'flexible') ...[
                  const Text('Quick Select Duration:', style: TextStyle(color: AppColors.textLight, fontSize: 14)),
                  const SizedBox(height: 12),

                  // Duration grid
                  if (widget.validityUnit.toLowerCase().contains('month')) ...[
                    Row(children: [
                      Expanded(child: _durationBtn('1 Month', 1, 'Months')),
                      const SizedBox(width: 12),
                      Expanded(child: _durationBtn('3 Months', 3, 'Months')),
                    ]),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(child: _durationBtn('6 Months', 6, 'Months')),
                      const SizedBox(width: 12),
                      Expanded(child: _durationBtn('12 Months', 12, 'Months')),
                    ]),
                  ] else ...[
                    Row(children: [
                      Expanded(child: _durationBtn('${widget.validityValue} Days', widget.validityValue, 'Days')),
                      const SizedBox(width: 12),
                      Expanded(child: _durationBtn('${widget.validityValue * 2} Days', widget.validityValue * 2, 'Days')),
                    ]),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(child: _durationBtn('${widget.validityValue * 3} Days', widget.validityValue * 3, 'Days')),
                      const SizedBox(width: 12),
                      Expanded(child: _durationBtn('${widget.validityValue * 6} Days', widget.validityValue * 6, 'Days')),
                    ]),
                  ],
                ],

                // New end date preview
                if (newEndDate != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.calendar_today, color: Color(0xFF27AE60), size: 18),
                            const SizedBox(width: 10),
                            Text('New expiry: ${_fmt(newEndDate)}',
                                style: const TextStyle(
                                    color: Color(0xFF27AE60),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14)),
                          ],
                        ),
                        if (_priceController.text.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.payments_outlined, color: Color(0xFF27AE60), size: 18),
                              const SizedBox(width: 10),
                              Text('Renewal Price: ₹${_priceController.text}',
                                  style: const TextStyle(
                                      color: Color(0xFF27AE60),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14)),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 20),

                // Confirm button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _selectedValue != null ? () => _confirm(context) : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: Text(
                      _selectedValue != null ? 'Confirm ${TerminologyHelper.getTerminology(widget.shopCategory).renewActionLabel}' : 'Select a Duration',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _durationBtn(String label, int value, String unit) {
    final isSelected = _selectedValue == value && _selectedUnit == unit;
    return InkWell(
      onTap: () => _selectDuration(value, unit, label),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : const Color(0xFFF0F7FF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.primary,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  DateTime _calculateNewEndDate(DateTime start, int value, String unit) {
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
}
