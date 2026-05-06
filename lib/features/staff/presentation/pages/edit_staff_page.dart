import 'package:flutter/material.dart';
import 'package:csms/core/widgets/responsive_layout.dart';
import 'package:csms/features/staff/domain/entities/staff_entity.dart';
import 'edit_staff_page_mobile.dart';
import 'edit_staff_page_web.dart';

class EditStaffPage extends StatelessWidget {
  final StaffEntity staff;

  const EditStaffPage({
    super.key,
    required this.staff,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: EditStaffPageMobile(
        staff: staff,
      ),
      web: EditStaffPageWeb(
        staff: staff,
      ),
    );
  }
}
