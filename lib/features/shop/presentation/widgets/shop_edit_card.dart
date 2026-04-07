import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:csms/core/theme/app_colors.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:csms/features/shop/domain/entities/shop_entity.dart';

class ShopEditCard extends StatefulWidget {
  final ShopEntity shop;
  final Function(String name, String shopAddress, String category, String phone)
  onSave;
  final VoidCallback onCancel;

  const ShopEditCard({
    super.key,
    required this.shop,
    required this.onSave,
    required this.onCancel,
  });

  @override
  State<ShopEditCard> createState() => _ShopEditCardState();
}

class _ShopEditCardState extends State<ShopEditCard> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _categoryController;
  late TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.shop.shopName);
    _addressController = TextEditingController(text: widget.shop.shopAddress);
    _categoryController = TextEditingController(text: widget.shop.category);
    _phoneController = TextEditingController(text: widget.shop.phone ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _categoryController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.border.withOpacity(0.5)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildEditField(
              title: 'Business Name',
              controller: _nameController,
              maxLength: 20,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9\s]')),
              ],
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Required';
                if (v.length > 20) return 'Max 20 characters';
                return null;
              },
            ),
            SizedBox(height: 16.h),
            _buildEditField(
              title: 'Business Address',
              controller: _addressController,
              maxLength: 40,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9\s,.-]')),
              ],
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Required';
                if (v.length > 40) return 'Max 40 characters';
                return null;
              },
            ),
            SizedBox(height: 16.h),
            _buildEditField(
              title: 'Category',
              controller: _categoryController,
              maxLength: 20,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9\s]')),
              ],
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Required';
                if (v.length > 20) return 'Max 20 characters';
                return null;
              },
            ),
            SizedBox(height: 16.h),
            _buildEditField(
              title: 'Contact Phone',
              controller: _phoneController,
              maxLength: 10,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (v) {
                if (v == null || v.isEmpty) return 'Required';
                if (v.length != 10) return 'Must be 10 digits';
                return null;
              },
            ),
            SizedBox(height: 32.h),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: widget.onCancel,
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      minimumSize: Size(double.infinity, 48.h),
                      side: const BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: AppColors.textLight,
                        fontWeight: FontWeight.bold,
                        fontSize: 14.sp,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState?.validate() ?? false) {
                        widget.onSave(
                          _nameController.text.trim(),
                          _addressController.text.trim(),
                          _categoryController.text.trim(),
                          _phoneController.text.trim(),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      minimumSize: Size(double.infinity, 48.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Save Changes',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14.sp,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditField({
    required String title,
    required TextEditingController controller,
    int? maxLength,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: AppColors.textLight,
            fontWeight: FontWeight.w600,
            fontSize: 13.sp,
          ),
        ),
        SizedBox(height: 8.h),
        TextFormField(
          controller: controller,
          textCapitalization: TextCapitalization.words,
          maxLength: maxLength,
          inputFormatters: inputFormatters,
          validator: validator,
          keyboardType: keyboardType,
          style: TextStyle(fontSize: 15.sp, color: AppColors.textDark),
          decoration: InputDecoration(
            counterText: '',
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16.w,
              vertical: 12.h,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            errorStyle: TextStyle(fontSize: 11.sp),
          ),
        ),
      ],
    );
  }
}
