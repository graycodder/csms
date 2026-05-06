import 'package:flutter/material.dart';
import 'package:csms/core/widgets/responsive_layout.dart';
import 'package:csms/features/settings/presentation/settings_page_mobile.dart';
import 'package:csms/features/settings/presentation/settings_page_web.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ResponsiveLayout(
      mobile: SettingsPageMobile(),
      web: SettingsPageWeb(),
      breakpoint: 800,
    );
  }
}
