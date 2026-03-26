import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/subscription_log_entity.dart';
import '../../domain/repositories/subscription_repository.dart';

// Events
abstract class SubscriptionEvent extends Equatable {
  const SubscriptionEvent();
  @override
  List<Object?> get props => [];
}

class LoadSubscriptionHistory extends SubscriptionEvent {
  final String shopId;
  final String ownerId;
  final String? customerId;

  const LoadSubscriptionHistory({
    required this.shopId,
    required this.ownerId,
    this.customerId,
  });

  @override
  List<Object?> get props => [shopId, ownerId, customerId];
}

// States
abstract class SubscriptionState extends Equatable {
  const SubscriptionState();
  @override
  List<Object?> get props => [];
}

class SubscriptionInitial extends SubscriptionState {}

class SubscriptionLoading extends SubscriptionState {}

class SubscriptionHistoryLoaded extends SubscriptionState {
  final List<SubscriptionLogEntity> logs;
  const SubscriptionHistoryLoaded(this.logs);

  @override
  List<Object?> get props => [logs];
}

class SubscriptionError extends SubscriptionState {
  final String message;
  const SubscriptionError(this.message);

  @override
  List<Object?> get props => [message];
}

class SubscriptionBloc extends Bloc<SubscriptionEvent, SubscriptionState> {
  final SubscriptionRepository repository;

  SubscriptionBloc({required this.repository}) : super(SubscriptionInitial()) {
    on<LoadSubscriptionHistory>(_onLoadSubscriptionHistory);
  }

  Future<void> _onLoadSubscriptionHistory(
    LoadSubscriptionHistory event,
    Emitter<SubscriptionState> emit,
  ) async {
    emit(SubscriptionLoading());

    final result = await repository.getSubscriptionLogs(
      shopId: event.shopId,
      ownerId: event.ownerId,
      customerId: event.customerId,
    );

    result.fold(
      (failure) => emit(SubscriptionError(failure.message)),
      (logs) => emit(SubscriptionHistoryLoaded(logs)),
    );
  }
}
