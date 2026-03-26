import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:csms/core/error/failures.dart';
import '../../domain/entities/shop_subscription_entity.dart';
import '../../domain/usecases/get_shop_subscription_status.dart';
import '../../domain/usecases/stream_shop_subscription_status.dart';
import '../../domain/usecases/get_shop_subscription_history.dart';
import '../../domain/usecases/renew_shop_subscription.dart';
import '../../domain/entities/shop_subscription_log_entity.dart';

// Events
abstract class ShopSubscriptionEvent extends Equatable {
  const ShopSubscriptionEvent();
  @override
  List<Object?> get props => [];
}

class LoadShopSubscriptionStatus extends ShopSubscriptionEvent {
  final String shopId;
  const LoadShopSubscriptionStatus(this.shopId);
  @override
  List<Object?> get props => [shopId];
}

class ListenToShopSubscriptionStatus extends ShopSubscriptionEvent {
  final String shopId;
  const ListenToShopSubscriptionStatus(this.shopId);
  @override
  List<Object?> get props => [shopId];
}

class LoadShopSubscriptionHistory extends ShopSubscriptionEvent {
  final String shopId;
  final String ownerId;
  const LoadShopSubscriptionHistory(this.shopId, this.ownerId);
  @override
  List<Object?> get props => [shopId, ownerId];
}

class RenewShopSubscriptionEvent extends ShopSubscriptionEvent {
  final String shopId;
  final String ownerId;
  final int validityValue;
  final String validityUnit;
  final double price;
  final String updatedById;

  const RenewShopSubscriptionEvent({
    required this.shopId,
    required this.ownerId,
    required this.validityValue,
    required this.validityUnit,
    required this.price,
    required this.updatedById,
  });

  @override
  List<Object?> get props => [shopId, ownerId, validityValue, validityUnit, price, updatedById];
}

// States
abstract class ShopSubscriptionState extends Equatable {
  const ShopSubscriptionState();
  @override
  List<Object?> get props => [];
}

class ShopSubscriptionInitial extends ShopSubscriptionState {}
class ShopSubscriptionLoading extends ShopSubscriptionState {}

class ShopSubscriptionStatusLoaded extends ShopSubscriptionState {
  final ShopSubscriptionEntity status;
  const ShopSubscriptionStatusLoaded(this.status);
  @override
  List<Object?> get props => [status];
}

class ShopSubscriptionHistoryLoaded extends ShopSubscriptionState {
  final List<ShopSubscriptionLogEntity> logs;
  const ShopSubscriptionHistoryLoaded(this.logs);
  @override
  List<Object?> get props => [logs];
}

class ShopSubscriptionRenewed extends ShopSubscriptionState {}

class ShopSubscriptionError extends ShopSubscriptionState {
  final String message;
  const ShopSubscriptionError(this.message);
  @override
  List<Object?> get props => [message];
}

// Bloc
class ShopSubscriptionBloc extends Bloc<ShopSubscriptionEvent, ShopSubscriptionState> {
  final GetShopSubscriptionStatus getStatus;
  final StreamShopSubscriptionStatus streamStatus;
  final GetShopSubscriptionHistory getHistory;
  final RenewShopSubscription renewSubscription;

  ShopSubscriptionBloc({
    required this.getStatus,
    required this.streamStatus,
    required this.getHistory,
    required this.renewSubscription,
  }) : super(ShopSubscriptionInitial()) {
    on<LoadShopSubscriptionStatus>(_onLoadStatus);
    on<ListenToShopSubscriptionStatus>(_onListenToStatus);
    on<LoadShopSubscriptionHistory>(_onLoadHistory);
    on<RenewShopSubscriptionEvent>(_onRenew);
  }

  Future<void> _onLoadStatus(LoadShopSubscriptionStatus event, Emitter<ShopSubscriptionState> emit) async {
    emit(ShopSubscriptionLoading());
    final result = await getStatus(event.shopId);
    result.fold(
      (failure) => emit(ShopSubscriptionError(failure.message)),
      (status) => emit(ShopSubscriptionStatusLoaded(status)),
    );
  }

  Future<void> _onListenToStatus(ListenToShopSubscriptionStatus event, Emitter<ShopSubscriptionState> emit) async {
    emit(ShopSubscriptionLoading());
    
    await emit.forEach<Either<Failure, ShopSubscriptionEntity>>(
      streamStatus(event.shopId),
      onData: (result) {
        return result.fold(
          (failure) => ShopSubscriptionError(failure.message),
          (status) => ShopSubscriptionStatusLoaded(status),
        );
      },
      onError: (error, _) => ShopSubscriptionError(error.toString()),
    );
  }

  Future<void> _onLoadHistory(LoadShopSubscriptionHistory event, Emitter<ShopSubscriptionState> emit) async {
    emit(ShopSubscriptionLoading());
    final result = await getHistory(event.shopId, event.ownerId);
    result.fold(
      (failure) => emit(ShopSubscriptionError(failure.message)),
      (logs) => emit(ShopSubscriptionHistoryLoaded(logs)),
    );
  }

  Future<void> _onRenew(RenewShopSubscriptionEvent event, Emitter<ShopSubscriptionState> emit) async {
    emit(ShopSubscriptionLoading());
    final result = await renewSubscription(
      shopId: event.shopId,
      ownerId: event.ownerId,
      validityValue: event.validityValue,
      validityUnit: event.validityUnit,
      price: event.price,
      updatedById: event.updatedById,
    );
    result.fold(
      (failure) => emit(ShopSubscriptionError(failure.message)),
      (_) => emit(ShopSubscriptionRenewed()),
    );
  }
}
