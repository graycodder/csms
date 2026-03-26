import 'package:flutter/material.dart';
import 'package:csms/core/theme/app_colors.dart';

class ShopInfoCard extends StatelessWidget {
  final String shopName;
  final String shopAddress;
  final String shopCategory;
  final String shopPhone;
  final VoidCallback onEdit;

  const ShopInfoCard({
    super.key,
    required this.shopName,
    required this.shopAddress,
    required this.shopCategory,
    required this.shopPhone,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Business Information',
                style: TextStyle(
                  color: AppColors.textDark,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              GestureDetector(
                onTap: onEdit,
                child: Row(
                  children: const [
                    Icon(
                      Icons.edit_outlined,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Edit',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildInfoFieldRow(
            title: 'Business Name',
            value: shopName,
            icon: Icons.business_outlined,
          ),
          const SizedBox(height: 16),
          _buildInfoFieldRow(
            title: 'Business Address',
            value: shopAddress,
            icon: Icons.location_on_outlined,
          ),
          const SizedBox(height: 16),
          _buildInfoFieldRow(
            title: 'Category',
            value: shopCategory,
            icon: Icons.category_outlined,
          ),
          const SizedBox(height: 16),
          _buildInfoFieldRow(
            title: 'Phone Number',
            value: shopPhone,
            icon: Icons.phone_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoFieldRow({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textLight,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(icon, color: AppColors.textLight, size: 20),
            const SizedBox(width: 8),
            Text(
              value,
              style: const TextStyle(
                color: AppColors.textDark,
                fontWeight: FontWeight.w500,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
