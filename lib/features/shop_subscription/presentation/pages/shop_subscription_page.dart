import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:csms/core/widgets/responsive_layout.dart';
import 'package:csms/features/shop/presentation/bloc/shop_context_bloc.dart';
import '../bloc/shop_subscription_bloc.dart';
import 'shop_subscription_page_mobile.dart';
import 'shop_subscription_page_web.dart';
import 'package:csms/injection_container.dart' as di;
import 'package:csms/core/utils/loading_overlay.dart';
import 'package:csms/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:csms/features/auth/presentation/bloc/auth_state.dart';

class ShopSubscriptionPage extends StatelessWidget {
  const ShopSubscriptionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final shopState = context.read<ShopContextBloc>().state;
        final bloc = di.sl<ShopSubscriptionBloc>();
        if (shopState is ShopSelected) {
          bloc.add(LoadShopSubscriptionStatus(shopState.selectedShop.shopId));
        }
        return bloc;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF0F2F5),
        body: BlocBuilder<ShopSubscriptionBloc, ShopSubscriptionState>(
          builder: (context, state) {
            if (state is ShopSubscriptionLoading ||
                state is ShopSubscriptionInitial) {
              return const LoadingOverlay();
            }

            if (state is ShopSubscriptionError) {
              return Center(
                child: Text(
                  state.message,
                  style: const TextStyle(color: Colors.red),
                ),
              );
            }

            if (state is ShopSubscriptionStatusLoaded) {
              final authState = context.watch<AuthBloc>().state;
              final ownerId = authState is AuthAuthenticated ? authState.ownerId : '';

              return ResponsiveLayout(
                mobile: ShopSubscriptionPageMobile(
                  subscription: state.status,
                  ownerId: ownerId,
                ),
                web: ShopSubscriptionPageWeb(
                  subscription: state.status,
                  ownerId: ownerId,
                ),
                breakpoint: 800,
              );
            }
            
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}
