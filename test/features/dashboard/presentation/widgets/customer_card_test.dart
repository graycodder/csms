import 'package:csms/features/dashboard/presentation/widgets/customer_card.dart';
import 'package:csms/features/customer/data/models/customer_model.dart';
import 'package:csms/features/subscription/domain/entities/subscription_entity.dart';
import 'package:csms/features/shop/domain/entities/shop_entity.dart';
import 'package:csms/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:csms/core/utils/terminology_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

void main() {
  final tCustomer = CustomerModel(
    customerId: '123',
    shopId: 'shop1',
    name: 'John Doe',
    mobileNumber: '1234567890',
    email: 'john@example.com',
    assignedProductIds: const {},
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
    updatedById: 'admin1',
    ownerId: 'owner1',
    status: 'active',
  );

  final tShop = ShopEntity(
    shopId: 'shop1',
    shopName: 'Test Shop',
    ownerId: 'owner1',
    category: 'Gym',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
    shopAddress: '123 Street',
    updatedById: 'admin1',
    settings: const ShopSettings(
      expiredDaysBefore: 30,
      notificationDaysBefore: 7,
      showProductFilters: true,
      autoArchiveExpired: false,
      whatsappReminderEnabled: true,
      defaultCountryCode: '91',
    ),
  );

  final tTerm = TerminologyHelper.getTerminology('Gym');

  SubscriptionEntity createSub({
    required String id,
    required DateTime endDate,
  }) {
    return SubscriptionEntity(
      subscriptionId: id,
      shopId: 'shop1',
      customerId: '123',
      productId: 'p1',
      startDate: DateTime.now().subtract(const Duration(days: 5)),
      endDate: endDate,
      status: 'active',
      logs: const [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      price: 100,
      updatedById: 'admin1',
      ownerId: 'owner1',
    );
  }

  testWidgets('CustomerCard displays customer info and status correctly', (
    WidgetTester tester,
  ) async {
    final activeSub = createSub(
      id: 'sub1',
      endDate: DateTime.now().add(const Duration(days: 25)),
    );

    final tState = DashboardLoaded(
      shop: tShop,
      products: const [],
      activeSubs: [activeSub],
      expiringSoon: const [],
      customers: [tCustomer],
      totalCustomers: 1,
      activeSubscriptions: 1,
      logs: [],
    );

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(360, 690),
        builder: (_, __) => MaterialApp(
          home: Scaffold(
            body: CustomerCard(
              customer: tCustomer,
              state: tState,
              term: tTerm,
              selectedProductId: 'all',
              formatDate: (d) => '${d.day}/${d.month}/${d.year}',
            ),
          ),
        ),
      ),
    );

    expect(find.text('John Doe'), findsOneWidget);
    expect(find.text('1234567890'), findsOneWidget);
    expect(find.textContaining('days left'), findsOneWidget);
  });

  testWidgets('CustomerCard shows Expiring Soon status', (
    WidgetTester tester,
  ) async {
    final expiringSub = createSub(
      id: 'sub2',
      endDate: DateTime.now().add(const Duration(days: 3)),
    );

    final tState = DashboardLoaded(
      shop: tShop,
      products: const [],
      activeSubs: const [],
      expiringSoon: [expiringSub],
      customers: [tCustomer],
      totalCustomers: 1,
      activeSubscriptions: 1,
      logs: [],
    );

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(360, 690),
        builder: (_, __) => MaterialApp(
          home: Scaffold(
            body: CustomerCard(
              customer: tCustomer,
              state: tState,
              term: tTerm,
              selectedProductId: 'all',
              formatDate: (d) => '${d.day}/${d.month}/${d.year}',
            ),
          ),
        ),
      ),
    );

    expect(find.textContaining('days left'), findsOneWidget);
  });
}
