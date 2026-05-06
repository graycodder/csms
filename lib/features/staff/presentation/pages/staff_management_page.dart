import 'package:flutter/material.dart';
import 'package:csms/core/widgets/responsive_layout.dart';
import 'package:csms/features/staff/presentation/pages/staff_management_page_mobile.dart';
import 'package:csms/features/staff/presentation/pages/staff_management_page_web.dart';

class StaffManagementPage extends StatelessWidget {
  const StaffManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ResponsiveLayout(
      mobile: StaffManagementPageMobile(),
      web: StaffManagementPageWeb(),
      breakpoint: 800,
    );
  }
}
