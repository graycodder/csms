import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:csms/core/theme/app_colors.dart';
import 'package:csms/features/shop/presentation/bloc/shop_context_bloc.dart';
import 'package:csms/features/dashboard/presentation/pages/dashboard_page.dart';

class ShopSelectionPage extends StatelessWidget {
  const ShopSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Select Business"),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textDark,
      ),
      body: BlocConsumer<ShopContextBloc, ShopContextState>(
        listener: (context, state) {
          if (state is ShopSelected) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const DashboardPage()),
            );
          }
        },
        builder: (context, state) {
          if (state is ShopContextLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ShopContextLoaded) {
            return ListView.separated(
              padding: const EdgeInsets.all(24),
              itemCount: state.shops.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final shop = state.shops[index];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  tileColor: AppColors.primary.withOpacity(0.05),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.primary,
                    child: Icon(Icons.business_rounded, color: Colors.white),
                  ),
                  title: Text(
                    shop.shopName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    shop.settings.notificationDaysBefore > 0
                        ? "Alerts: ${shop.settings.notificationDaysBefore} days before"
                        : "No alerts",
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    context.read<ShopContextBloc>().add(SelectShop(shop, state.shops));
                  },
                );
              },
            );
          }

          if (state is ShopContextEmpty) {
            return const Center(
              child: Text("No business accounts found. Please complete onboarding."),
            );
          }

          if (state is ShopContextError) {
            return Center(child: Text(state.message));
          }

          return const Center(child: Text("Initializing..."));
        },
      ),
    ),
  );
}
}
