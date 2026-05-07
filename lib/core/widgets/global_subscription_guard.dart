import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:csms/features/shop_subscription/presentation/bloc/shop_subscription_bloc.dart';
import 'package:csms/features/subscription/presentation/pages/shop_subscription_lock_page.dart';
import 'package:csms/features/shop/presentation/bloc/shop_context_bloc.dart';

class GlobalSubscriptionGuard extends StatefulWidget {
  final Widget child;

  const GlobalSubscriptionGuard({super.key, required this.child});

  @override
  State<GlobalSubscriptionGuard> createState() => _GlobalSubscriptionGuardState();
}

class _GlobalSubscriptionGuardState extends State<GlobalSubscriptionGuard> {
  @override
  void initState() {
    super.initState();
    _triggerSubscriptionCheck();
  }

  void _triggerSubscriptionCheck() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final shopState = context.read<ShopContextBloc>().state;
      if (shopState is ShopSelected) {
        context.read<ShopSubscriptionBloc>().add(
              ListenToShopSubscriptionStatus(shopState.selectedShop.shopId),
            );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ShopContextBloc, ShopContextState>(
      listener: (context, state) {
        if (state is ShopSelected) {
          context.read<ShopSubscriptionBloc>().add(
                ListenToShopSubscriptionStatus(state.selectedShop.shopId),
              );
        }
      },
      child: BlocBuilder<ShopSubscriptionBloc, ShopSubscriptionState>(
        builder: (context, state) {
          if (state is ShopSubscriptionStatusLoaded) {
            final status = state.status;
            final active = status.activePlan;
            final now = DateTime.now();
            final isExpired =
                active == null ||
                active.status == 'expired' ||
                active.endDate.isBefore(now);

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
          return widget.child;
        },
      ),
    );
  }
}
