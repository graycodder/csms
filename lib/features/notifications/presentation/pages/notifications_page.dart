import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:csms/core/widgets/responsive_layout.dart';
import 'package:csms/features/shop/presentation/bloc/shop_context_bloc.dart';
import 'package:csms/features/notifications/presentation/bloc/notification_bloc.dart';
import 'package:csms/core/utils/terminology_helper.dart';
import 'package:csms/core/utils/loading_overlay.dart';
import 'notifications_page_mobile.dart';
import 'notifications_page_web.dart';

import 'package:csms/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:csms/features/auth/presentation/bloc/auth_state.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      body: BlocBuilder<NotificationBloc, NotificationState>(
        builder: (context, state) {
          if (state is NotificationListening) {
            final shopState = context.watch<ShopContextBloc>().state;
            final authState = context.watch<AuthBloc>().state;
            
            final category = shopState is ShopSelected
                ? shopState.selectedShop.category
                : '';
            final term = TerminologyHelper.getTerminology(category);
            final ownerId = authState is AuthAuthenticated ? authState.ownerId : '';

            return ResponsiveLayout(
              mobile: NotificationsPageMobile(
                notifications: state.notifications,
                term: term,
              ),
              web: NotificationsPageWeb(
                notifications: state.notifications,
                shopCategory: category,
                ownerId: ownerId,
              ),
              breakpoint: 800,
            );
          } else if (state is NotificationError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      state.message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ],
                ),
              ),
            );
          }
          return const LoadingOverlay();
        },
      ),
    );
  }
}
