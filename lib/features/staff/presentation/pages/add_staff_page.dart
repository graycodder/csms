import 'package:flutter/material.dart';
import 'package:csms/core/widgets/responsive_layout.dart';
import 'add_staff_page_mobile.dart';
import 'add_staff_page_web.dart';

class AddStaffPage extends StatelessWidget {
  final String shopId;
  final String ownerId;

  const AddStaffPage({
    super.key,
    required this.shopId,
    required this.ownerId,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: AddStaffPageMobile(
        shopId: shopId,
        ownerId: ownerId,
      ),
      web: AddStaffPageWeb(
        shopId: shopId,
        ownerId: ownerId,
      ),
    );
  }
}
