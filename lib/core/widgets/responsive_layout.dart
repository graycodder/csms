import 'package:flutter/material.dart';

class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget web;
  final double breakpoint;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    required this.web,
    this.breakpoint = 800,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= breakpoint) {
          return web;
        } else {
          return mobile;
        }
      },
    );
  }
}
