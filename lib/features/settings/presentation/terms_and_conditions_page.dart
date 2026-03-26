import 'package:flutter/material.dart';
import 'package:csms/core/theme/app_colors.dart';

class TermsAndConditionsPage extends StatelessWidget {
  const TermsAndConditionsPage({super.key});

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
                      'Terms & Conditions',
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
                    _SectionTitle('1. Acceptance of Terms'),
                    _SectionBody(
                      'By accessing and using this Subscription Manager application, you accept and agree to be bound by the terms and provision of this agreement.',
                    ),
                    _SectionTitle('2. Use License'),
                    _SectionBody(
                      'Permission is granted to use this application for personal and commercial purposes to manage customer subscriptions and product renewals. This license shall automatically terminate if you violate any of these restrictions.',
                    ),
                    _SectionTitle('3. Data Management'),
                    _SectionBody(
                      'You are responsible for maintaining the confidentiality of your customer data. The application stores data locally on your device. We recommend regular backups of your important business information.',
                    ),
                    _SectionTitle('4. Limitations'),
                    _SectionBody(
                      'In no event shall the application developers be liable for any damages arising out of the use or inability to use the application, including but not limited to loss of data or business interruption.',
                    ),
                    _SectionTitle('5. Modifications'),
                    _SectionBody(
                      'We reserve the right to modify these terms at any time. We will notify users of significant changes. Continued use of the application after changes constitutes acceptance of the new terms.',
                    ),
                    _SectionTitle('6. Governing Law'),
                    _SectionBody(
                      'These terms shall be governed by and construed in accordance with applicable laws. Any disputes relating to these terms will be subject to the exclusive jurisdiction of the relevant courts.',
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
                'Terms & Conditions',
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
