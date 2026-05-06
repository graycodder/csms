import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:csms/features/shop_subscription/domain/entities/shop_subscription_entity.dart';
import 'shop_subscription_history_page.dart';
import 'package:csms/core/widgets/web_sidebar.dart';

class ShopSubscriptionPageWeb extends StatefulWidget {
  final ShopSubscriptionEntity subscription;
  final String ownerId;

  const ShopSubscriptionPageWeb({
    super.key,
    required this.subscription,
    required this.ownerId,
  });

  @override
  State<ShopSubscriptionPageWeb> createState() =>
      _ShopSubscriptionPageWebState();
}

class _ShopSubscriptionPageWebState extends State<ShopSubscriptionPageWeb> {
  @override
  Widget build(BuildContext context) {
    final active = widget.subscription.activePlan;
    final now = DateTime.now();
    final isExpired =
        active == null ||
        active.status == 'expired' ||
        active.endDate.isBefore(now);

    return Row(
      children: [
        const WebSidebar(selectedIndex: 3),
        Expanded(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: Container(
                  color: const Color(0xFFF0F2F5),
                  width: double.infinity,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(40),
                    child: _buildSubscriptionContent(active, isExpired),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFF1E56F0),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(32, 48, 32, 48),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Colors.white12,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Business Subscription',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const Text(
                    'Configure and manage',
                    style: TextStyle(fontSize: 14, color: Colors.white70),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubscriptionContent(dynamic active, bool isExpired) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1000),
        child: Container(
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Plan Status',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Last checked: ${DateFormat('MMMM dd, yyyy').format(DateTime.now())}',
                style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
              ),
              const SizedBox(height: 40),
              if (active == null)
                _buildSection(
                  '1. Subscription Required',
                  'No active subscription found for this shop. Please contact support or choose a plan to continue using all features.',
                )
              else ...[
                _buildSection(
                  '1. Active Plan',
                  'Your shop is currently on the "${active.planName}" plan. This provides full access to executive management tools and real-time reporting.',
                ),
                _buildSection(
                  '2. Validity Period',
                  'Your current subscription cycle began on ${DateFormat('MMMM dd, yyyy').format(active.startDate)} and is scheduled to remain active until ${DateFormat('MMMM dd, yyyy').format(active.endDate)}.',
                ),
                _buildSection(
                  '3. Account Status',
                  'The current status of your business account is "${active.status.toUpperCase()}". ${isExpired ? "Warning: Your subscription has expired and features may be limited." : "Everything is running smoothly."}',
                ),
                _buildSection(
                  '4. Data & Management',
                  'Your business data is being processed according to the executive management tier. Monthly reports and customer insights are updated in real-time.',
                ),
              ],
              const SizedBox(height: 40),
              Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ShopSubscriptionHistoryPage(
                              shopId: widget.subscription.shopId,
                              ownerId: widget.ownerId,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E56F0),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 20,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'View Billing History',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF4B5563),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
