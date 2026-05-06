import 'package:flutter/material.dart';
import 'package:csms/core/widgets/responsive_layout.dart';
import 'package:csms/features/dashboard/presentation/pages/dashboard_page_mobile.dart';
import 'package:csms/features/dashboard/presentation/pages/dashboard_page_web.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ResponsiveLayout(
      mobile: DashboardPageMobile(),
      web: DashboardPageWeb(),
      breakpoint: 800, // Switch to Web UI when screen is 800px or wider
    );
  }
}
