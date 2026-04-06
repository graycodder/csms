import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:csms/core/theme/app_theme.dart';
import 'package:csms/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:csms/features/splash_screen.dart';
import 'package:csms/features/shop/presentation/bloc/shop_context_bloc.dart';
import 'package:csms/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:csms/features/notifications/presentation/bloc/notification_bloc.dart';
import 'package:csms/injection_container.dart' as di;
import 'package:csms/firebase_options.dart';
import 'package:csms/core/services/notification_service.dart';
import 'package:csms/core/config/app_config.dart';
import 'package:csms/features/customer/presentation/bloc/customer_bloc.dart';
import 'package:csms/features/product/presentation/bloc/product_bloc.dart';
import 'package:csms/features/staff/presentation/bloc/staff_bloc.dart';
import 'package:csms/features/shop_subscription/presentation/bloc/shop_subscription_bloc.dart';
import 'package:csms/features/app_config/presentation/bloc/version_bloc.dart';
import 'package:csms/core/widgets/global_subscription_guard.dart';
import 'package:csms/core/widgets/global_version_guard.dart';
import 'package:csms/core/connectivity/presentation/bloc/connectivity_bloc.dart';
import 'package:csms/core/connectivity/presentation/bloc/connectivity_event.dart';
import 'package:csms/core/connectivity/presentation/bloc/connectivity_state.dart';
import 'package:csms/core/widgets/no_internet_widget.dart';

Future<void> bootstrap(AppConfig config) async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize Firebase. On Web, the JS SDK is already initialized via index.html
    // to avoid the getApp() race condition. The duplicate-app error is expected and safe.
    try {
      await Firebase.initializeApp(options: config.firebaseOptions);
    } catch (e) {
      if (!e.toString().contains('duplicate-app')) {
        rethrow;
      }
    }

    // Pass all uncaught "fatal" errors from the framework to Crashlytics
    if (!kIsWeb) {
      FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    }

    // Initialize Custom Notification Channels + Push Subscriptions cleanly
    await NotificationService().initialize();
  } catch (e) {
    debugPrint("Firebase/Service Initialization Error: $e");
  }

  // Initialize dependency injection safely afterwards
  await di.init();

  runApp(MyApp(config: config));
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Pass all uncaught asynchronous errors that aren't handled by the Flutter framework to Crashlytics
  if (!kIsWeb) {
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  }

  // Default to production if run directly from main.dart
  await bootstrap(
    AppConfig(
      environment: Environment.production,
      firebaseOptions: DefaultFirebaseOptions.currentPlatform,
      appTitle: 'CSMS',
    ),
  );
}

class MyApp extends StatelessWidget {
  final AppConfig config;
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  const MyApp({super.key, required this.config});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(360, 690),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (_, child) {
        return MultiBlocProvider(
          providers: [
            BlocProvider(create: (_) => di.sl<AuthBloc>()),
            BlocProvider(create: (_) => di.sl<ShopContextBloc>()),
            BlocProvider(create: (_) => di.sl<DashboardBloc>()),
            BlocProvider(create: (_) => di.sl<NotificationBloc>()),
            BlocProvider(create: (_) => di.sl<CustomerBloc>()),
            BlocProvider(create: (_) => di.sl<ProductBloc>()),
            BlocProvider(create: (_) => di.sl<StaffBloc>()),
            BlocProvider(create: (_) => di.sl<ShopSubscriptionBloc>()),
            BlocProvider(
              create: (_) => di.sl<VersionBloc>()..add(MonitorVersion()),
            ),
            BlocProvider(
              create: (_) => di.sl<ConnectivityBloc>()..add(MonitorConnectivity()),
            ),
          ],
          child: MaterialApp(
            navigatorKey: navigatorKey,
            title: config.appTitle,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            home: const SplashScreen(),
            builder: (context, child) {
              // Clamp system text scaling to 1.0 so device accessibility font
              // settings do not stack on top of ScreenUtil's own .sp scaling.
              // Without this, a device set to "Large" fonts will make all .sp
              // values proportionally larger than the design intent.
              final mediaQuery = MediaQuery.of(context);
              Widget content = MediaQuery(
                data: mediaQuery.copyWith(textScaler: TextScaler.noScaling),
                child: child!,
              );

              if (config.isStaging) {
                content = Banner(
                  message: "STAGING",
                  location: BannerLocation.topEnd,
                  color: Colors.orange,
                  child: content,
                );
              }

              return GlobalVersionGuard(
                child: GlobalSubscriptionGuard(
                  child: BlocBuilder<ConnectivityBloc, ConnectivityState>(
                    builder: (context, connectivityState) {
                      return Stack(
                        children: [
                          content,
                          if (connectivityState is ConnectivityOffline)
                            const NoInternetWidget(),
                        ],
                      );
                    },
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
