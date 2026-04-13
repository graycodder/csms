import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:csms/features/customer/domain/entities/customer_entity.dart';
import 'package:csms/features/customer/domain/repositories/customer_repository.dart';
import 'package:csms/features/subscription/domain/repositories/subscription_repository.dart';
import 'package:csms/features/notifications/domain/repositories/notification_repository.dart';
import 'package:csms/core/utils/terminology_helper.dart';

// Events
abstract class CustomerEvent extends Equatable {
  const CustomerEvent();
  @override
  List<Object?> get props => [];
}

class AddCustomerWithSubscription extends CustomerEvent {
  final CustomerEntity customer;
  final String productId;
  final int validityValue;
  final String validityUnit;
  final double price;
  final double registrationFeeAmount;
  final double? paidAmount;
  final String? paymentMode;
  final String productName;
  final String updatedByName;
  final String shopCategory;
  final String? notes;

  const AddCustomerWithSubscription({
    required this.customer,
    required this.productId,
    required this.validityValue,
    required this.validityUnit,
    required this.price,
    this.registrationFeeAmount = 0.0,
    this.paidAmount,
    this.paymentMode,
    required this.productName,
    required this.updatedByName,
    required this.shopCategory,
    this.notes,
  });

  @override
  List<Object?> get props => [
    customer,
    productId,
    validityValue,
    validityUnit,
    price,
    registrationFeeAmount,
    paidAmount,
    paymentMode,
    productName,
    updatedByName,
    notes,
  ];
}

class UpdateCustomerInfo extends CustomerEvent {
  final CustomerEntity customer;
  final String? paymentMode;
  final String updatedByName;
  final String updatedById;
  final String ownerId;
  final String shopId;
  final String customerName;
  final String shopCategory;

  const UpdateCustomerInfo({
    required this.customer,
    this.paymentMode,
    required this.updatedByName,
    required this.updatedById,
    required this.ownerId,
    required this.shopId,
    required this.customerName,
    required this.shopCategory,
  });

  @override
  List<Object?> get props => [
    customer,
    paymentMode,
    updatedByName,
    updatedById,
    ownerId,
    shopId,
    customerName,
    shopCategory,
  ];
}

class AddSubscription extends CustomerEvent {
  final String shopId;
  final String customerId;
  final String productId;
  final String ownerId;
  final String updatedById;
  final int validityValue;
  final String validityUnit;
  final double price;
  final double registrationFeeAmount;
  final double? paidAmount;
  final String? paymentMode;
  final String customerName;
  final String productName;
  final String updatedByName;
  final String shopCategory;
  final String? notes;

  const AddSubscription({
    required this.shopId,
    required this.customerId,
    required this.productId,
    required this.ownerId,
    required this.updatedById,
    required this.validityValue,
    required this.validityUnit,
    required this.price,
    this.registrationFeeAmount = 0.0,
    this.paidAmount,
    this.paymentMode,
    required this.customerName,
    required this.productName,
    required this.updatedByName,
    required this.shopCategory,
    this.notes,
  });

  @override
  List<Object?> get props => [
    shopId,
    customerId,
    productId,
    ownerId,
    updatedById,
    validityValue,
    validityUnit,
    price,
    registrationFeeAmount,
    paidAmount,
    paymentMode,
    customerName,
    productName,
    updatedByName,
    notes,
  ];
}

class DeleteCustomer extends CustomerEvent {
  final String customerId;
  const DeleteCustomer(this.customerId);
  @override
  List<Object?> get props => [customerId];
}

class RenewCustomerSubscription extends CustomerEvent {
  final String subscriptionId;
  final String shopId;
  final int validityValue;
  final String validityUnit;
  final String updatedById;
  final String ownerId;
  final double? price;
  final double? paidAmount;
  final String? paymentMode;
  final String productName;
  final String updatedByName;
  final String customerName;
  final String shopCategory;
  final String? notes;

  const RenewCustomerSubscription({
    required this.subscriptionId,
    required this.shopId,
    required this.validityValue,
    required this.validityUnit,
    required this.updatedById,
    required this.ownerId,
    required this.productName,
    required this.updatedByName,
    required this.customerName,
    required this.shopCategory,
    this.price,
    this.paidAmount,
    this.paymentMode,
    this.notes,
  });

  @override
  List<Object?> get props => [
    subscriptionId,
    shopId,
    validityValue,
    validityUnit,
    updatedById,
    ownerId,
    price,
    paidAmount,
    paymentMode,
    productName,
    updatedByName,
    customerName,
    shopCategory,
    notes,
  ];
}

class UpdateSubscription extends CustomerEvent {
  final String subscriptionId;
  final DateTime endDate;
  final double price;
  final String updatedById;
  final String ownerId;
  final String shopId;
  final String updatedByName;
  final String customerName;
  final String shopCategory;
  final double? registrationFeeAmount;
  final double? registrationFeePaid;
  final double? paidAmount;
  final String? paymentMode;
  final String? status;
  final CustomerEntity? customer; // Add optional customer entity
  final String? notes;

  const UpdateSubscription({
    required this.subscriptionId,
    required this.endDate,
    required this.price,
    required this.updatedById,
    required this.ownerId,
    required this.shopId,
    required this.updatedByName,
    required this.customerName,
    required this.shopCategory,
    this.registrationFeeAmount,
    this.registrationFeePaid,
    this.paidAmount,
    this.paymentMode,
    this.status,
    this.customer,
    this.notes,
  });

  @override
  List<Object?> get props => [
    subscriptionId,
    endDate,
    price,
    registrationFeeAmount,
    registrationFeePaid,
    paidAmount,
    paymentMode,
    updatedById,
    ownerId,
    shopId,
    updatedByName,
    customerName,
    shopCategory,
    status,
    customer,
    notes,
  ];
}

class ResetCustomer extends CustomerEvent {}

// States
abstract class CustomerState extends Equatable {
  const CustomerState();
  @override
  List<Object?> get props => [];
}

class CustomerInitial extends CustomerState {}

class CustomerLoading extends CustomerState {}

class CustomerSuccess extends CustomerState {}

class CustomerError extends CustomerState {
  final String message;
  const CustomerError(this.message);
  @override
  List<Object?> get props => [message];
}

// BLoC
class CustomerBloc extends Bloc<CustomerEvent, CustomerState> {
  final CustomerRepository customerRepository;
  final SubscriptionRepository subscriptionRepository;
  final NotificationRepository notificationRepository;

  CustomerBloc({
    required this.customerRepository,
    required this.subscriptionRepository,
    required this.notificationRepository,
  }) : super(CustomerInitial()) {
    on<AddCustomerWithSubscription>(_onAddCustomerWithSubscription);
    on<UpdateCustomerInfo>(_onUpdateCustomerInfo);
    on<DeleteCustomer>(_onDeleteCustomer);
    on<RenewCustomerSubscription>(_onRenewCustomerSubscription);
    on<UpdateSubscription>(_onUpdateSubscription);
    on<AddSubscription>(_onAddSubscription);
    on<ResetCustomer>((event, emit) => emit(CustomerInitial()));
  }

  Future<void> _onAddCustomerWithSubscription(
    AddCustomerWithSubscription event,
    Emitter<CustomerState> emit,
  ) async {
    emit(CustomerLoading());
    final customerResult = await customerRepository.addCustomer(event.customer);

    await customerResult.fold(
      (failure) async => emit(CustomerError(failure.message)),
      (customerId) async {
        final subResult = await subscriptionRepository.createSubscription(
          shopId: event.customer.shopId,
          customerId: customerId,
          productId: event.productId,
          ownerId: event.customer.ownerId,
          updatedById: event.customer.updatedById,
          validityValue: event.validityValue,
          validityUnit: event.validityUnit,
          price: event.price,
          registrationFeeAmount: event.registrationFeeAmount,
          paidAmount: event.paidAmount,
          paymentMode: event.paymentMode,
          productName: event.productName,
          isNewCustomer: true,
          notes: event.notes,
        );
        await subResult.fold(
          (failure) async => emit(CustomerError(failure.message)),
          (_) async {
            final term = TerminologyHelper.getTerminology(event.shopCategory);
            await notificationRepository.pushNotification(
              ownerId: event.customer.ownerId,
              shopId: event.customer.shopId,
              title: 'New ${term.subscriptionLabel}',
              body:
                  "${event.customer.name}'s ${term.subscriptionLabel.toLowerCase()} was added by ${event.updatedByName}",
              type: 'subscription',
              updatedById: event.customer.updatedById,
            );
            emit(CustomerSuccess());
          },
        );
      },
    );
  }

  Future<void> _onUpdateCustomerInfo(
    UpdateCustomerInfo event,
    Emitter<CustomerState> emit,
  ) async {
    emit(CustomerLoading());
    final result = await customerRepository.updateCustomer(
      event.customer,
      paymentMode: event.paymentMode,
    );

    result.fold(
      (failure) => emit(CustomerError(failure.message)),
      (_) => emit(CustomerSuccess()),
    );
  }

  Future<void> _onDeleteCustomer(
    DeleteCustomer event,
    Emitter<CustomerState> emit,
  ) async {
    emit(CustomerLoading());
    // Safe clearance of associated subscriptions first
    await subscriptionRepository.deleteSubscriptionsForCustomer(
      event.customerId,
    );
    final result = await customerRepository.deleteCustomer(event.customerId);
    result.fold(
      (failure) => emit(CustomerError(failure.message)),
      (_) => emit(CustomerSuccess()),
    );
  }

  Future<void> _onRenewCustomerSubscription(
    RenewCustomerSubscription event,
    Emitter<CustomerState> emit,
  ) async {
    emit(CustomerLoading());
    final result = await subscriptionRepository.renewSubscription(
      subscriptionId: event.subscriptionId,
      validityValue: event.validityValue,
      validityUnit: event.validityUnit,
      updatedById: event.updatedById,
      price: event.price,
      paidAmount: event.paidAmount,
      paymentMode: event.paymentMode,
      productName: event.productName,
      notes: event.notes,
    );
    await result.fold((failure) async => emit(CustomerError(failure.message)), (
      _,
    ) async {
      final term = TerminologyHelper.getTerminology(event.shopCategory);
      await notificationRepository.pushNotification(
        ownerId: event.ownerId,
        shopId: event.shopId,
        title: '${term.subscriptionLabel} Renewed',
        body:
            "${event.customerName}'s ${term.subscriptionLabel.toLowerCase()} for ${event.productName} has been renewed by ${event.updatedByName}",
        type: 'renewal',
        updatedById: event.updatedById,
      );
      emit(CustomerSuccess());
    });
  }

  Future<void> _onUpdateSubscription(
    UpdateSubscription event,
    Emitter<CustomerState> emit,
  ) async {
    emit(CustomerLoading());
    
    // Check and update customer entity first if provided
    if (event.customer != null) {
      final custResult = await customerRepository.updateCustomer(
        event.customer!,
        paymentMode: event.paymentMode,
      );
      if (custResult.isLeft()) {
        emit(
          CustomerError(
            custResult.fold(
              (l) => l.message,
              (r) => "Error updating customer details",
            ),
          ),
        );
        return;
      }
    }

    final result = await subscriptionRepository.updateSubscription(
      subscriptionId: event.subscriptionId,
      endDate: event.endDate,
      price: event.price,
      registrationFeeAmount: event.registrationFeeAmount,
      registrationFeePaid: event.registrationFeePaid,
      paidAmount: event.paidAmount,
      paymentMode: event.paymentMode,
      updatedById: event.updatedById,
      status: event.status,
      notes: event.notes,
    );
    await result.fold((failure) async => emit(CustomerError(failure.message)), (
      _,
    ) async {
      final term = TerminologyHelper.getTerminology(event.shopCategory);
      await notificationRepository.pushNotification(
        ownerId: event.ownerId,
        shopId: event.shopId,
        title: '${term.subscriptionLabel} Corrected',
        body:
            "${event.customerName}'s ${term.subscriptionLabel.toLowerCase()} details have been corrected by ${event.updatedByName}",
        type: 'edit',
        updatedById: event.updatedById,
      );
      emit(CustomerSuccess());
    });
  }

  Future<void> _onAddSubscription(
    AddSubscription event,
    Emitter<CustomerState> emit,
  ) async {
    emit(CustomerLoading());
    final result = await subscriptionRepository.createSubscription(
      shopId: event.shopId,
      customerId: event.customerId,
      productId: event.productId,
      ownerId: event.ownerId,
      updatedById: event.updatedById,
      validityValue: event.validityValue,
      validityUnit: event.validityUnit,
      price: event.price,
      registrationFeeAmount: event.registrationFeeAmount,
      paidAmount: event.paidAmount,
      paymentMode: event.paymentMode,
      productName: event.productName,
      notes: event.notes,
    );

    await result.fold((failure) async => emit(CustomerError(failure.message)), (
      _,
    ) async {
      final term = TerminologyHelper.getTerminology(event.shopCategory);
      await notificationRepository.pushNotification(
        ownerId: event.ownerId,
        shopId: event.shopId,
        title: 'New ${term.subscriptionLabel} Added',
        body:
            "${event.customerName}'s ${term.subscriptionLabel.toLowerCase()} for ${event.productName} was added by ${event.updatedByName}",
        type: 'subscription',
        updatedById: event.updatedById,
      );
      emit(CustomerSuccess());
    });
  }
}
