import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:csms/core/widgets/responsive_layout.dart';
import 'package:csms/features/reports/presentation/pages/report_page_mobile.dart';
import 'package:csms/features/reports/presentation/pages/report_page_web.dart';
import 'package:csms/features/reports/presentation/bloc/report_bloc.dart';
import 'package:csms/injection_container.dart';

class ReportPage extends StatelessWidget {
  const ReportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<ReportBloc>(),
      child: const ResponsiveLayout(
        mobile: ReportPageMobile(),
        web: ReportPageWeb(),
        breakpoint: 800,
      ),
    );
  }
}
