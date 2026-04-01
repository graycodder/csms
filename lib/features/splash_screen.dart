import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:csms/core/theme/app_colors.dart';
import 'package:csms/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:csms/features/auth/presentation/bloc/auth_event.dart';
import 'package:csms/features/auth/presentation/bloc/auth_state.dart';
import 'package:csms/features/auth/presentation/pages/login_page.dart';
import 'package:csms/features/shop/presentation/pages/shop_selection_page.dart';
import 'package:csms/features/shop/presentation/bloc/shop_context_bloc.dart';
import 'package:csms/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:csms/features/auth/presentation/pages/onboarding_page.dart';
import 'package:lottie/lottie.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Dispatch the check auth immediately
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authState = context.read<AuthBloc>().state;
      final shopState = context.read<ShopContextBloc>().state;

      if (shopState is ShopSelected) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => DashboardPage()),
        );
        return;
      } else if (shopState is ShopContextLoaded) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ShopSelectionPage()),
        );
        return;
      } else if (authState is AuthAuthenticated) {
        context.read<ShopContextBloc>().add(
              LoadShops(
                ownerId: authState.ownerId,
                shopId: authState.shopId,
                role: authState.role,
              ),
            );
        return;
      }

      context.read<AuthBloc>().add(CheckAuthStatus());
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is AuthAuthenticated) {
              print('DEBUG: SplashScreen - AuthAuthenticated: ${state.userId}');
              // Start loading shops immediately natively
              context.read<ShopContextBloc>().add(
                    LoadShops(
                      ownerId: state.ownerId,
                      shopId: state.shopId,
                      role: state.role,
                    ),
                  );
            } else if (state is AuthUnauthenticated || state is AuthError) {
              print('DEBUG: SplashScreen - Unauthenticated or Error');
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
              );
            }
          },
        ),
        BlocListener<ShopContextBloc, ShopContextState>(
          listener: (context, state) {
            print('DEBUG: SplashScreen - ShopContextState: $state');
            if (state is ShopSelected) {
              print('DEBUG: SplashScreen - Navigating to Dashboard');
              // Only one shop or shop already selected - go to dashboard natively
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => DashboardPage()),
              );
            } else if (state is ShopContextLoaded) {
              print('DEBUG: SplashScreen - Multiple shops found');
              // Multiple shops found - let user pick natively
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const ShopSelectionPage()),
              );
            }
            else if (state is ShopContextEmpty) {
               // Handle no shops (could be a new owner) natively
               Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()), // Or Onboarding natives
              );
            }
          },
        ),
      ],
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/app_icon.png',
                width: 140.w,
                height: 140.w,
              ),
              SizedBox(height: 32.h),
              Lottie.asset(
                'assets/animations/loading.json',
                width: 80.w,
                height: 80.w,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
