import 'package:flutter/material.dart';
import 'package:csms/core/widgets/responsive_layout.dart';
import 'package:csms/features/reports/presentation/pages/report_page_mobile.dart';
import 'package:csms/features/reports/presentation/pages/report_page_web.dart';

class ReportPage extends StatelessWidget {
  const ReportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ResponsiveLayout(
      mobile: ReportPageMobile(),
      web: ReportPageWeb(),
      breakpoint: 800,
    );
  }
}
