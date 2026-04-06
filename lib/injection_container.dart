import 'package:get_it/get_it.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

// Core Connectivity
import 'package:csms/core/connectivity/presentation/bloc/connectivity_bloc.dart';

// Auth
import 'package:csms/features/auth/domain/repositories/auth_repository.dart';
import 'package:csms/features/auth/domain/repositories/onboarding_repository.dart';
import 'package:csms/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:csms/features/auth/data/repositories/onboarding_repository_impl.dart';
import 'package:csms/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:csms/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Shop
import 'package:csms/features/shop/domain/repositories/shop_repository.dart';
import 'package:csms/features/shop/data/repositories/shop_repository_impl.dart';
import 'package:csms/features/shop/data/datasources/shop_local_data_source.dart';
import 'package:csms/features/shop/presentation/bloc/shop_context_bloc.dart';

// Customer
import 'package:csms/features/customer/domain/repositories/customer_repository.dart';
import 'package:csms/features/customer/data/repositories/customer_repository_impl.dart';
import 'package:csms/features/customer/presentation/bloc/customer_bloc.dart';

// Subscription
import 'package:csms/features/subscription/domain/repositories/subscription_repository.dart';
import 'package:csms/features/subscription/data/repositories/subscription_repository_impl.dart';
import 'package:csms/features/subscription/presentation/bloc/subscription_bloc.dart';

// Shop Subscription
import 'package:csms/features/shop_subscription/domain/repositories/shop_subscription_repository.dart';
import 'package:csms/features/shop_subscription/data/repositories/shop_subscription_repository_impl.dart';
import 'package:csms/features/shop_subscription/domain/usecases/get_shop_subscription_status.dart';
import 'package:csms/features/shop_subscription/domain/usecases/get_shop_subscription_history.dart';
import 'package:csms/features/shop_subscription/domain/usecases/renew_shop_subscription.dart';
import 'package:csms/features/shop_subscription/domain/usecases/stream_shop_subscription_status.dart';
import 'package:csms/features/shop_subscription/presentation/bloc/shop_subscription_bloc.dart';

// Notifications
import 'package:csms/features/notifications/domain/repositories/notification_repository.dart';
import 'package:csms/features/notifications/data/repositories/notification_repository_impl.dart';
import 'package:csms/features/notifications/presentation/bloc/notification_bloc.dart';

// Product
import 'package:csms/features/product/domain/repositories/product_repository.dart';
import 'package:csms/features/product/data/repositories/product_repository_impl.dart';
import 'package:csms/features/product/presentation/bloc/product_bloc.dart';

// Staff
import 'package:csms/features/staff/domain/repositories/staff_repository.dart';
import 'package:csms/features/staff/data/repositories/staff_repository_impl.dart';
import 'package:csms/features/staff/presentation/bloc/staff_bloc.dart';

// Profile
import 'package:csms/features/profile/domain/repositories/profile_repository.dart';
import 'package:csms/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:csms/features/profile/presentation/bloc/profile_bloc.dart';

// App Config
import 'package:csms/features/app_config/domain/repositories/app_config_repository.dart';
import 'package:csms/features/app_config/data/repositories/app_config_repository_impl.dart';
import 'package:csms/features/app_config/presentation/bloc/version_bloc.dart';

// Dashboard
import 'package:csms/features/dashboard/presentation/bloc/dashboard_bloc.dart';

// Reports
import 'package:csms/features/reports/domain/repositories/report_repository.dart';
import 'package:csms/features/reports/data/repositories/report_repository_impl.dart';
import 'package:csms/features/reports/domain/usecases/get_business_report.dart';
import 'package:csms/features/reports/presentation/bloc/report_bloc.dart';

final sl = GetIt.instance; // sl: Service Locator

Future<void> init() async {
  //! Core
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);

  //! Features - Auth
  sl.registerLazySingleton<AuthLocalDataSource>(
    () => AuthLocalDataSourceImpl(sharedPreferences: sl()),
  );

  sl.registerFactory(
    () => AuthBloc(authRepository: sl(), onboardingRepository: sl()),
  );

  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(localDataSource: sl()),
  );
  sl.registerLazySingleton<OnboardingRepository>(
    () => OnboardingRepositoryImpl(database: sl()),
  );

  //! Features - Shop
  sl.registerLazySingleton<ShopLocalDataSource>(
    () => ShopLocalDataSourceImpl(sharedPreferences: sl()),
  );
  sl.registerLazySingleton<ShopRepository>(
    () => ShopRepositoryImpl(database: sl(), localDataSource: sl()),
  );
  sl.registerFactory(() => ShopContextBloc(repository: sl()));

  //! Features - Customer
  sl.registerLazySingleton<CustomerRepository>(
    () => CustomerRepositoryImpl(database: sl()),
  );
  sl.registerFactory(
    () => CustomerBloc(
      customerRepository: sl(),
      subscriptionRepository: sl(),
      notificationRepository: sl(),
    ),
  );

  //! Features - Subscription
  sl.registerLazySingleton<SubscriptionRepository>(
    () => SubscriptionRepositoryImpl(database: sl()),
  );
  sl.registerFactory(() => SubscriptionBloc(repository: sl()));

  //! Features - Shop Subscription
  sl.registerLazySingleton<ShopSubscriptionRepository>(
    () => ShopSubscriptionRepositoryImpl(database: sl()),
  );
  sl.registerLazySingleton(() => GetShopSubscriptionStatus(sl()));
  sl.registerLazySingleton(() => StreamShopSubscriptionStatus(sl()));
  sl.registerLazySingleton(() => GetShopSubscriptionHistory(sl()));
  sl.registerLazySingleton(() => RenewShopSubscription(sl()));
  sl.registerFactory(
    () => ShopSubscriptionBloc(
      getStatus: sl(),
      streamStatus: sl(),
      getHistory: sl(),
      renewSubscription: sl(),
    ),
  );

  //! Features - Notifications
  sl.registerLazySingleton<NotificationRepository>(
    () => NotificationRepositoryImpl(database: sl()),
  );
  sl.registerFactory(() => NotificationBloc(repository: sl()));

  //! Features - Product
  sl.registerLazySingleton<ProductRepository>(
    () => ProductRepositoryImpl(database: sl()),
  );
  sl.registerFactory(() => ProductBloc(repository: sl()));

  sl.registerLazySingleton<StaffRepository>(
    () => StaffRepositoryImpl(database: sl()),
  );
  sl.registerFactory(() => StaffBloc(repository: sl()));

  //! Features - Profile
  sl.registerLazySingleton<ProfileRepository>(
    () => ProfileRepositoryImpl(database: sl()),
  );
  sl.registerFactory(() => ProfileBloc(repository: sl()));

  //! Features - App Config
  sl.registerLazySingleton<AppConfigRepository>(
    () => AppConfigRepositoryImpl(database: sl()),
  );
  sl.registerFactory(() => VersionBloc(repository: sl()));

  sl.registerFactory(
    () => DashboardBloc(
      customerRepository: sl(),
      productRepository: sl(),
      subscriptionRepository: sl(),
      shopRepository: sl(),
    ),
  );

  //! Features - Reports
  sl.registerLazySingleton<ReportRepository>(
    () => ReportRepositoryImpl(database: sl()),
  );
  sl.registerLazySingleton(() => GetBusinessReport(sl()));
  sl.registerFactory(() => ReportBloc(getBusinessReport: sl()));

  sl.registerFactory(() => ConnectivityBloc(connectivity: sl()));

  //! External

  sl.registerLazySingleton(() {
    final db = FirebaseDatabase.instance;
    if (!kIsWeb) {
      db.setPersistenceEnabled(true);
    }
    return db;
  });
  sl.registerLazySingleton(() => FirebaseAuth.instance);
  sl.registerLazySingleton(() => FirebaseFirestore.instance);
  sl.registerLazySingleton(() => Connectivity());
}
