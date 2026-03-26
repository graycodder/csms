import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:dartz/dartz.dart';
import 'package:csms/core/error/failures.dart';
import 'package:csms/features/customer/domain/entities/customer_entity.dart';
import 'package:csms/features/product/domain/entities/product_entity.dart';
import 'package:csms/features/subscription/domain/entities/subscription_entity.dart';
import 'package:csms/features/shop/domain/entities/shop_entity.dart';
import 'package:csms/features/customer/domain/repositories/customer_repository.dart';
import 'package:csms/features/product/domain/repositories/product_repository.dart';
import 'package:csms/features/subscription/domain/repositories/subscription_repository.dart';
import 'package:csms/features/shop/domain/repositories/shop_repository.dart';

// Events
abstract class DashboardEvent extends Equatable {
  const DashboardEvent();
  @override
  List<Object?> get props => [];
}

class LoadDashboardData extends DashboardEvent {
  final String shopId;
  final String ownerId;
  const LoadDashboardData({required this.shopId, required this.ownerId});
  @override
  List<Object?> get props => [shopId, ownerId];
}

class LoadMoreCustomers extends DashboardEvent {
  final String shopId;
  final String ownerId;
  const LoadMoreCustomers({required this.shopId, required this.ownerId});
  @override
  List<Object?> get props => [shopId, ownerId];
}

class ResetDashboard extends DashboardEvent {}

// States
abstract class DashboardState extends Equatable {
  const DashboardState();
  @override
  List<Object?> get props => [];
}

class DashboardInitial extends DashboardState {}

class DashboardLoading extends DashboardState {}

class DashboardLoaded extends DashboardState {
  final List<CustomerEntity> customers;
  final List<ProductEntity> products;
  final List<SubscriptionEntity> expiringSoon;
  final List<SubscriptionEntity> activeSubs;
  final int totalCustomers;
  final int activeSubscriptions;
  final ShopEntity shop;
  final bool hasMore;
  final String? lastDoc;

  const DashboardLoaded({
    required this.customers,
    required this.products,
    required this.expiringSoon,
    required this.activeSubs,
    required this.totalCustomers,
    required this.activeSubscriptions,
    required this.shop,
    this.hasMore = false,
    this.lastDoc,
  });

  @override
  List<Object?> get props => [
    customers,
    products,
    expiringSoon,
    activeSubs,
    totalCustomers,
    activeSubscriptions,
    shop,
    hasMore,
    lastDoc,
  ];
}

class DashboardError extends DashboardState {
  final String message;
  const DashboardError(this.message);
  @override
  List<Object?> get props => [message];
}

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final CustomerRepository customerRepository;
  final ProductRepository productRepository;
  final SubscriptionRepository subscriptionRepository;
  final ShopRepository shopRepository;

  DashboardBloc({
    required this.customerRepository,
    required this.productRepository,
    required this.subscriptionRepository,
    required this.shopRepository,
  }) : super(DashboardInitial()) {
    on<LoadDashboardData>(_onLoadDashboardData);
    on<LoadMoreCustomers>(_onLoadMoreCustomers);
    on<ResetDashboard>((event, emit) => emit(DashboardInitial()));
  }

  Future<void> _onLoadDashboardData(
    LoadDashboardData event,
    Emitter<DashboardState> emit,
  ) async {
    emit(DashboardLoading());

    // 1. Fetch Shop first to get settings
    final shopResult = await shopRepository.getShop(event.shopId);

    return shopResult.fold(
      (failure) => emit(DashboardError(failure.message)),
      (shop) async {
        final warningThreshold = shop.settings.expiredDaysBefore;

        // 2. Fetch all other data using shop settings
        final results = await Future.wait([
          customerRepository.getCustomers(
            shopId: event.shopId,
            ownerId: event.ownerId,
          ),
          productRepository.getProducts(
            event.shopId,
            event.ownerId,
          ),
          subscriptionRepository.getExpiringSubscriptions(
            shopId: event.shopId,
            ownerId: event.ownerId,
            notificationDaysBefore: warningThreshold,
          ),
          subscriptionRepository.getActiveSubscriptions(
            shopId: event.shopId,
            ownerId: event.ownerId,
          ),
        ]);

        final customersResult = results[0] as Either<Failure, List<CustomerEntity>>;
        final productsResult = results[1] as Either<Failure, List<ProductEntity>>;
        final expiringResult = results[2] as Either<Failure, List<SubscriptionEntity>>;
        final activeSubsResult = results[3] as Either<Failure, List<SubscriptionEntity>>;

        customersResult.fold(
          (failure) => emit(DashboardError(failure.message)),
          (customers) {
            productsResult.fold(
              (failure) => emit(DashboardError(failure.message)),
              (products) {
                expiringResult.fold(
                  (failure) => emit(DashboardError(failure.message)),
                  (expiringSubs) {
                    activeSubsResult.fold(
                      (failure) => emit(DashboardError(failure.message)),
                      (activeSubs) {
                        emit(DashboardLoaded(
                          customers: customers,
                          products: products,
                          expiringSoon: expiringSubs,
                          activeSubs: activeSubs,
                          totalCustomers: customers.length, // This might need a separate count query for large datasets
                          activeSubscriptions: activeSubs.length,
                          shop: shop,
                          hasMore: customers.length >= 20,
                          lastDoc: customers.isNotEmpty ? customers.last.owner_createdAt : null,
                        ));
                      },
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Future<void> _onLoadMoreCustomers(
    LoadMoreCustomers event,
    Emitter<DashboardState> emit,
  ) async {
    final currentState = state;
    if (currentState is DashboardLoaded && currentState.hasMore) {
      final results = await customerRepository.getCustomers(
        shopId: event.shopId,
        ownerId: event.ownerId,
        lastDoc: currentState.lastDoc,
      );

      results.fold(
        (failure) => null, // Fail silently or log
        (newCustomers) {
          if (newCustomers.isEmpty) {
            emit(currentState.copyWith(hasMore: false));
          } else {
            emit(currentState.copyWith(
              customers: [...currentState.customers, ...newCustomers],
              hasMore: newCustomers.length >= 20,
              lastDoc: newCustomers.last.owner_createdAt,
            ));
          }
        },
      );
    }
  }
}

extension on DashboardLoaded {
  DashboardLoaded copyWith({
    List<CustomerEntity>? customers,
    bool? hasMore,
    String? lastDoc,
  }) {
    return DashboardLoaded(
      customers: customers ?? this.customers,
      products: products,
      expiringSoon: expiringSoon,
      activeSubs: activeSubs,
      totalCustomers: totalCustomers,
      activeSubscriptions: activeSubscriptions,
      shop: shop,
      hasMore: hasMore ?? this.hasMore,
      lastDoc: lastDoc ?? this.lastDoc,
    );
  }
}
