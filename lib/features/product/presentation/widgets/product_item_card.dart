import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:csms/core/theme/app_colors.dart';
import 'package:csms/features/product/domain/entities/product_entity.dart';

class ProductItemCard extends StatelessWidget {
  final ProductEntity product;
  final VoidCallback onEdit;
  final VoidCallback onStatusToggle;

  const ProductItemCard({
    super.key,
    required this.product,
    required this.onEdit,
    required this.onStatusToggle,
  });

  @override
  Widget build(BuildContext context) {
    final bool isActive = product.status == 'active';

    return ColorFiltered(
      colorFilter: isActive
          ? const ColorFilter.mode(Colors.transparent, BlendMode.multiply)
          : const ColorFilter.matrix([
              0.2126, 0.7152, 0.0722, 0, 0,
              0.2126, 0.7152, 0.0722, 0, 0,
              0.2126, 0.7152, 0.0722, 0, 0,
              0,      0,      0,      1, 0,
            ]), // Grayscale filter for inactive products
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: isActive 
                ? AppColors.border.withOpacity(0.5)
                : AppColors.border.withOpacity(0.3),
          ),
          boxShadow: isActive ? null : [
             BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10.r,
              offset: Offset(0, 4.h),
            )
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        product.name[0].toUpperCase() + product.name.substring(1).toLowerCase(),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15.sp,
                          color: isActive ? AppColors.textDark : AppColors.textLight,
                          decoration: isActive ? null : TextDecoration.lineThrough,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      _StatusBadge(status: product.status),
                    ],
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'Price: ${product.priceType == 'flexible' ? 'Flexible' : '${product.price.toStringAsFixed(0)}'} • ${product.validityType == 'flexible' ? 'Flexible' : '${product.validityValue} ${product.validityUnit}'}',
                    style: TextStyle(
                      color: isActive ? AppColors.textLight : AppColors.textLight.withOpacity(0.7),
                      fontSize: 13.sp,
                    ),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                GestureDetector(
                  onTap: onEdit,
                  child: Container(
                    padding: EdgeInsets.all(8.r),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.edit_outlined,
                      color: AppColors.primary,
                      size: 18.sp,
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                GestureDetector(
                  onTap: onStatusToggle,
                  child: Container(
                    padding: EdgeInsets.all(8.r),
                    decoration: BoxDecoration(
                      color: isActive 
                          ? const Color(0xFFEF4444).withOpacity(0.1)
                          : const Color(0xFF10B981).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isActive ? Icons.block : Icons.check_circle_outline,
                      color: isActive ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                      size: 18.sp,
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
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final bool isActive = status == 'active';
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: isActive 
            ? const Color(0xFF10B981).withOpacity(0.1)
            : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Text(
        isActive ? 'Active' : 'Inactive',
        style: TextStyle(
          fontSize: 10.sp,
          fontWeight: FontWeight.bold,
          color: isActive ? const Color(0xFF10B981) : Colors.grey,
        ),
      ),
    );
  }
}
