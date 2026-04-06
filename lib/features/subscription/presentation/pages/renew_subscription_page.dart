import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_colors.dart';
import 'package:csms/features/customer/presentation/bloc/customer_bloc.dart';
import 'package:csms/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:csms/features/auth/presentation/bloc/auth_state.dart';
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
  final double currentBalance;

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
    this.currentBalance = 0.0,
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
  final _paidAmountController = TextEditingController();
  String _selectedPaymentMode = 'Cash';

  @override
  void initState() {
    super.initState();
    _priceController = TextEditingController(
      text: widget.basePrice.toStringAsFixed(0),
    );
    _validityController = TextEditingController(
      text: widget.validityValue.toString(),
    );

    if (widget.validityType == 'fixed') {
      _selectedValue = null;
      _selectedUnit = null;
    } else {
      _selectedValue = widget.validityValue;
      _selectedUnit = widget.validityUnit.toLowerCase();
      _selectedLabel = 'Custom Duration';
      _updatePrice(_selectedValue);
    }
  }

  @override
  void dispose() {
    _priceController.dispose();
    _validityController.dispose();
    _paidAmountController.dispose();
    super.dispose();
  }

  String _fmt(DateTime d) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
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
      _updatePrice(value);
    });
  }

  void _updatePrice(int? value) {
    if (value == null || widget.validityValue == 0) return;
    // Calculate price relative to base plan price and its validity
    final price = (widget.basePrice / widget.validityValue) * value;
    _priceController.text = price.toStringAsFixed(0);
    // Suggest paying the new plan price by default, but we'll show the total due with carry-forward
    _paidAmountController.text = price.toStringAsFixed(0);
  }

  Future<void> _confirm(BuildContext context) async {
    if (_selectedValue == null || _selectedUnit == null) return;

    final newEndDate = _calculateNewEndDate(
      widget.currentEndDate,
      _selectedValue!,
      _selectedUnit!,
    );
    final isActive = widget.currentEndDate.isAfter(DateTime.now());

    FocusManager.instance.primaryFocus?.unfocus();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Text(
          'Confirm ${TerminologyHelper.getTerminology(widget.shopCategory).renewActionLabel}',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Duration: $_selectedLabel',
                style: TextStyle(fontSize: 15.sp),
              ),
              SizedBox(height: 8.h),
              if (isActive) ...[
                SizedBox(height: 4.h),
                Container(
                  padding: EdgeInsets.all(10.r),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: AppColors.primary,
                        size: 18.sp,
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          'Active ${TerminologyHelper.getTerminology(widget.shopCategory).subscriptionLabel.toLowerCase()} found — new period will be queued after current expiry.',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 13.sp,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  'Current expiry: ${_fmt(widget.currentEndDate)}',
                  style: TextStyle(color: AppColors.textLight, fontSize: 13.sp),
                ),
              ],
              SizedBox(height: 4.h),
              if (widget.currentBalance > 0) ...[
                Text(
                  'Carry Forward balance: ₹${widget.currentBalance.toStringAsFixed(0)}',
                  style: TextStyle(
                    color: Colors.red.shade700,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4.h),
              ],
              Text(
                'New Plan: ₹${_priceController.text}',
                style: TextStyle(fontSize: 14.sp),
              ),
              const Divider(),
              Text(
                'Total Due: ₹${((double.tryParse(_priceController.text) ?? 0) + widget.currentBalance).toStringAsFixed(0)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                  fontSize: 15.sp,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'New expiry: ${_fmt(newEndDate)}',
                style: TextStyle(color: AppColors.textLight, fontSize: 13.sp),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              FocusManager.instance.primaryFocus?.unfocus();
              Navigator.pop(context, false);
            },
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.textLight, fontSize: 14.sp),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              FocusManager.instance.primaryFocus?.unfocus();
              Navigator.pop(context, true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),
            child: Text(
              'Confirm',
              style: TextStyle(color: Colors.white, fontSize: 14.sp),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final authState = context.read<AuthBloc>().state;
      if (authState is AuthAuthenticated) {
        final price = double.tryParse(_priceController.text);
        final paidAmt =
            double.tryParse(_paidAmountController.text) ?? price ?? 0.0;

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
            paidAmount: paidAmt,
            paymentMode: _selectedPaymentMode,
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
        ? _calculateNewEndDate(
            widget.currentEndDate,
            _selectedValue!,
            _selectedUnit!,
          )
        : null;

    return BlocListener<CustomerBloc, CustomerState>(
      listener: (context, state) {
        if (state is CustomerLoading) {
          LoadingOverlayHelper.show(context);
        } else if (state is CustomerSuccess) {
          LoadingOverlayHelper.hide();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Membership renewed successfully!',
                style: TextStyle(fontSize: 14.sp),
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.pop(context); // Close Renew Page
        } else if (state is CustomerError) {
          LoadingOverlayHelper.hide();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Error: ${state.message}',
                style: TextStyle(fontSize: 14.sp),
              ),
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
            TerminologyHelper.getTerminology(
              widget.shopCategory,
            ).renewActionLabel,
            style: TextStyle(
              color: AppColors.textDark,
              fontWeight: FontWeight.bold,
              fontSize: 18.sp,
            ),
          ),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(24.0.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title & Info
                Text(
                  widget.productName,
                  style: TextStyle(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'Current ${TerminologyHelper.getTerminology(widget.shopCategory).planLabel.toLowerCase()}: ${widget.validityValue} ${widget.validityUnit}',
                  style: TextStyle(
                    fontSize: 16.sp,
                    color: AppColors.textLight.withOpacity(0.7),
                  ),
                ),
                SizedBox(height: 24.h),

                // Queue info banner
                if (isActive) ...[
                  SizedBox(height: 8.h),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 8.h,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.queue,
                          size: 16.sp,
                          color: AppColors.primary,
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            'Currently active until ${_fmt(widget.currentEndDate)} — new period will be queued.',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 12.sp,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  Text(
                    'Expired on ${_fmt(widget.currentEndDate)}',
                    style: TextStyle(color: Colors.red, fontSize: 13.sp),
                  ),
                ],

                SizedBox(height: 20.h),

                if (widget.priceType == 'flexible') ...[
                  Text(
                    'Custom Price',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15.sp,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  TextField(
                    controller: _priceController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      FilteringTextInputFormatter.deny(RegExp(r'^0')),
                    ],
                    decoration: const InputDecoration(hintText: 'Enter price'),
                    onChanged: (v) => setState(() {}),
                  ),
                  SizedBox(height: 20.h),
                ],

                if (widget.validityType == 'flexible') ...[
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Validity',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15.sp,
                              ),
                            ),
                            SizedBox(height: 12.h),
                            TextField(
                              controller: _validityController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                FilteringTextInputFormatter.deny(RegExp(r'^0')),
                              ],
                              onChanged: (v) {
                                setState(() {
                                  _selectedValue = int.tryParse(v);
                                  _selectedLabel = 'Custom Duration';
                                  _updatePrice(_selectedValue);
                                });
                              },
                              decoration: const InputDecoration(
                                prefixIcon: Icon(Icons.timer_outlined),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 16.w),
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Unit',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15.sp,
                              ),
                            ),
                            SizedBox(height: 12.h),
                            DropdownButtonFormField<String>(
                              value: (_selectedUnit ?? 'months').toLowerCase(),
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
                  SizedBox(height: 20.h),
                ],

                if (widget.validityType != 'flexible') ...[
                  Text(
                    'Quick Select Duration:',
                    style: TextStyle(
                      color: AppColors.textLight,
                      fontSize: 14.sp,
                    ),
                  ),
                  SizedBox(height: 12.h),

                  // Duration grid
                  if (widget.validityUnit.toLowerCase().contains('month')) ...[
                    Row(
                      children: [
                        Expanded(child: _durationBtn('1 Month', 1, 'Months')),
                        SizedBox(width: 12.w),
                        Expanded(child: _durationBtn('3 Months', 3, 'Months')),
                      ],
                    ),
                    SizedBox(height: 12.h),
                    Row(
                      children: [
                        Expanded(child: _durationBtn('6 Months', 6, 'Months')),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: _durationBtn('12 Months', 12, 'Months'),
                        ),
                      ],
                    ),
                  ] else ...[
                    Row(
                      children: [
                        Expanded(
                          child: _durationBtn(
                            '${widget.validityValue} Days',
                            widget.validityValue,
                            'Days',
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: _durationBtn(
                            '${widget.validityValue * 2} Days',
                            widget.validityValue * 2,
                            'Days',
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12.h),
                    Row(
                      children: [
                        Expanded(
                          child: _durationBtn(
                            '${widget.validityValue * 3} Days',
                            widget.validityValue * 3,
                            'Days',
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: _durationBtn(
                            '${widget.validityValue * 6} Days',
                            widget.validityValue * 6,
                            'Days',
                          ),
                        ),
                      ],
                    ),
                  ],
                ],

                SizedBox(height: 24.h),
                const Divider(),
                SizedBox(height: 20.h),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Amount Paid',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13.sp,
                            ),
                          ),
                          SizedBox(height: 8.h),
                          TextFormField(
                            controller: _paidAmountController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              hintText: '0',
                              prefixIcon: Icon(Icons.currency_rupee),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Payment Mode',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13.sp,
                            ),
                          ),
                          SizedBox(height: 8.h),
                          DropdownButtonFormField<String>(
                            value: _selectedPaymentMode,
                            decoration: const InputDecoration(
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                            items: ['Cash', 'UPI', 'Card', 'Bank Transfer'].map(
                              (m) {
                                return DropdownMenuItem(
                                  value: m,
                                  child: Text(
                                    m,
                                    style: TextStyle(fontSize: 14.sp),
                                  ),
                                );
                              },
                            ).toList(),
                            onChanged: (v) => setState(
                              () => _selectedPaymentMode = v ?? 'Cash',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Builder(
                  builder: (context) {
                    final totalDue =
                        (double.tryParse(_priceController.text) ?? 0) +
                        widget.currentBalance;
                    final pending =
                        totalDue -
                        (double.tryParse(_paidAmountController.text) ?? 0);
                    if (pending > 0) {
                      return Padding(
                        padding: EdgeInsets.only(top: 16.h),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Pending Balance:',
                              style: TextStyle(
                                color: Colors.red.shade700,
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '₹${pending.toStringAsFixed(0)}',
                              style: TextStyle(
                                color: Colors.red.shade700,
                                fontSize: 15.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),

                // New end date preview
                if (newEndDate != null) ...[
                  SizedBox(height: 16.h),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 12.h,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              color: const Color(0xFF27AE60),
                              size: 18.sp,
                            ),
                            SizedBox(width: 10.w),
                            Text(
                              'New expiry: ${_fmt(newEndDate)}',
                              style: TextStyle(
                                color: const Color(0xFF27AE60),
                                fontWeight: FontWeight.bold,
                                fontSize: 14.sp,
                              ),
                            ),
                          ],
                        ),
                        if (_priceController.text.isNotEmpty) ...[
                          SizedBox(height: 8.h),
                          Row(
                            children: [
                              Icon(
                                Icons.payments_outlined,
                                color: const Color(0xFF27AE60),
                                size: 18.sp,
                              ),
                              SizedBox(width: 10.w),
                              Text(
                                'Renewal Price: ₹${_priceController.text}',
                                style: TextStyle(
                                  color: const Color(0xFF27AE60),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14.sp,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],

                SizedBox(height: 20.h),

                SizedBox(
                  width: double.infinity,
                  height: 56.h,
                  child: ElevatedButton(
                    onPressed: _selectedValue != null
                        ? () => _confirm(context)
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      _selectedValue != null
                          ? 'Confirm ${TerminologyHelper.getTerminology(widget.shopCategory).renewActionLabel}'
                          : 'Select a Duration',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
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
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16.h),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : const Color(0xFFF0F7FF),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
            width: 2.w,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.primary,
            fontWeight: FontWeight.bold,
            fontSize: 15.sp,
          ),
        ),
      ),
    );
  }

  DateTime _calculateNewEndDate(DateTime start, int value, String unit) {
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
}
