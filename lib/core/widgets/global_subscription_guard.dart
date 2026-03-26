import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:csms/features/shop_subscription/presentation/bloc/shop_subscription_bloc.dart';
import 'package:csms/features/subscription/presentation/pages/shop_subscription_lock_page.dart';
import 'package:csms/features/shop_subscription/domain/entities/shop_subscription_entity.dart';

class GlobalSubscriptionGuard extends StatelessWidget {
  final Widget child;

  const GlobalSubscriptionGuard({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ShopSubscriptionBloc, ShopSubscriptionState>(
      builder: (context, state) {
        if (state is ShopSubscriptionStatusLoaded) {
          final status = state.status;
          final active = status.activePlan;
          final now = DateTime.now();
          final isExpired = active == null || active.status == 'expired' || active.endDate.isBefore(now);

          if (isExpired) {
            return ShopSubscriptionLockPage(
              shopName: status.shopName,
              startDate: active?.startDate,
              endDate: active?.endDate,
              status: active?.status ?? 'No Active Plan',
            );
          }
        } else if (state is ShopSubscriptionError) {
          return const ShopSubscriptionLockPage(
            shopName: 'Shop',
            status: 'Subscription Required',
          );
        }
        return child;
      },
    );
  }
}
