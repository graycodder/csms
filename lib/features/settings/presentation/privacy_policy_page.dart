import 'package:flutter/material.dart';
import 'package:csms/core/theme/app_colors.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Privacy Policy',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Last updated: March 21, 2026',
                      style: TextStyle(fontSize: 13, color: Color(0xFF9E9E9E)),
                    ),
                    SizedBox(height: 20),
                    _SectionTitle('1. Information We Collect'),
                    _SectionBody(
                      'The Subscription Manager application collects and stores information you provide, including shop details, customer names, phone numbers, subscription dates, and payment amounts. All data is stored locally on your device.',
                    ),
                    _SectionTitle('2. How We Use Your Information'),
                    _SectionBody(
                      'Your information is used solely to provide subscription management functionality, including tracking customer subscriptions, sending renewal notifications, and generating business insights. We do not share your data with third parties.',
                    ),
                    _SectionTitle('3. Data Storage and Security'),
                    _SectionBody(
                      "All data is stored locally in your browser's local storage. We do not transmit your data to external servers. However, you are responsible for securing your device and backing up your data regularly.",
                    ),
                    _SectionTitle('4. Data Retention'),
                    _SectionBody(
                      'Your data remains on your device until you choose to delete it. You can delete individual customers, clear all data, or uninstall the application at any time. Data deletion is permanent and cannot be recovered.',
                    ),
                    _SectionTitle('5. Cookies and Tracking'),
                    _SectionBody(
                      'This application does not use cookies or any third-party tracking technologies. All functionality is self-contained within the application.',
                    ),
                    _SectionTitle('6. Changes to This Policy'),
                    _SectionBody(
                      'We may update this Privacy Policy from time to time. We will notify you of any changes by updating the date at the top of this page. Continued use of the application after any changes constitutes acceptance of the updated policy.',
                    ),
                    _SectionTitle('7. Contact Us'),
                    _SectionBody(
                      'If you have any questions about this Privacy Policy or our data practices, please contact us through the application support channel.',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        left: 20,
        right: 20,
        bottom: 28,
      ),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Row(
        children: [
          InkWell(
            onTap: () => Navigator.pop(context),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_back, color: Colors.white, size: 22),
            ),
          ),
          const SizedBox(width: 16),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Privacy Policy',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.2,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Configure and manage',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1A1A2E),
        ),
      ),
    );
  }
}

class _SectionBody extends StatelessWidget {
  final String text;
  const _SectionBody(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        color: Color(0xFF4B5563),
        height: 1.6,
      ),
    );
  }
}
