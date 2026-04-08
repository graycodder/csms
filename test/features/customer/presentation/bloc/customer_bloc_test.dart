import 'package:bloc_test/bloc_test.dart';
import 'package:csms/core/error/failures.dart';
import 'package:csms/features/customer/data/models/customer_model.dart';
import 'package:csms/features/customer/domain/repositories/customer_repository.dart';
import 'package:csms/features/customer/presentation/bloc/customer_bloc.dart';
import 'package:csms/features/notifications/domain/repositories/notification_repository.dart';
import 'package:csms/features/subscription/domain/repositories/subscription_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:csms/features/customer/domain/entities/customer_entity.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockCustomerRepository extends Mock implements CustomerRepository {}
class MockSubscriptionRepository extends Mock implements SubscriptionRepository {}
class MockNotificationRepository extends Mock implements NotificationRepository {}

class FakeCustomerEntity extends Fake implements CustomerEntity {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeCustomerEntity());
  });

  late CustomerBloc customerBloc;
  late MockCustomerRepository mockCustomerRepository;
  late MockSubscriptionRepository mockSubscriptionRepository;
  late MockNotificationRepository mockNotificationRepository;

  final tCustomer = CustomerModel(
    customerId: '123',
    shopId: 'shop1',
    name: 'John Doe',
    mobileNumber: '123',
    email: 'john@example.com',
    assignedProductIds: const {},
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
    updatedById: 'admin1',
    ownerId: 'owner1',
  );

  setUp(() {
    mockCustomerRepository = MockCustomerRepository();
    mockSubscriptionRepository = MockSubscriptionRepository();
    mockNotificationRepository = MockNotificationRepository();
    customerBloc = CustomerBloc(
      customerRepository: mockCustomerRepository,
      subscriptionRepository: mockSubscriptionRepository,
      notificationRepository: mockNotificationRepository,
    );
  });

  tearDown(() {
    customerBloc.close();
  });

  group('CustomerBloc', () {
    test('initial state should be CustomerInitial', () {
      expect(customerBloc.state, isA<CustomerInitial>());
    });

    blocTest<CustomerBloc, CustomerState>(
      'emits [CustomerLoading, CustomerSuccess] when UpdateCustomerInfo is successful',
      build: () {
        when(() => mockCustomerRepository.updateCustomer(any(),
                paymentMode: any(named: 'paymentMode')))
            .thenAnswer((_) async => const Right(null));
        return customerBloc;
      },
      act: (bloc) => bloc.add(UpdateCustomerInfo(customer: tCustomer)),
      expect: () => [
        isA<CustomerLoading>(),
        isA<CustomerSuccess>(),
      ],
      verify: (_) {
        verify(() => mockCustomerRepository.updateCustomer(tCustomer,
            paymentMode: any(named: 'paymentMode'))).called(1);
      },
    );

    blocTest<CustomerBloc, CustomerState>(
      'emits [CustomerLoading, CustomerError] when UpdateCustomerInfo fails',
      build: () {
        when(() => mockCustomerRepository.updateCustomer(any(),
                paymentMode: any(named: 'paymentMode')))
            .thenAnswer((_) async => const Left(ServerFailure('Update Failed')));
        return customerBloc;
      },
      act: (bloc) => bloc.add(UpdateCustomerInfo(customer: tCustomer)),
      expect: () => [
        isA<CustomerLoading>(),
        isA<CustomerError>(),
      ],
    );

    blocTest<CustomerBloc, CustomerState>(
      'emits [CustomerLoading, CustomerSuccess] when RenewCustomerSubscription is successful and triggers notification',
      build: () {
        when(() => mockSubscriptionRepository.renewSubscription(
          subscriptionId: any(named: 'subscriptionId'),
          validityValue: any(named: 'validityValue'),
          validityUnit: any(named: 'validityUnit'),
          updatedById: any(named: 'updatedById'),
          price: any(named: 'price'),
          productName: any(named: 'productName'),
        )).thenAnswer((_) async => const Right(null));
        
        when(() => mockNotificationRepository.pushNotification(
          ownerId: any(named: 'ownerId'),
          shopId: any(named: 'shopId'),
          title: any(named: 'title'),
          body: any(named: 'body'),
          type: any(named: 'type'),
          updatedById: any(named: 'updatedById'),
        )).thenAnswer((_) async => const Right(null));

        return customerBloc;
      },
      act: (bloc) => bloc.add(RenewCustomerSubscription(
        subscriptionId: 'sub1',
        shopId: 'shop1',
        validityValue: 1,
        validityUnit: 'Month',
        updatedById: 'admin1',
        ownerId: 'owner1',
        productName: 'Premium',
        price: 100,
        updatedByName: 'Staff',
        customerName: 'John',
        shopCategory: 'Health and Fitness',
      )),
      expect: () => [
        isA<CustomerLoading>(),
        isA<CustomerSuccess>(),
      ],
      verify: (_) {
        verify(() => mockNotificationRepository.pushNotification(
          ownerId: 'owner1',
          shopId: 'shop1',
          title: 'Membership Renewed',
          body: "John's membership for Premium has been renewed by Staff",
          type: 'renewal',
          updatedById: 'admin1',
        )).called(1);
      },
    );
  });
}
