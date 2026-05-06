import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:csms/core/widgets/responsive_layout.dart';
import 'package:csms/injection_container.dart' as di;
import '../bloc/shop_subscription_bloc.dart';
import 'shop_subscription_history_page_mobile.dart';
import 'shop_subscription_history_page_web.dart';

class ShopSubscriptionHistoryPage extends StatelessWidget {
  final String shopId;
  final String ownerId;

  const ShopSubscriptionHistoryPage({
    super.key,
    required this.shopId,
    required this.ownerId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => di.sl<ShopSubscriptionBloc>()
        ..add(LoadShopSubscriptionHistory(shopId, ownerId)),
      child: ResponsiveLayout(
        mobile: ShopSubscriptionHistoryPageMobile(
          shopId: shopId,
          ownerId: ownerId,
        ),
        web: ShopSubscriptionHistoryPageWeb(
          shopId: shopId,
          ownerId: ownerId,
        ),
      ),
    );
  }
}
