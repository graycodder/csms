import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'onboarding_page_mobile.dart';
import 'onboarding_page_web.dart';

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    // If it's web or the screen is wider than 600px, show the web optimized version
    if (kIsWeb || MediaQuery.of(context).size.width > 600) {
      return const OnboardingPageWeb();
    }
    // Otherwise show the mobile version
    return const OnboardingPageMobile();
  }
}
